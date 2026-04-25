#' Fetch event records from SELMA (v3)
#'
#' Retrieves event records from SELMA v3. Events are the v3 equivalent of
#' notes — they link activity records (comments, tasks, emails) to students,
#' enrolments, intakes, contacts, or organisations.
#'
#' In v3, comments (notes) are attached to events rather than directly to
#' students. To get notes with student context, fetch both and use
#' [selma_join_notes()]:
#'
#' ```r
#' con <- selma_connect()
#' notes  <- selma_notes(con)
#' events <- selma_events(con)
#' students <- selma_students(con)
#' notes_with_students <- selma_join_notes(notes, students, events = events)
#' ```
#'
#' @inheritParams selma_students
#' @return A tibble of event records with columns including `id`, `student`,
#'   `enrolment`, `intake`, `event_type`, `event_subject`, `event_body`,
#'   `event_priority`, `event_complete`, and `event_due_date`.
#' @export
#' @examples
#' \dontrun{
#' con <- selma_connect()
#' events <- selma_events(con)
#' events <- selma_events(con, filter = list(student = "42"))
#' }
selma_events <- make_entity_fetcher("events")
