#' Fetch notes and events from SELMA
#'
#' Retrieves notes and event records linked to students and enrolments.
#' Notes include pastoral care records, meeting notes, and other
#' student-related documentation.
#'
#' @inheritParams selma_students
#' @return A tibble of note/event records with columns including `noteid`,
#'   `student_id`, `enrolmentid`, `notetype`, `notearea`, `note1`, and
#'   `confidential`.
#' @export
#' @examples
#' \dontrun{
#' con <- selma_connect()
#' notes <- selma_notes(con)
#'
#' # Notes for a specific student
#' student_notes <- notes |>
#'   dplyr::filter(student_id == "123")
#' }
selma_notes <- function(con = NULL, cache = FALSE, cache_dir = "selma_cache",
                        cache_hours = 24, items_per_page = 100L,
                        .progress = TRUE) {
  selma_fetch_entity(con, "notes-events", "notes",
                     cache = cache, cache_dir = cache_dir,
                     cache_hours = cache_hours,
                     items_per_page = items_per_page,
                     .progress = .progress)
}
