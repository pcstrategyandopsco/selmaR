#' Fetch class definitions from SELMA
#'
#' Retrieves timetable class records with capacity and date information.
#'
#' @inheritParams selma_students
#' @param class_name Filter by class name (exact match).
#' @param campus_id Filter by campus ID.
#' @param enrstatus Filter by enrolment status.
#' @return A tibble of class records with columns including `id`,
#'   `class_name`, `capacity`, `startdate`, `enddate`, `campusid`,
#'   and `enrolment_count`.
#' @export
#' @examples
#' \dontrun{
#' selma_connect()
#' classes <- selma_classes()
#' classes <- selma_classes(campus_id = "1")
#' }
selma_classes <- function(con = NULL, class_name = NULL, campus_id = NULL,
                          enrstatus = NULL,
                          cache = FALSE, cache_dir = "selma_cache",
                          cache_hours = 24, items_per_page = 100L,
                          .progress = TRUE) {
  query_params <- compact_query(
    class = class_name, campusid = campus_id, enrstatus = enrstatus
  )
  selma_fetch_entity(con, "classes", "classes",
                     query_params = query_params,
                     cache = cache, cache_dir = cache_dir,
                     cache_hours = cache_hours,
                     items_per_page = items_per_page,
                     .progress = .progress)
}

#' Fetch class enrolment links from SELMA
#'
#' Retrieves records linking enrolments to classes, including student
#' and intake details.
#'
#' @inheritParams selma_students
#' @return A tibble of class enrolment records.
#' @export
#' @examples
#' \dontrun{
#' selma_connect()
#' class_enrolments <- selma_class_enrolments()
#' }
selma_class_enrolments <- function(con = NULL, cache = FALSE, cache_dir = "selma_cache",
                                   cache_hours = 24, items_per_page = 100L,
                                   .progress = TRUE) {
  selma_fetch_entity(con, "class_enrolment", "class_enrolment",
                     cache = cache, cache_dir = cache_dir,
                     cache_hours = cache_hours,
                     items_per_page = items_per_page,
                     .progress = .progress)
}

#' Fetch student class assignments from SELMA
#'
#' Retrieves which students are assigned to which classes.
#'
#' @inheritParams selma_students
#' @param student_id Filter by student ID.
#' @return A tibble of student-class records with columns including
#'   `student_id`, `class`, `campus_id`, `start_date`, and `end_date`.
#' @export
#' @examples
#' \dontrun{
#' selma_connect()
#' student_classes <- selma_student_classes()
#' student_classes <- selma_student_classes(student_id = "123")
#' }
selma_student_classes <- function(con = NULL, student_id = NULL,
                                  cache = FALSE, cache_dir = "selma_cache",
                                  cache_hours = 24, items_per_page = 100L,
                                  .progress = TRUE) {
  query_params <- compact_query(StudentID = student_id)
  selma_fetch_entity(con, "student_classes", "student_classes",
                     query_params = query_params,
                     cache = cache, cache_dir = cache_dir,
                     cache_hours = cache_hours,
                     items_per_page = items_per_page,
                     .progress = .progress)
}
