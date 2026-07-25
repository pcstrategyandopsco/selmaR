#' Upload a document to SELMA (v3 only)
#'
#' Uploads a local file and creates a Document resource in SELMA, optionally
#' associating it with a student, event, or intake enrolment. Wraps the
#' `POST /api/documents` multipart endpoint.
#'
#' This endpoint exists only in the SELMA v3 API. Calling it on a v2 connection
#' errors — document upload is not available in v2.
#'
#' `document_type`, `student`, and `event` accept either a bare ID (e.g. `1` or
#' `"1"`) or a full IRI (`"/api/document_types/1"`); bare IDs are expanded to
#' the IRI form the API expects. Look up valid document types with
#' `selma_get(con, "document_types")`.
#'
#' @param con A `selma_connection` object from [selma_connect()], or `NULL`
#'   to use the stored connection.
#' @param file Path to a local file to upload.
#' @param document_type Document type, as an ID or IRI. Required.
#' @param student Optional student to associate, as an ID or IRI.
#' @param event Optional event to associate, as an ID or IRI.
#' @return A single-row tibble describing the created document, with
#'   `clean_names()` applied.
#' @export
#' @examples
#' \dontrun{
#' con <- selma_connect()
#'
#' # See which document types are configured in your instance
#' selma_get(con, "document_types")
#'
#' # Upload a signed enrolment agreement against a student
#' selma_upload_document(
#'   con,
#'   file          = "agreements/student-42-signed.pdf",
#'   document_type = 1,
#'   student       = 42
#' )
#' }
selma_upload_document <- function(con = NULL, file, document_type,
                                  student = NULL, event = NULL) {
  con <- selma_get_connection(con)

  if (con$api_version != "v3") {
    abort(c(
      "Document upload is not available on this SELMA connection.",
      "x" = str_c("Connected API version is '", con$api_version, "'."),
      "i" = "POST /api/documents exists only in SELMA v3."
    ))
  }

  if (missing(file) || length(file) != 1L || is.na(file)) {
    abort("`file` must be a single path to a local file.")
  }
  if (!file.exists(file)) {
    abort(c(
      str_c("File not found: ", file),
      "i" = "`file` must be a path to an existing local file."
    ))
  }
  if (missing(document_type) || is.null(document_type)) {
    abort("`document_type` is required. See selma_get(con, \"document_types\").")
  }

  cfg <- api_cfg(con$api_version)
  url <- str_c(con$base_url, cfg$path_prefix, "documents")

  body_parts <- list(
    file          = curl::form_file(file),
    document_type = document_iri(document_type, "document_types"),
    student       = document_iri(student, "students"),
    event         = document_iri(event, "events")
  )
  body_parts <- Filter(Negate(is.null), body_parts)

  resp <- httr2::request(url) |>
    httr2::req_headers(Authorization = con$token) |>
    httr2::req_body_multipart(!!!body_parts) |>
    httr2::req_throttle(rate = 2, realm = "selma") |>
    httr2::req_retry(
      max_tries    = 5,
      is_transient = \(resp) httr2::resp_status(resp) %in% c(429L, 500L, 502L, 503L, 504L),
      backoff      = \(i) min(2^i, 60)
    ) |>
    httr2::req_error(body = function(resp) {
      status <- httr2::resp_status(resp)
      if (status == 401L) {
        "SELMA bearer token has expired or is invalid. Re-authenticate with selma_connect()."
      } else {
        str_c("SELMA document upload failed. Status: ", status, " URL: ", url)
      }
    }) |>
    httr2::req_perform()

  parsed <- httr2::resp_body_json(resp, simplifyVector = TRUE)

  # Strip JSON-LD metadata, then flatten NULL/nested fields to NA
  parsed[c("@context", "@id", "@type")] <- NULL
  parsed <- lapply(parsed, function(x) {
    if (is.null(x) || is.list(x)) return(NA)
    x
  })

  result <- as_tibble(as.data.frame(parsed, stringsAsFactors = FALSE))
  standardize_selma_data(result, "documents", api_version = con$api_version)
}

#' Expand a bare ID to a SELMA IRI reference
#'
#' Returns `NULL` for `NULL` input (so optional associations can be dropped from
#' the request body). Values already in path form (`"/api/..."`) pass through
#' unchanged; bare IDs are wrapped as `"/api/{resource}/{id}"`.
#'
#' @param value ID (numeric or character), full IRI, or `NULL`.
#' @param resource v3 resource path segment (e.g. `"students"`).
#' @return Character IRI, or `NULL`.
#' @noRd
document_iri <- function(value, resource) {
  if (is.null(value)) return(NULL)
  value <- as.character(value)
  if (startsWith(value, "/")) return(value)
  str_c("/api/", resource, "/", value)
}
