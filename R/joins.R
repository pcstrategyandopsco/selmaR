#' Join enrolments with student details
#'
#' Convenience function that joins enrolments to students. Works on both v2
#' and v3 data — the join key is detected automatically from column names.
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
  if ("student" %in% names(enrolments)) {
    # v3: student is character (IRI-stripped) — cast to integer for join
    enrolments |>
      mutate(.fk = as.integer(student)) |>
      left_join(students, by = c(".fk" = "id"), suffix = c("", ".student")) |>
      select(-.fk)
  } else {
    left_join(enrolments, students,
              by = c("student_id" = "id"),
              suffix = c("", ".student"))
  }
}

#' Join enrolments with intake details
#'
#' Convenience function that joins enrolments to intakes. Works on both v2
#' and v3 data — the join key is detected automatically from column names.
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
  if ("intake" %in% names(enrolments)) {
    # v3: intake is character (IRI-stripped); intakes PK is id
    enrolments |>
      mutate(.fk = as.integer(intake)) |>
      left_join(intakes, by = c(".fk" = "id"), suffix = c("", ".intake")) |>
      select(-.fk)
  } else {
    left_join(enrolments, intakes,
              by = c("intake_id" = "intakeid"),
              suffix = c("", ".intake"))
  }
}

#' Build a complete student enrolment pipeline
#'
#' Joins enrolments to both students and intakes in one step — the most
#' common starting point for SELMA analysis. Works on v2 and v3 data.
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
#' # Filter to funded enrolments
#' active <- pipeline |>
#'   dplyr::filter(enrolment_status %in% SELMA_FUNDED_STATUSES)
#' }
selma_student_pipeline <- function(enrolments, students, intakes) {
  enrolments |>
    selma_join_students(students) |>
    selma_join_intakes(intakes)
}

#' Join components to enrolments
#'
#' Links component-level data (individual course units) back to their
#' parent enrolments. Works on v2 and v3 data.
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
  if ("enrolment" %in% names(components)) {
    # v3: enrolment is character (IRI-stripped); enrolments PK is id
    components |>
      mutate(.fk = as.integer(enrolment)) |>
      left_join(enrolments, by = c(".fk" = "id"), suffix = c("", ".enrolment")) |>
      select(-.fk)
  } else {
    left_join(components, enrolments,
              by = c("enrolid" = "id"),
              suffix = c("", ".enrolment"))
  }
}

#' Join intakes to programme details
#'
#' Links intakes to their parent programme definitions. Works on v2 and v3 data.
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
  if ("programme" %in% names(intakes)) {
    # v3: programme is character (IRI-stripped); programmes PK is id
    intakes |>
      mutate(.fk = as.integer(programme)) |>
      left_join(programmes, by = c(".fk" = "id"), suffix = c("", ".programme")) |>
      select(-.fk)
  } else {
    left_join(intakes, programmes,
              by = "progid",
              suffix = c("", ".programme"))
  }
}

#' Join notes to students
#'
#' Links note records to student records. On v2, notes have a direct
#' `student_id` foreign key. On v3, notes (comments) are linked via events
#' rather than directly to students — this function works on v2 only and
#' aborts with an informative message on v3.
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
  if ("event" %in% names(notes)) {
    abort(c(
      "selma_join_notes() does not support v3 data.",
      "i" = "In v3, comments (notes) link to students via events, not directly.",
      "i" = "Join via: notes |> left_join(events) |> left_join(students)."
    ))
  }
  left_join(notes, students,
            by = c("student_id" = "id"),
            suffix = c("", ".student"))
}

#' Join addresses to students
#'
#' Links address records to their associated students. Works on v2 and v3 data.
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
  if ("student" %in% names(addresses)) {
    # v3: student is character (IRI-stripped)
    addresses |>
      mutate(.fk = as.integer(student)) |>
      left_join(students, by = c(".fk" = "id"), suffix = c("", ".student")) |>
      select(-.fk)
  } else {
    left_join(addresses, students,
              by = c("studentid" = "id"),
              suffix = c("", ".student"))
  }
}

#' Join classes to campuses
#'
#' Links class records to their campus locations. Works on v2 and v3 data.
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
  if ("campus" %in% names(classes)) {
    # v3: campus is character (IRI-stripped)
    classes |>
      mutate(.fk = as.integer(campus)) |>
      left_join(campuses, by = c(".fk" = "id"), suffix = c("", ".campus")) |>
      select(-.fk)
  } else {
    left_join(classes, campuses,
              by = c("campusid" = "id"),
              suffix = c("", ".campus"))
  }
}

#' Join component attempts to enrolment components
#'
#' Links assessment attempt records to their parent enrolment components.
#' The `enrolment_component_attempts` endpoint is v2-only — this function
#' aborts with an informative message if called with v3 data.
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
  if (!"compenrid" %in% names(attempts)) {
    abort(c(
      "selma_join_attempts() requires v2 data.",
      "i" = "The enrolment_component_attempts endpoint does not exist in SELMA v3."
    ))
  }
  left_join(attempts, components,
            by = "compenrid",
            suffix = c("", ".component"))
}

#' Build a full component pipeline
#'
#' Joins components to enrolments, students, and intakes in one step.
#' Works on v2 and v3 data — join keys are detected automatically.
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
    selma_join_students(students) |>
    selma_join_intakes(intakes)
}
