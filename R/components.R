#' Fetch enrolment components from SELMA
#'
#' Retrieves component-level data (individual course units within a
#' programme). This is typically the largest dataset.
#'
#' @inheritParams selma_students
#' @param student_id Filter by student ID.
#' @param enrol_id Filter by enrolment ID.
#' @return A tibble of enrolment component records.
#' @export
#' @examples
#' \dontrun{
#' selma_connect()
#' components <- selma_components()
#' components <- selma_components(student_id = "123")
#' components <- selma_components(enrol_id = "456")
#' }
selma_components <- function(con = NULL, student_id = NULL, enrol_id = NULL,
                             cache = FALSE, cache_dir = "selma_cache",
                             cache_hours = 24, items_per_page = 100L,
                             .progress = TRUE) {
  con <- selma_get_connection(con)
  entity <- "enrolment_components"

  query_params <- compact_query(
    studentid = student_id, enrolid = enrol_id
  )

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

  data <- standardize_selma_data(data, "components")

  if (use_cache) cache_save(data, path, entity)
  data
}
