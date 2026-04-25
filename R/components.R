#' Fetch enrolment components from SELMA
#'
#' Retrieves component-level data (individual course units within a programme).
#' This is typically the largest dataset.
#'
#' Use the `filter` argument to pass server-side query parameters sourced
#' directly from the SELMA OpenAPI spec. Valid parameter names for the active
#' API version are stored in
#' `.selma_schemas[[version]]$enrolment_components$params`.
#'
#' @inheritParams selma_students
#' @return A tibble of enrolment component records.
#' @export
#' @examples
#' \dontrun{
#' selma_connect()
#' components <- selma_components()
#' components <- selma_components(filter = list(enrolment = "456"))
#' }
selma_components <- make_entity_fetcher("enrolment_components")
