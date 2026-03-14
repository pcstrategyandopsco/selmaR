#' Fetch marketing sources from SELMA
#'
#' Retrieves the reference list of marketing/lead sources used to track
#' how students discovered the organisation.
#'
#' @inheritParams selma_students
#' @return A tibble of marketing source records with columns including
#'   `id`, `code`, `name`, and `active`.
#' @export
#' @examples
#' \dontrun{
#' con <- selma_connect()
#' sources <- selma_marketing_sources(con)
#' }
selma_marketing_sources <- function(con = NULL, cache = FALSE,
                                    cache_dir = "selma_cache",
                                    cache_hours = 24,
                                    items_per_page = 100L,
                                    .progress = TRUE) {
  selma_fetch_entity(con, "marketing_sources", "marketing_sources",
                     cache = cache, cache_dir = cache_dir,
                     cache_hours = cache_hours,
                     items_per_page = items_per_page,
                     .progress = .progress)
}
