#' Fetch programme definitions from SELMA
#'
#' Retrieves programme (qualification) records.
#'
#' @inheritParams selma_students
#' @param status Filter by programme status (e.g. `"Active"`, `"Inactive"`).
#'   v2 only (`progstatus`) — ignored on v3 with a warning.
#' @return A tibble of programme records.
#' @export
#' @examples
#' \dontrun{
#' selma_connect()
#' programmes <- selma_programmes()
#' programmes <- selma_programmes(status = "Active")
#' }
selma_programmes <- function(con = NULL, status = NULL,
                             cache = FALSE, cache_dir = "selma_cache",
                             cache_hours = 24, items_per_page = 100L,
                             .progress = TRUE) {
  con <- selma_get_connection(con)
  entity <- "programmes"

  if (con$api_version == "v3" && !is.null(status)) {
    cli_warn(c(
      "The `status` filter is not supported by the SELMA v3 programmes API.",
      "i" = "It has been ignored. Fetch all programmes and filter locally if needed."
    ))
  }

  query_params <- if (con$api_version == "v2") {
    compact_query(progstatus = status)
  } else {
    NULL
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
