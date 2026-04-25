# Package-level environment for storing the active connection
selma_env <- new.env(parent = emptyenv())

#' Connect to the SELMA API
#'
#' Authenticates with SELMA and stores the connection for the session.
#' Once connected, all `selma_*()` fetch functions use this connection
#' automatically — no need to pass it explicitly.
#'
#' Credentials are resolved in order:
#'
#' 1. **Direct arguments** — `base_url`, `email`, `password`
#' 2. **config.yml** — version-specific block (`selma.v2` or `selma.v3`) if
#'    `api_version` is set, then flat `selma` block as fallback
#' 3. **Environment variables** — version-specific (`SELMA_V3_EMAIL` etc.)
#'    then generic (`SELMA_EMAIL` etc.)
#'
#' @section config.yml:
#' Create a `config.yml` in your project root (add to `.gitignore`!).
#'
#' **Single version** (flat structure, backward-compatible):
#' ```yaml
#' default:
#'   selma:
#'     base_url: "https://myorg.selma.co.nz/"
#'     email: "api@selma.co.nz"
#'     password: "secret"
#' ```
#'
#' **Dual version** (v2 and v3 credentials stored separately):
#' ```yaml
#' default:
#'   selma:
#'     v2:
#'       base_url: "https://myorg.selma.co.nz/"
#'       email: "v2_api@selma.co.nz"
#'       password: "v2secret"
#'     v3:
#'       base_url: "https://myorg.selma.app/"
#'       email: "v3_api@selma.app"
#'       password: "v3secret"
#' ```
#'
#' When `api_version = "v3"` is set (or auto-detected), selmaR reads
#' `selma.v3.email` / `selma.v3.password` first, falling back to the flat
#' `selma.email` / `selma.password` if not present.
#'
#' @param base_url SELMA base URL (e.g. `"https://myorg.selma.co.nz/"`).
#' @param email API login email.
#' @param password API login password.
#' @param api_version SELMA API version: `"v2"`, `"v3"`, or `NULL` (default)
#'   to auto-detect. A SELMA instance runs one version — the value is stored
#'   on the connection object and used for all subsequent requests.
#' @param config_file Path to a config YAML file (default `"config.yml"`).
#'   Set to `NULL` to skip config file lookup.
#' @return A `selma_connection` object (invisibly). The connection is also
#'   stored in the package environment for automatic use by all fetch functions.
#' @export
#' @examples
#' \dontrun{
#' # Connect once — all functions use it automatically (api_version auto-detected)
#' selma_connect()
#' students <- selma_students()
#' enrolments <- selma_enrolments()
#'
#' # Specify API version explicitly
#' selma_connect(
#'   base_url = "https://myorg.selma.co.nz/",
#'   email = "api@selma.co.nz",
#'   password = "secret",
#'   api_version = "v3"
#' )
#' }
selma_connect <- function(base_url = NULL, email = NULL, password = NULL,
                          api_version = NULL, config_file = "config.yml") {

  # Validate api_version first — needed before config resolution so the
  # correct version-specific config block is read
  if (!is.null(api_version)) {
    api_version <- tryCatch(
      match.arg(api_version, c("v2", "v3")),
      error = function(e) abort(c(
        str_c("Invalid api_version: '", api_version, "'."),
        "i" = "Must be 'v2', 'v3', or NULL (auto-detect)."
      ))
    )
  }

  # Resolve credentials: args > version-specific config > flat config > env vars
  cfg <- selma_resolve_config(base_url, email, password, config_file, api_version)

  if (cfg$base_url == "") {
    abort(c(
      "SELMA base_url not found.",
      "i" = "Set via argument, config.yml (selma.base_url), or SELMA_BASE_URL env var."
    ))
  }
  if (cfg$email == "") {
    abort(c(
      "SELMA email not found.",
      "i" = "Set via argument, config.yml (selma.v3.email or selma.email), or SELMA_V3_EMAIL / SELMA_EMAIL env var."
    ))
  }
  if (cfg$password == "") {
    abort(c(
      "SELMA password not found.",
      "i" = "Set via argument, config.yml (selma.v3.password or selma.password), or SELMA_V3_PASSWORD / SELMA_PASSWORD env var."
    ))
  }

  # Normalise to exactly one trailing slash
  cfg$base_url <- str_c(str_remove(cfg$base_url, "/+$"), "/")

  token <- selma_auth(cfg$base_url, cfg$email, cfg$password, api_version)

  # Auto-detect api_version if not specified
  if (is.null(api_version)) {
    api_version <- selma_detect_api_version(cfg$base_url, token)
  }

  con <- structure(
    list(
      base_url    = cfg$base_url,
      token       = token,
      api_version = api_version
    ),
    class = "selma_connection"
  )

  # Store in package environment for automatic use
  selma_env$connection <- con

  cli_alert_success("Connected to SELMA {api_version} at {.url {cfg$base_url}}")
  invisible(con)
}

#' Disconnect from the SELMA API
#'
#' Clears the stored connection. Subsequent fetch calls will require
#' a new `selma_connect()`.
#'
#' @export
#' @examples
#' \dontrun{
#' selma_connect()
#' selma_disconnect()
#' }
selma_disconnect <- function() {
  selma_env$connection <- NULL
  cli_alert_info("SELMA connection cleared.")
  invisible(NULL)
}

#' Get the active SELMA connection
#'
#' Returns the stored connection, or errors with a helpful message if
#' no connection exists. Used internally by all fetch functions and the
#' MCP server.
#'
#' @param con Optional explicit connection. If `NULL`, uses the stored
#'   connection from [selma_connect()].
#' @return A `selma_connection` object.
#' @export
selma_get_connection <- function(con = NULL) {
  if (!is.null(con)) {
    if (!inherits(con, "selma_connection")) {
      abort("`con` must be a selma_connection object from selma_connect().")
    }
    return(con)
  }

  stored <- selma_env$connection
  if (is.null(stored)) {
    abort(c(
      "No SELMA connection found.",
      "i" = "Run selma_connect() first to authenticate."
    ))
  }
  stored
}

#' @export
print.selma_connection <- function(x, ...) {
  cat("<selma_connection>\n")
  cat("  Base URL:    ", x$base_url, "\n")
  cat("  API version: ", x$api_version %||% "unknown", "\n")
  cat("  Token:       ", str_sub(x$token, 1, 20), "...\n")
  invisible(x)
}

#' Resolve SELMA config from args, config.yml, or env vars
#'
#' Resolution order for each field:
#'   1. Direct argument
#'   2. Version-specific config block (e.g. selma.v3.email)
#'   3. Flat config block (selma.email)
#'   4. Version-specific env var (e.g. SELMA_V3_EMAIL)
#'   5. Generic env var (SELMA_EMAIL)
#'
#' @noRd
selma_resolve_config <- function(base_url, email, password, config_file,
                                 api_version = NULL) {
  # Start with direct args (may be NULL)
  result <- list(
    base_url = base_url %||% "",
    email    = email    %||% "",
    password = password %||% ""
  )

  # Try config.yml
  if (!is.null(config_file) && file.exists(config_file)) {
    selma_cfg <- tryCatch(
      config::get("selma", file = config_file),
      error = function(e) NULL
    )

    if (!is.null(selma_cfg)) {
      # Version-specific block (e.g. selma.v3) takes precedence over flat selma
      ver_cfg <- if (!is.null(api_version)) selma_cfg[[api_version]] else NULL

      if (result$base_url == "")
        result$base_url <- ver_cfg$base_url %||% selma_cfg$base_url %||% ""
      if (result$email == "")
        result$email    <- ver_cfg$email    %||% selma_cfg$email    %||% ""
      if (result$password == "")
        result$password <- ver_cfg$password %||% selma_cfg$password %||% ""
    }
  }

  # Env vars: version-specific (SELMA_V3_EMAIL) then generic (SELMA_EMAIL)
  ver_upper <- if (!is.null(api_version)) str_to_upper(api_version) else ""

  if (result$base_url == "") {
    result$base_url <-
      (if (ver_upper != "") Sys.getenv(str_c("SELMA_", ver_upper, "_BASE_URL")) else "") %|+|%
      Sys.getenv("SELMA_BASE_URL")
  }
  if (result$email == "") {
    result$email <-
      (if (ver_upper != "") Sys.getenv(str_c("SELMA_", ver_upper, "_EMAIL")) else "") %|+|%
      Sys.getenv("SELMA_EMAIL")
  }
  if (result$password == "") {
    result$password <-
      (if (ver_upper != "") Sys.getenv(str_c("SELMA_", ver_upper, "_PASSWORD")) else "") %|+|%
      Sys.getenv("SELMA_PASSWORD")
  }

  result
}

# Like %||% but treats empty string as NULL — for env var fallback chains
`%|+|%` <- function(x, y) if (!is.null(x) && str_length(x) > 0) x else y

#' Authenticate with the SELMA API
#'
#' Uses the version-specific auth endpoint and body field names from the
#' registry. When `api_version` is `NULL`, tries v3 first then v2.
#'
#' @param base_url SELMA base URL (with trailing slash).
#' @param email Login email.
#' @param password Login password.
#' @param api_version `"v2"`, `"v3"`, or `NULL` (try v3 then v2).
#' @return Bearer token string (e.g. `"Bearer eyJ..."`).
#' @noRd
selma_auth <- function(base_url, email, password, api_version = NULL) {
  if (!is.null(api_version)) {
    cfg <- api_cfg(api_version)
    return(.selma_auth_attempt(base_url, email, password, cfg))
  }

  # Version unknown — try v3 first, then v2
  for (ver in c("v3", "v2")) {
    token <- tryCatch(
      .selma_auth_attempt(base_url, email, password, api_cfg(ver)),
      error = function(e) NULL
    )
    if (!is.null(token)) return(token)
  }

  abort(c(
    "SELMA authentication failed on both v3 and v2 endpoints.",
    "i" = str_c("Tried: ", base_url, "api/auth  and  ", base_url, "api/login_check"),
    "i" = "Check your base_url and credentials."
  ))
}

#' Perform a single auth attempt against a specific version endpoint
#' @noRd
.selma_auth_attempt <- function(base_url, email, password, cfg) {
  auth_url <- str_c(base_url, cfg$auth_endpoint)
  body_fields <- stats::setNames(
    list(email, password),
    c(cfg$auth_username_field, cfg$auth_password_field)
  )

  resp <- httr2::request(auth_url) |>
    httr2::req_body_json(body_fields) |>
    httr2::req_error(body = function(resp) {
      str_c(
        "SELMA authentication failed.",
        " Status: ", httr2::resp_status(resp),
        " URL: ", auth_url
      )
    }) |>
    httr2::req_perform()

  body <- httr2::resp_body_json(resp)

  if (is.null(body$token)) {
    abort("SELMA authentication response did not contain a token.")
  }

  str_c("Bearer ", body$token)
}
