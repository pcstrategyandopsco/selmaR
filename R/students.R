#' Fetch student records from SELMA
#'
#' Retrieves student records with contact information. Returns a tibble
#' with `clean_names()` applied and IDs as character.
#'
#' Use the `filter` argument to pass server-side query parameters sourced
#' directly from the SELMA OpenAPI spec. Valid parameter names for the active
#' API version are stored in `.selma_schemas[[version]]$students$params`.
#'
#' @param con A `selma_connection` object from [selma_connect()], or `NULL`
#'   (default) to use the stored connection.
#' @param filter Named list of API query parameters, e.g.
#'   `list(surname = "Smith", first_name = "Alice")` (v3) or
#'   `list(surname = "Smith", forename = "Alice")` (v2).
#'   Unknown names emit a warning and are dropped.
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
#' students <- selma_students(filter = list(surname = "Smith"))
#' students <- selma_students(filter = list(first_name = "Alice"), cache = TRUE)
#' }
selma_students <- make_entity_fetcher("students")
