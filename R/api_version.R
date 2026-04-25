# Internal API version configuration registry
#
# All version-specific constants live here. Nothing in api.R, auth.R, or
# entity files should hardcode "app/", "hydra:member", or auth paths.
# Always read from this registry via:
#
#   cfg <- .api_config[[con$api_version]]
#
# @noRd

.api_config <- list(

  v2 = list(
    # URL construction
    path_prefix    = "app/",
    auth_endpoint  = "api/login_check",

    # Auth body field names (v2 uses _username/_password form-style fields)
    auth_username_field = "_username",
    auth_password_field = "_password",

    # Hydra JSON-LD pagination keys
    member_key     = "hydra:member",
    total_key      = "hydra:totalItems",
    view_key       = "hydra:view",
    next_key       = "hydra:next",

    # Pattern used to identify and strip Hydra @id URI columns
    id_uri_pattern = "^/app/"
  ),

  v3 = list(
    # URL construction
    path_prefix    = "api/",
    auth_endpoint  = "api/auth",

    # Auth body field names (v3 uses email/password)
    auth_username_field = "email",
    auth_password_field = "password",

    # Hydra JSON-LD pagination keys (v3 drops the "hydra:" namespace prefix)
    member_key     = "member",
    total_key      = "totalItems",
    view_key       = "view",
    next_key       = "next",

    # Pattern used to identify and strip Hydra @id URI columns
    id_uri_pattern = "^/api/"
  )
)

#' Look up version config for a connection
#'
#' @param api_version Character: `"v2"` or `"v3"`.
#' @return Named list of version-specific constants.
#' @noRd
api_cfg <- function(api_version) {
  cfg <- .api_config[[api_version]]
  if (is.null(cfg)) {
    abort(c(
      paste0("Unknown api_version: '", api_version, "'."),
      "i" = "Must be one of: 'v2', 'v3'."
    ))
  }
  cfg
}

#' Extract the member array from a paginated SELMA response
#'
#' Tries the version-appropriate key first. Falls back to the other version's
#' key with a warning (signals a likely version mismatch). Errors immediately
#' if neither key is present, listing all available response keys.
#'
#' @param page_data Parsed JSON response (named list).
#' @param api_version Character: `"v2"` or `"v3"`.
#' @return The member array (list or data frame).
#' @noRd
extract_members <- function(page_data, api_version) {
  cfg <- api_cfg(api_version)
  members <- page_data[[cfg$member_key]]

  if (!is.null(members)) return(members)

  # Try the other version's key as a fallback
  alt_version <- if (api_version == "v2") "v3" else "v2"
  alt_key     <- .api_config[[alt_version]]$member_key
  members     <- page_data[[alt_key]]

  if (!is.null(members)) {
    cli_warn(c(
      "SELMA response used '{alt_key}' instead of expected '{cfg$member_key}'.",
      "i" = "Your SELMA instance may have been upgraded. Try api_version = '{alt_version}' in selma_connect()."
    ))
    return(members)
  }

  # Neither key found — fail loud with diagnostics
  abort(c(
    "SELMA API response contains no member data.",
    "x" = "Neither '{cfg$member_key}' nor '{alt_key}' found in response.",
    "i" = paste("Response keys:", paste(names(page_data), collapse = ", "))
  ))
}

#' Auto-detect the SELMA API version
#'
#' Probes the API by attempting a minimal request to both the v3 and v2
#' students endpoints. Returns `"v3"` if the v3 path responds, `"v2"`
#' otherwise.
#'
#' @param base_url SELMA base URL (with trailing slash).
#' @param token Bearer token string.
#' @return `"v2"` or `"v3"`.
#' @noRd
selma_detect_api_version <- function(base_url, token) {
  # Probe v3 first (newer, preferred)
  v3_url <- paste0(base_url, .api_config$v3$path_prefix, "students?page=1&itemsPerPage=1")

  resp <- tryCatch(
    httr2::request(v3_url) |>
      httr2::req_headers(Authorization = token) |>
      httr2::req_error(is_error = function(r) FALSE) |>
      httr2::req_perform(),
    error = function(e) NULL
  )

  if (!is.null(resp) && httr2::resp_status(resp) == 200L) {
    body <- tryCatch(httr2::resp_body_json(resp), error = function(e) NULL)
    if (!is.null(body) && !is.null(body[["member"]])) {
      cli_alert_info("Auto-detected SELMA API version: v3")
      return("v3")
    }
  }

  cli_alert_info("Auto-detected SELMA API version: v2")
  "v2"
}
