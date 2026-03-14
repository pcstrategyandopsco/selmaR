#' Fetch intake enrolments with nested components
#'
#' Retrieves enrolments for a specific intake including nested student and
#' component details. Unlike other endpoints, this returns non-paginated
#' nested JSON that is flattened into a tibble.
#'
#' @inheritParams selma_students
#' @param intake_id Integer intake ID to fetch enrolments for.
#' @return A tibble of flattened intake enrolment records.
#' @export
#' @examples
#' \dontrun{
#' selma_connect()
#' ie <- selma_intake_enrolments(intake_id = 123)
#' }
selma_intake_enrolments <- function(con = NULL, intake_id, .progress = TRUE) {
  con <- selma_get_connection(con)

  if (missing(intake_id) || is.null(intake_id) || is.na(intake_id)) {
    abort("`intake_id` is required for selma_intake_enrolments().")
  }

  selma_get(
    con,
    endpoint = "intake_enrolments",
    query_params = list(intakeid = as.integer(intake_id)),
    .progress = .progress
  )
}
