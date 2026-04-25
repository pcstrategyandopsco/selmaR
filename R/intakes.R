#' Fetch intake definitions from SELMA
#'
#' Retrieves intake (cohort) records with dates and programme links.
#'
#' @inheritParams selma_students
#' @param prog_id Filter by programme ID. v2 only (`ProgID`) — ignored on
#'   v3 with a warning.
#' @param status Filter by intake status (e.g. `"Open"`, `"Closed"`). v2
#'   only (`intakestatus`) — ignored on v3 with a warning.
#' @param start_before Filter intakes starting before this date (ISO string).
#'   Maps to `intakestartdate[before]` (v2) or `start_date[before]` (v3).
#' @param start_after Filter intakes starting after this date (ISO string).
#'   Maps to `intakestartdate[after]` (v2) or `start_date[after]` (v3).
#' @return A tibble of intake records.
#' @export
#' @examples
#' \dontrun{
#' selma_connect()
#' intakes <- selma_intakes()
#' intakes <- selma_intakes(start_after = "2025-01-01")
#' }
selma_intakes <- function(con = NULL, prog_id = NULL, status = NULL,
                          start_before = NULL, start_after = NULL,
                          cache = FALSE, cache_dir = "selma_cache",
                          cache_hours = 24, items_per_page = 100L,
                          .progress = TRUE) {
  con <- selma_get_connection(con)
  entity <- "intakes"

  if (con$api_version == "v3") {
    if (!is.null(prog_id) || !is.null(status)) {
      cli_warn(c(
        "The `prog_id` and `status` filters are not supported by the SELMA v3 intakes API.",
        "i" = "They have been ignored. Fetch all intakes and filter locally if needed."
      ))
    }
    query_params <- compact_query(
      `start_date[before]` = start_before,
      `start_date[after]`  = start_after
    )
  } else {
    query_params <- compact_query(
      ProgID                      = prog_id,
      intakestatus                = status,
      `intakestartdate[before]`   = start_before,
      `intakestartdate[after]`    = start_after
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
