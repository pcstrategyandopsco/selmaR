#' Fetch component definitions from SELMA
#'
#' Retrieves component (unit standard/course) definitions — the master list
#' of components available across programmes. This is different from
#' [selma_components()] which returns *enrolment* components (instances
#' of components attached to student enrolments).
#'
#' @inheritParams selma_students
#' @return A tibble of component definitions with columns including
#'   `compid`, `compcode`, `comptitle`, `compefts`, `comptype`,
#'   `compcrediteq`, and `complevelfw`.
#' @export
#' @examples
#' \dontrun{
#' con <- selma_connect()
#' comp_defs <- selma_component_definitions(con)
#' }
selma_component_definitions <- function(con = NULL, cache = FALSE,
                                        cache_dir = "selma_cache",
                                        cache_hours = 24,
                                        items_per_page = 100L,
                                        .progress = TRUE) {
  selma_fetch_entity(con, "components", "component_definitions",
                     cache = cache, cache_dir = cache_dir,
                     cache_hours = cache_hours,
                     items_per_page = items_per_page,
                     .progress = .progress)
}
