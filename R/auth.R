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
#' 2. **config.yml** — via the config package (`selma` key; see below)
#' 3. **Environment variables** — `SELMA_BASE_URL`, `SELMA_EMAIL`, `SELMA_PASSWORD`
#'
#' @section config.yml:
#' Create a `config.yml` in your project root (add to `.gitignore`!):
#'
#' ```yaml
#' default:
#'   selma:
#'     base_url: "https://myorg.selma.co.nz/"
#'     email: "api@selma.co.nz"
#'     password: "secret"
#' ```
#'
#' @param base_url SELMA base URL (e.g. `"https://myorg.selma.co.nz/"`).
#' @param email API login email.
#' @param password API login password.
#' @param config_file Path to a config YAML file (default `"config.yml"`).
#'   Set to `NULL` to skip config file lookup.
#' @return A `selma_connection` object (invisibly). The connection is also
#'   stored in the package environment for automatic use by all fetch functions.
#' @export
#' @examples
#' \dontrun{
#' # Connect once — all functions use it automatically
#' selma_connect()
#' students <- selma_students()
#' enrolments <- selma_enrolments()
#'
#' # Or pass credentials directly
#' selma_connect(
#'   base_url = "https://myorg.selma.co.nz/",
#'   email = "api@selma.co.nz",
#'   password = "secret"
#' )
#' }
selma_connect <- function(base_url = NULL, email = NULL, password = NULL,
                          config_file = "config.yml") {

  # Resolve credentials: args > config.yml > env vars
  cfg <- selma_resolve_config(base_url, email, password, config_file)

  if (cfg$base_url == "") {
    abort(c(
      "SELMA base_url not found.",
      "i" = "Set it via argument, config.yml (selma.base_url), or SELMA_BASE_URL env var."
    ))
  }
  if (cfg$email == "") {
    abort(c(
      "SELMA email not found.",
      "i" = "Set it via argument, config.yml (selma.email), or SELMA_EMAIL env var."
    ))
  }
  if (cfg$password == "") {
    abort(c(
      "SELMA password not found.",
      "i" = "Set it via argument, config.yml (selma.password), or SELMA_PASSWORD env var."
    ))
  }

  # Ensure trailing slash
  if (!grepl("/$", cfg$base_url)) {
    cfg$base_url <- paste0(cfg$base_url, "/")
  }

  token <- selma_auth(cfg$base_url, cfg$email, cfg$password)

  con <- structure(
    list(
      base_url = cfg$base_url,
      token = token
    ),
    class = "selma_connection"
  )

  # Store in package environment for automatic use
  selma_env$connection <- con

  cli_alert_success("Connected to SELMA at {.url {cfg$base_url}}")
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
#' no connection exists. Used internally by all fetch functions.
#'
#' @param con Optional explicit connection. If `NULL`, uses the stored
#'   connection from [selma_connect()].
#' @return A `selma_connection` object.
#' @noRd
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
  cat("  Base URL:", x$base_url, "\n")
  cat("  Token:   ", substr(x$token, 1, 20), "...\n")
  invisible(x)
}

#' Resolve SELMA config from args, config.yml, or env vars
#' @noRd
selma_resolve_config <- function(base_url, email, password, config_file) {
  # Start with direct args (may be NULL)
  result <- list(
    base_url = base_url %||% "",
    email = email %||% "",
    password = password %||% ""
  )

  # Try config.yml for any missing values
  if (!is.null(config_file) && file.exists(config_file)) {
    cfg <- tryCatch(
      config::get("selma", file = config_file),
      error = function(e) NULL
    )
    if (!is.null(cfg)) {
      if (result$base_url == "") result$base_url <- cfg$base_url %||% ""
      if (result$email == "") result$email <- cfg$email %||% ""
      if (result$password == "") result$password <- cfg$password %||% ""
    }
  }

  # Fall back to env vars for anything still missing
  if (result$base_url == "") result$base_url <- Sys.getenv("SELMA_BASE_URL")
  if (result$email == "") result$email <- Sys.getenv("SELMA_EMAIL")
  if (result$password == "") result$password <- Sys.getenv("SELMA_PASSWORD")

  result
}

#' Authenticate with the SELMA API
#'
#' @param base_url SELMA base URL.
#' @param email Login email.
#' @param password Login password.
#' @return Bearer token string (e.g. `"Bearer eyJ..."`).
#' @noRd
selma_auth <- function(base_url, email, password) {
  auth_url <- paste0(base_url, "login_check")

  resp <- httr2::request(auth_url) |>
    httr2::req_headers(Authorization = "Basic") |>
    httr2::req_body_json(list(email = email, password = password)) |>
    httr2::req_error(body = function(resp) {
      paste(
        "SELMA authentication failed.",
        "Status:", httr2::resp_status(resp),
        "URL:", auth_url
      )
    }) |>
    httr2::req_perform()

  body <- httr2::resp_body_json(resp)

  if (is.null(body$token)) {
    abort("SELMA authentication response did not contain a token.")
  }

  paste("Bearer", body$token)
}
