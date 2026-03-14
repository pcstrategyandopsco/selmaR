#' Fetch student records from SELMA
#'
#' Retrieves student records with contact information. Returns a tibble
#' with `clean_names()` applied and IDs as character.
#'
#' @param con A `selma_connection` object from [selma_connect()], or `NULL`
#'   (default) to use the stored connection.
#' @param surname Filter by surname (exact match).
#' @param forename Filter by forename (exact match).
#' @param email1 Filter by primary email (exact match).
#' @param dob Filter by date of birth (ISO date string, e.g. `"1990-01-15"`).
#' @param third_party_id Filter by ThirdPartyID.
#' @param third_party_id2 Filter by ThirdPartyID2.
#' @param organisation Filter by organisation ID.
#' @param cache If `TRUE`, use RDS caching (default `FALSE`).
#' @param cache_dir Directory for cache files (default `"selma_cache"`).
#' @param cache_hours Hours before cache is considered stale (default 24).
#' @param items_per_page Items per API page (default 100).
#' @param .progress Show progress messages (default `TRUE`).
#' @return A tibble of student records.
#' @export
#' @examples
#' \dontrun{
#' selma_connect()
#' students <- selma_students()
#' students <- selma_students(surname = "Smith")
#' students <- selma_students(cache = TRUE, cache_dir = "data")
#' }
selma_students <- function(con = NULL, surname = NULL, forename = NULL,
                           email1 = NULL, dob = NULL, third_party_id = NULL,
                           third_party_id2 = NULL, organisation = NULL,
                           cache = FALSE, cache_dir = "selma_cache",
                           cache_hours = 24, items_per_page = 100L,
                           .progress = TRUE) {
  con <- selma_get_connection(con)
  entity <- "students"

  query_params <- compact_query(
    surname = surname, forename = forename, email1 = email1, dob = dob,
    ThirdPartyID1 = third_party_id, ThirdPartyID2 = third_party_id2,
    Organisation = organisation
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
