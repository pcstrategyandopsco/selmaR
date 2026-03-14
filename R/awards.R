#' Fetch enrolment awards from SELMA
#'
#' Retrieves award/qualification records linked to enrolments.
#'
#' @inheritParams selma_students
#' @return A tibble of enrolment award records with columns including
#'   `award_id`, `award_code`, `award_name`, `enrol_id`, `prog_id`,
#'   and `prog_type`.
#' @export
#' @examples
#' \dontrun{
#' con <- selma_connect()
#' awards <- selma_enrolment_awards(con)
#' }
selma_enrolment_awards <- function(con = NULL, cache = FALSE, cache_dir = "selma_cache",
                                   cache_hours = 24, items_per_page = 100L,
                                   .progress = TRUE) {
  selma_fetch_entity(con, "enrolment_awards", "enrolment_awards",
                     cache = cache, cache_dir = cache_dir,
                     cache_hours = cache_hours,
                     items_per_page = items_per_page,
                     .progress = .progress)
}
