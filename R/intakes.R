#' Fetch intake definitions from SELMA
#'
#' Retrieves intake (cohort) records with dates and programme links.
#'
#' @inheritParams selma_students
#' @param prog_id Filter by programme ID.
#' @param status Filter by intake status (e.g. `"Open"`, `"Closed"`).
#' @param start_before Filter intakes starting before this date (ISO string).
#' @param start_after Filter intakes starting after this date (ISO string).
#' @return A tibble of intake records.
#' @export
#' @examples
#' \dontrun{
#' selma_connect()
#' intakes <- selma_intakes()
#' intakes <- selma_intakes(prog_id = "42")
#' intakes <- selma_intakes(start_after = "2025-01-01")
#' }
selma_intakes <- function(con = NULL, prog_id = NULL, status = NULL,
                          start_before = NULL, start_after = NULL,
                          cache = FALSE, cache_dir = "selma_cache",
                          cache_hours = 24, items_per_page = 100L,
                          .progress = TRUE) {
  con <- selma_get_connection(con)
  entity <- "intakes"

  query_params <- compact_query(
    ProgID = prog_id, intakestatus = status,
    `intakestartdate[before]` = start_before,
    `intakestartdate[after]` = start_after
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

  data <- standardize_selma_data(data, entity)

  if (use_cache) cache_save(data, path, entity)
  data
}
