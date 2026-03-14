#' Fetch component assessment attempts from SELMA
#'
#' Retrieves individual assessment attempt records for enrolment components,
#' including grades, dates, and outcomes.
#'
#' @inheritParams selma_students
#' @param compenrid Filter by enrolment component ID.
#' @return A tibble of component attempt records with columns including
#'   `component_attempt_id`, `compenrid`, `attemptdate`, `attemptgrade`,
#'   and `attemptoutcome`.
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
  query_params <- compact_query(compenrid = compenrid)
  selma_fetch_entity(con, "enrolment_component_attempts", "component_attempts",
                     query_params = query_params,
                     cache = cache, cache_dir = cache_dir,
                     cache_hours = cache_hours,
                     items_per_page = items_per_page,
                     .progress = .progress)
}
