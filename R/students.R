#' Fetch student records from SELMA
#'
#' Retrieves student records with contact information. Returns a tibble
#' with `clean_names()` applied and IDs as character.
#'
#' @param con A `selma_connection` object from [selma_connect()], or `NULL`
#'   (default) to use the stored connection.
#' @param surname Filter by surname (exact match). Supported in v2 and v3.
#' @param forename Filter by forename / first name (exact match).
#'   Maps to `forename` (v2) or `first_name` (v3).
#' @param email1 Filter by primary email (exact match).
#'   Maps to `email1` (v2) or `email_primary` (v3).
#' @param dob Filter by date of birth (ISO date string, e.g. `"1990-01-15"`).
#'   Maps to `dob` (v2) or `date_of_birth` (v3).
#' @param third_party_id Filter by ThirdPartyID / other_id_1.
#' @param third_party_id2 Filter by ThirdPartyID2 / other_id_2.
#' @param organisation Filter by organisation ID. v2 only — ignored on v3
#'   with a warning.
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

  if (con$api_version == "v3") {
    if (!is.null(organisation)) {
      cli_warn(c(
        "The `organisation` filter is not supported by the SELMA v3 API.",
        "i" = "It has been ignored. Use selma_enrolments(organisation = ...) for v3."
      ))
    }
    query_params <- compact_query(
      surname         = surname,
      first_name      = forename,
      email_primary   = email1,
      date_of_birth   = dob,
      other_id_1      = third_party_id,
      other_id_2      = third_party_id2
    )
  } else {
    query_params <- compact_query(
      surname       = surname,
      forename      = forename,
      email1        = email1,
      dob           = dob,
      ThirdPartyID1 = third_party_id,
      ThirdPartyID2 = third_party_id2,
      Organisation  = organisation
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
