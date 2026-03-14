#' Fetch custom field definitions from SELMA
#'
#' Retrieves custom field tab and field definitions configured in SELMA.
#'
#' @inheritParams selma_students
#' @return A tibble of custom field tab records.
#' @export
#' @examples
#' \dontrun{
#' selma_connect()
#' custom_fields <- selma_custom_fields()
#' }
selma_custom_fields <- function(con = NULL, cache = FALSE, cache_dir = "selma_cache",
                                cache_hours = 24, items_per_page = 100L,
                                .progress = TRUE) {
  selma_fetch_entity(con, "custom_fields_tabs", "custom_fields",
                     cache = cache, cache_dir = cache_dir,
                     cache_hours = cache_hours,
                     items_per_page = items_per_page,
                     .progress = .progress)
}

#' Fetch custom field values for a student
#'
#' Retrieves the custom field data stored against a specific student.
#'
#' @param student_id The student ID (required).
#' @param con A `selma_connection` object, or `NULL` to use the stored
#'   connection.
#' @return A tibble of custom field values for the student.
#' @export
#' @examples
#' \dontrun{
#' selma_connect()
#' selma_student_custom_fields("123")
#' }
selma_student_custom_fields <- function(student_id, con = NULL) {
  con <- selma_get_connection(con)
  url <- paste0(con$base_url, "app/student/custom/", student_id)
  resp <- selma_request(con, url)
  resp[c("@context", "@id", "@type")] <- NULL
  if (length(resp) == 0) return(tibble())
  resp <- lapply(resp, function(x) {
    if (is.null(x)) return(NA)
    if (is.list(x)) return(NA)
    x
  })
  result <- as_tibble(as.data.frame(resp, stringsAsFactors = FALSE))
  clean_names(result)
}

#' Fetch custom field values for an enrolment
#'
#' Retrieves the custom field data stored against a specific enrolment.
#'
#' @param enrolment_id The enrolment ID (required).
#' @param con A `selma_connection` object, or `NULL` to use the stored
#'   connection.
#' @return A tibble of custom field values for the enrolment.
#' @export
#' @examples
#' \dontrun{
#' selma_connect()
#' selma_enrolment_custom_fields("456")
#' }
selma_enrolment_custom_fields <- function(enrolment_id, con = NULL) {
  con <- selma_get_connection(con)
  url <- paste0(con$base_url, "app/enrolment/custom/", enrolment_id)
  resp <- selma_request(con, url)
  resp[c("@context", "@id", "@type")] <- NULL
  if (length(resp) == 0) return(tibble())
  resp <- lapply(resp, function(x) {
    if (is.null(x)) return(NA)
    if (is.list(x)) return(NA)
    x
  })
  result <- as_tibble(as.data.frame(resp, stringsAsFactors = FALSE))
  clean_names(result)
}

#' Fetch custom field values for all components in an enrolment
#'
#' Retrieves custom field data for all enrolment components belonging
#' to a specific enrolment.
#'
#' @param enrolment_id The enrolment ID (required).
#' @param con A `selma_connection` object, or `NULL` to use the stored
#'   connection.
#' @return A tibble of custom field values for the enrolment's components.
#' @export
#' @examples
#' \dontrun{
#' selma_connect()
#' selma_component_custom_fields("456")
#' }
selma_component_custom_fields <- function(enrolment_id, con = NULL) {
  con <- selma_get_connection(con)
  url <- paste0(con$base_url, "app/enrolment_component/custom/collection/",
                enrolment_id)
  resp <- selma_request(con, url)
  if (is.null(resp) || length(resp) == 0) return(tibble())
  # May be a list of records
  if (is.data.frame(resp)) {
    return(clean_names(as_tibble(resp)))
  }
  result <- bind_rows(lapply(resp, as.data.frame, stringsAsFactors = FALSE))
  clean_names(as_tibble(result))
}
