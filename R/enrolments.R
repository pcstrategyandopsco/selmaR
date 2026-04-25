#' Fetch enrolment records from SELMA
#'
#' Retrieves all enrolment records linking students to intakes.
#'
#' @inheritParams selma_students
#' @param intake_id Filter by intake ID. v3 only — ignored on v2 with a
#'   warning.
#' @param student_id Filter by student ID. v3 only — ignored on v2 with a
#'   warning.
#' @return A tibble of enrolment records.
#' @export
#' @examples
#' \dontrun{
#' selma_connect()
#' enrolments <- selma_enrolments()
#' enrolments <- selma_enrolments(intake_id = "123")  # v3 only
#' }
selma_enrolments <- function(con = NULL, intake_id = NULL, student_id = NULL,
                             cache = FALSE, cache_dir = "selma_cache",
                             cache_hours = 24, items_per_page = 100L,
                             .progress = TRUE) {
  con <- selma_get_connection(con)
  entity <- "enrolments"

  if (con$api_version == "v2") {
    if (!is.null(intake_id) || !is.null(student_id)) {
      cli_warn(c(
        "The `intake_id` and `student_id` filters are not supported by the SELMA v2 API.",
        "i" = "They have been ignored. Upgrade to v3 to filter enrolments server-side."
      ))
    }
    query_params <- NULL
  } else {
    query_params <- compact_query(
      intake  = intake_id,
      student = student_id
    )
  }

  use_cache <- cache && is.null(query_params)
  path <- cache_path(cache_dir, entity)

  if (use_cache && cache_is_fresh(path, cache_hours)) {
    return(cache_load(path, entity))
  }

  data <- selma_get(
    con, entity,
    query_params = query_params,
    items_per_page = items_per_page,
    .progress = .progress
  )

  data <- standardize_selma_data(data, entity, api_version = con$api_version)

  if (use_cache) cache_save(data, path, entity)
  data
}
