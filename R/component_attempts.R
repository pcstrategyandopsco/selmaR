#' Fetch component assessment attempts from SELMA (v2 only)
#'
#' Retrieves individual assessment attempt records for enrolment components.
#' This endpoint exists in SELMA v2 only. For v3, use [selma_component_grades()].
#'
#' @inheritParams selma_students
#' @param compenrid Filter by enrolment component ID (v2 only).
#' @return A tibble of component attempt records.
#' @export
#' @examples
#' \dontrun{
#' selma_connect()
#' attempts <- selma_component_attempts()
#' attempts <- selma_component_attempts(compenrid = "789")
#' }
selma_component_attempts <- function(con = NULL, compenrid = NULL,
                                     cache = FALSE, cache_dir = "selma_cache",
                                     cache_hours = 24, items_per_page = 100L,
                                     .progress = TRUE) {
  con <- selma_get_connection(con)
  if (con$api_version == "v3") {
    abort(c(
      "selma_component_attempts() uses a v2-only endpoint.",
      "i" = "In v3, use selma_component_grades() to fetch assessment attempt data.",
      "i" = "The v3 equivalent is the enrolment_component_grades endpoint."
    ))
  }
  query_params <- compact_query(compenrid = compenrid)
  selma_fetch_entity(con, "enrolment_component_attempts", "component_attempts",
                     query_params = query_params,
                     cache = cache, cache_dir = cache_dir,
                     cache_hours = cache_hours,
                     items_per_page = items_per_page,
                     .progress = .progress)
}

#' Fetch component grade/attempt records from SELMA (v3)
#'
#' Retrieves `enrolment_component_grades` records — the v3 equivalent of
#' [selma_component_attempts()]. Each record captures one assessment attempt
#' against an enrolment component, including the attempt date, note, numerical
#' value, and grading scheme grade.
#'
#' The `enrolment_component` column contains the IRI-stripped ID of the parent
#' [selma_components()] record. Use [selma_join_attempts()] to join grades back
#' to their parent components.
#'
#' @inheritParams selma_students
#' @return A tibble of enrolment component grade records.
#' @export
#' @examples
#' \dontrun{
#' con <- selma_connect()
#' grades <- selma_component_grades(con)
#' grades <- selma_component_grades(con, filter = list(enrolment_component = "789"))
#' }
selma_component_grades <- make_entity_fetcher("enrolment_component_grades")
