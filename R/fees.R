#' Fetch intake fee schedules from SELMA
#'
#' Retrieves fee records associated with intakes.
#'
#' @inheritParams selma_students
#' @return A tibble of intake fee records with columns including `id`,
#'   `fee`, `description`, `category`, `type`, and `duedate`.
#' @export
#' @examples
#' \dontrun{
#' con <- selma_connect()
#' fees <- selma_intake_fees(con)
#' }
selma_intake_fees <- function(con = NULL, cache = FALSE, cache_dir = "selma_cache",
                              cache_hours = 24, items_per_page = 100L,
                              .progress = TRUE) {
  selma_fetch_entity(con, "intake_fees", "intake_fees",
                     cache = cache, cache_dir = cache_dir,
                     cache_hours = cache_hours,
                     items_per_page = items_per_page,
                     .progress = .progress)
}

#' Fetch fees-free eligibility codes from SELMA
#'
#' Retrieves the reference list of fees-free status codes.
#'
#' @inheritParams selma_students
#' @return A tibble of fees-free codes.
#' @export
#' @examples
#' \dontrun{
#' con <- selma_connect()
#' selma_fees_free(con)
#' }
selma_fees_free <- function(con = NULL, cache = FALSE, cache_dir = "selma_cache",
                            cache_hours = 24, items_per_page = 100L,
                            .progress = TRUE) {
  selma_fetch_entity(con, "fees_frees", "fees_frees",
                     cache = cache, cache_dir = cache_dir,
                     cache_hours = cache_hours,
                     items_per_page = items_per_page,
                     .progress = .progress)
}
