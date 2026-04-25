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
#' Links note records to student records. Works on both v2 and v3 data:
#'
#' - **v2**: notes have a direct `student_id` foreign key — joined in one step.
#' - **v3**: notes (comments) link to students via events. Pass the events
#'   tibble from [selma_events()] via the `events` argument to enable the
#'   two-step join: comments → events → students.
#'
#' @param notes A tibble from [selma_notes()].
#' @param students A tibble from [selma_students()].
#' @param events A tibble from [selma_events()] (required for v3 data, ignored
#'   on v2).
#' @return A tibble with note and student columns joined.
#' @export
#' @examples
#' \dontrun{
#' con <- selma_connect()
#'
#' # v2
#' selma_join_notes(selma_notes(con), selma_students(con))
#'
#' # v3
#' selma_join_notes(
#'   selma_notes(con),
#'   selma_students(con),
#'   events = selma_events(con)
#' )
#' }
selma_join_notes <- function(notes, students, events = NULL) {
  if ("event" %in% names(notes)) {
    # v3: comments → events → students (two-step join)
    if (is.null(events)) {
      abort(c(
        "selma_join_notes() requires an events tibble for v3 data.",
        "i" = "In v3, comments link to students via events — not directly.",
        "i" = "Fetch events with selma_events(con) and pass as events = ..."
      ))
    }
    # Step 1: join comments to events
    notes_events <- notes |>
      mutate(.event_fk = as.integer(event)) |>
      left_join(events, by = c(".event_fk" = "id"), suffix = c("", ".event")) |>
      select(-.event_fk)
    # Step 2: join to students via event.student
    notes_events |>
      mutate(.student_fk = as.integer(student)) |>
      left_join(students, by = c(".student_fk" = "id"), suffix = c("", ".student")) |>
      select(-.student_fk)
  } else {
    left_join(notes, students,
              by = c("student_id" = "id"),
              suffix = c("", ".student"))
  }
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

#' Join component attempts (or grades) to enrolment components
#'
#' Links assessment attempt records to their parent enrolment components.
#' Works on both v2 and v3 data:
#'
#' - **v2**: pass a tibble from [selma_component_attempts()] — joined via
#'   the shared `compenrid` key.
#' - **v3**: pass a tibble from [selma_component_grades()] — joined via the
#'   `enrolment_component` IRI-reference column.
#'
#' @param attempts A tibble from [selma_component_attempts()] (v2) or
#'   [selma_component_grades()] (v3).
#' @param components A tibble from [selma_components()].
#' @return A tibble with attempt/grade and component columns joined.
#' @export
#' @examples
#' \dontrun{
#' con <- selma_connect()
#'
#' # v2
#' selma_join_attempts(selma_component_attempts(con), selma_components(con))
#'
#' # v3
#' selma_join_attempts(selma_component_grades(con), selma_components(con))
#' }
selma_join_attempts <- function(attempts, components) {
  if ("enrolment_component" %in% names(attempts)) {
    # v3: enrolment_component is character (IRI-stripped); components PK is id
    attempts |>
      mutate(.fk = as.integer(enrolment_component)) |>
      left_join(components, by = c(".fk" = "id"), suffix = c("", ".component")) |>
      select(-.fk)
  } else if ("compenrid" %in% names(attempts)) {
    # v2: both tables share compenrid as the join key
    left_join(attempts, components,
              by = "compenrid",
              suffix = c("", ".component"))
  } else {
    abort(c(
      "selma_join_attempts() could not determine data version.",
      "i" = "Expected 'enrolment_component' (v3, from selma_component_grades()) or 'compenrid' (v2)."
    ))
  }
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
