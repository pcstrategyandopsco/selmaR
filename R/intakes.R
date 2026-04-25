#' Fetch intake definitions from SELMA
#'
#' Retrieves intake (cohort) records with dates and programme links.
#'
#' Use the `filter` argument to pass server-side query parameters sourced
#' directly from the SELMA OpenAPI spec. Valid parameter names for the active
#' API version are stored in `.selma_schemas[[version]]$intakes$params`.
#'
#' @inheritParams selma_students
#' @return A tibble of intake records.
#' @export
#' @examples
#' \dontrun{
#' selma_connect()
#' intakes <- selma_intakes()
#' intakes <- selma_intakes(filter = list("start_date[after]" = "2025-01-01"))
#' }
selma_intakes <- make_entity_fetcher("intakes")
