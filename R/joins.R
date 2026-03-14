#' Join enrolments with student details
#'
#' Convenience function that joins enrolments to students, giving you a
#' combined tibble with student contact details alongside each enrolment.
#'
#' @param enrolments A tibble from [selma_enrolments()].
#' @param students A tibble from [selma_students()].
#' @return A tibble with enrolment and student columns joined.
#' @export
#' @examples
#' \dontrun{
#' con <- selma_connect()
#' enrolments <- selma_enrolments(con)
#' students <- selma_students(con)
#' student_enrolments <- selma_join_students(enrolments, students)
#' }
selma_join_students <- function(enrolments, students) {
  left_join(enrolments, students,
            by = c("student_id" = "id"),
            suffix = c("", ".student"))
}

#' Join enrolments with intake details
#'
#' Convenience function that joins enrolments to intakes, adding intake
#' dates, programme links, and cohort information to each enrolment.
#'
#' @param enrolments A tibble from [selma_enrolments()].
#' @param intakes A tibble from [selma_intakes()].
#' @return A tibble with enrolment and intake columns joined.
#' @export
#' @examples
#' \dontrun{
#' con <- selma_connect()
#' enrolments <- selma_enrolments(con)
#' intakes <- selma_intakes(con)
#' enrolment_intakes <- selma_join_intakes(enrolments, intakes)
#' }
selma_join_intakes <- function(enrolments, intakes) {
  left_join(enrolments, intakes,
            by = c("intake_id" = "intakeid"),
            suffix = c("", ".intake"))
}

#' Build a complete student enrolment pipeline
#'
#' Joins enrolments to both students and intakes in one step — the most
#' common starting point for SELMA analysis.
#'
#' @param enrolments A tibble from [selma_enrolments()].
#' @param students A tibble from [selma_students()].
#' @param intakes A tibble from [selma_intakes()].
#' @return A tibble combining enrolment, student, and intake data.
#' @export
#' @examples
#' \dontrun{
#' con <- selma_connect()
#' pipeline <- selma_student_pipeline(
#'   selma_enrolments(con),
#'   selma_students(con),
#'   selma_intakes(con)
#' )
#'
#' # Filter to funded students
#' active <- pipeline |>
#'   dplyr::filter(enrstatus %in% SELMA_FUNDED_STATUSES)
#' }
selma_student_pipeline <- function(enrolments, students, intakes) {
  enrolments |>
    selma_join_students(students) |>
    selma_join_intakes(intakes)
}

#' Join components to enrolments
#'
#' Links component-level data (individual course units) back to their
#' parent enrolments. Useful for building detailed per-component reports.
#'
#' @param components A tibble from [selma_components()].
#' @param enrolments A tibble from [selma_enrolments()].
#' @return A tibble with component and enrolment columns joined.
#' @export
#' @examples
#' \dontrun{
#' con <- selma_connect()
#' components <- selma_components(con)
#' enrolments <- selma_enrolments(con)
#' component_details <- selma_join_components(components, enrolments)
#' }
selma_join_components <- function(components, enrolments) {
  left_join(components, enrolments,
            by = c("enrolid" = "id"),
            suffix = c("", ".enrolment"))
}

#' Join intakes to programme details
#'
#' Links intakes to their parent programme definitions, adding programme
#' names and metadata to each intake.
#'
#' @param intakes A tibble from [selma_intakes()].
#' @param programmes A tibble from [selma_programmes()].
#' @return A tibble with intake and programme columns joined.
#' @export
#' @examples
#' \dontrun{
#' con <- selma_connect()
#' intakes <- selma_intakes(con)
#' programmes <- selma_programmes(con)
#' intake_programmes <- selma_join_programmes(intakes, programmes)
#' }
selma_join_programmes <- function(intakes, programmes) {
  left_join(intakes, programmes,
            by = "progid",
            suffix = c("", ".programme"))
}

#' Join notes to students
#'
#' Links notes/events to student records.
#'
#' @param notes A tibble from [selma_notes()].
#' @param students A tibble from [selma_students()].
#' @return A tibble with note and student columns joined.
#' @export
#' @examples
#' \dontrun{
#' con <- selma_connect()
#' notes_with_students <- selma_join_notes(
#'   selma_notes(con), selma_students(con)
#' )
#' }
selma_join_notes <- function(notes, students) {
  left_join(notes, students,
            by = c("student_id" = "id"),
            suffix = c("", ".student"))
}

#' Join addresses to students
#'
#' Links address records to their associated students.
#'
#' @param addresses A tibble from [selma_addresses()].
#' @param students A tibble from [selma_students()].
#' @return A tibble with address and student columns joined.
#' @export
#' @examples
#' \dontrun{
#' con <- selma_connect()
#' student_addresses <- selma_join_addresses(
#'   selma_addresses(con), selma_students(con)
#' )
#' }
selma_join_addresses <- function(addresses, students) {
  left_join(addresses, students,
            by = c("studentid" = "id"),
            suffix = c("", ".student"))
}

#' Join classes to campuses
#'
#' Links class records to their campus locations.
#'
#' @param classes A tibble from [selma_classes()].
#' @param campuses A tibble from [selma_campuses()].
#' @return A tibble with class and campus columns joined.
#' @export
#' @examples
#' \dontrun{
#' con <- selma_connect()
#' class_campuses <- selma_join_classes(
#'   selma_classes(con), selma_campuses(con)
#' )
#' }
selma_join_classes <- function(classes, campuses) {
  left_join(classes, campuses,
            by = c("campusid" = "id"),
            suffix = c("", ".campus"))
}

#' Join component attempts to enrolment components
#'
#' Links assessment attempt records to their parent enrolment components.
#'
#' @param attempts A tibble from [selma_component_attempts()].
#' @param components A tibble from [selma_components()].
#' @return A tibble with attempt and component columns joined.
#' @export
#' @examples
#' \dontrun{
#' con <- selma_connect()
#' attempt_details <- selma_join_attempts(
#'   selma_component_attempts(con), selma_components(con)
#' )
#' }
selma_join_attempts <- function(attempts, components) {
  left_join(attempts, components,
            by = "compenrid",
            suffix = c("", ".component"))
}

#' Build a full component pipeline
#'
#' Joins components to enrolments, students, and intakes in one step.
#' Useful for building detailed per-component reports with full student
#' and intake context.
#'
#' @param components A tibble from [selma_components()].
#' @param enrolments A tibble from [selma_enrolments()].
#' @param students A tibble from [selma_students()].
#' @param intakes A tibble from [selma_intakes()].
#' @return A tibble combining component, enrolment, student, and intake data.
#' @export
#' @examples
#' \dontrun{
#' con <- selma_connect()
#' full_components <- selma_component_pipeline(
#'   selma_components(con),
#'   selma_enrolments(con),
#'   selma_students(con),
#'   selma_intakes(con)
#' )
#' }
selma_component_pipeline <- function(components, enrolments, students, intakes) {
  components |>
    selma_join_components(enrolments) |>
    left_join(students,
              by = c("student_id" = "id"),
              suffix = c("", ".student")) |>
    left_join(intakes,
              by = c("intake_id" = "intakeid"),
              suffix = c("", ".intake"))
}
