#' Fetch system users from SELMA
#'
#' Retrieves user accounts configured in the SELMA instance.
#'
#' @inheritParams selma_students
#' @return A tibble of user records with columns including `id`, `username`,
#'   `email`, `firstname`, `lastname`, `roles`, and `is_active`.
#' @export
#' @examples
#' \dontrun{
#' con <- selma_connect()
#' users <- selma_users(con)
#' }
selma_users <- function(con = NULL, cache = FALSE, cache_dir = "selma_cache",
                        cache_hours = 24, items_per_page = 100L,
                        .progress = TRUE) {
  selma_fetch_entity(con, "users", "users",
                     cache = cache, cache_dir = cache_dir,
                     cache_hours = cache_hours,
                     items_per_page = items_per_page,
                     .progress = .progress)
}
