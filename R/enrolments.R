#' Fetch enrolment records from SELMA
#'
#' Retrieves all enrolment records linking students to intakes.
#'
#' @inheritParams selma_students
#' @return A tibble of enrolment records.
#' @export
#' @examples
#' \dontrun{
#' selma_connect()
#' enrolments <- selma_enrolments()
#' }
selma_enrolments <- function(con = NULL, cache = FALSE, cache_dir = "selma_cache",
                             cache_hours = 24, items_per_page = 100L,
                             .progress = TRUE) {
  con <- selma_get_connection(con)
  entity <- "enrolments"
  path <- cache_path(cache_dir, entity)

  if (cache && cache_is_fresh(path, cache_hours)) {
    return(cache_load(path, entity))
  }

  data <- selma_get(
    con, entity,
    items_per_page = items_per_page,
    .progress = .progress
  )

  data <- standardize_selma_data(data, entity)

  if (cache) cache_save(data, path, entity)

  data
}
