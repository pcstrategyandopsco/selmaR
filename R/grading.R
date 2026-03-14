#' Fetch grading schemes from SELMA
#'
#' Retrieves grading scheme definitions with grade boundaries and pass marks.
#'
#' @inheritParams selma_students
#' @return A tibble of grading scheme records.
#' @export
#' @examples
#' \dontrun{
#' con <- selma_connect()
#' grading <- selma_grading_schemes(con)
#' }
selma_grading_schemes <- function(con = NULL, cache = FALSE, cache_dir = "selma_cache",
                                  cache_hours = 24, items_per_page = 100L,
                                  .progress = TRUE) {
  selma_fetch_entity(con, "grading_schemes", "grading_schemes",
                     cache = cache, cache_dir = cache_dir,
                     cache_hours = cache_hours,
                     items_per_page = items_per_page,
                     .progress = .progress)
}
