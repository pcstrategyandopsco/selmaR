#' Fetch campus locations from SELMA
#'
#' Retrieves campus/site records with location and contact details.
#'
#' @inheritParams selma_students
#' @return A tibble of campus records with columns including `id`,
#'   `short_name`, `site_code`, `city`, `country`, and `campus_manager`.
#' @export
#' @examples
#' \dontrun{
#' con <- selma_connect()
#' campuses <- selma_campuses(con)
#' }
selma_campuses <- function(con = NULL, cache = FALSE, cache_dir = "selma_cache",
                           cache_hours = 24, items_per_page = 100L,
                           .progress = TRUE) {
  selma_fetch_entity(con, "campuses", "campuses",
                     cache = cache, cache_dir = cache_dir,
                     cache_hours = cache_hours,
                     items_per_page = items_per_page,
                     .progress = .progress)
}
