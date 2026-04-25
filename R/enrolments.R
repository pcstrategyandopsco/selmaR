#' Fetch enrolment records from SELMA
#'
#' Retrieves all enrolment records linking students to intakes.
#' Use the `filter` argument to pass server-side query parameters sourced
#' directly from the SELMA OpenAPI spec. Valid parameter names for the active
#' API version are stored in `.selma_schemas[[version]]$enrolments$params`.
#'
#' @inheritParams selma_students
#' @param filter Named list of API query parameters, e.g.
#'   `list("enrolment_status_date[after]" = "2026-01-01")`.
#'   Unknown names emit a warning and are dropped.
#' @return A tibble of enrolment records.
#' @export
#' @examples
#' \dontrun{
#' selma_connect()
#'
#' # All enrolments
#' enrolments <- selma_enrolments()
#'
#' # Status changed yesterday (v3)
#' enrolments <- selma_enrolments(
#'   filter = list("enrolment_status_date[after]" = "2026-04-23")
#' )
#'
#' # Filter by intake (v3)
#' enrolments <- selma_enrolments(filter = list(intake = "123"))
#' }
selma_enrolments <- make_entity_fetcher("enrolments")
