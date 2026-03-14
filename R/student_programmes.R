#' Fetch student programme records from SELMA
#'
#' Retrieves a programme-level view of student enrolments, including
#' completion status and programme details.
#'
#' @inheritParams selma_students
#' @param student_id Filter by student ID.
#' @return A tibble of student-programme records with columns including
#'   `student_id`, `enrol_id`, `prog_id`, `prog_title`, `prog_code`,
#'   `enr_status`, and `enr_completion_date`.
#' @export
#' @examples
#' \dontrun{
#' selma_connect()
#' student_progs <- selma_student_programmes()
#' student_progs <- selma_student_programmes(student_id = "123")
#' }
selma_student_programmes <- function(con = NULL, student_id = NULL,
                                     cache = FALSE, cache_dir = "selma_cache",
                                     cache_hours = 24, items_per_page = 100L,
                                     .progress = TRUE) {
  query_params <- compact_query(StudentID = student_id)
  selma_fetch_entity(con, "student_programmes", "student_programmes",
                     query_params = query_params,
                     cache = cache, cache_dir = cache_dir,
                     cache_hours = cache_hours,
                     items_per_page = items_per_page,
                     .progress = .progress)
}
