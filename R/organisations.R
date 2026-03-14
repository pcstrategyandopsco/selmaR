#' Fetch organisations from SELMA
#'
#' Retrieves organisation records (employers, agents, partner institutions).
#'
#' @inheritParams selma_students
#' @param org_id Filter by organisation ID.
#' @param name Filter by organisation name (exact match).
#' @param third_party_id Filter by third-party ID.
#' @param registration_number Filter by registration number.
#' @return A tibble of organisation records with columns including `id`,
#'   `name`, `legalname`, `orgtype`, `email`, `phone`, and `country`.
#' @export
#' @examples
#' \dontrun{
#' selma_connect()
#' orgs <- selma_organisations()
#' orgs <- selma_organisations(name = "Acme Ltd")
#' }
selma_organisations <- function(con = NULL, org_id = NULL, name = NULL,
                                third_party_id = NULL,
                                registration_number = NULL,
                                cache = FALSE, cache_dir = "selma_cache",
                                cache_hours = 24, items_per_page = 100L,
                                .progress = TRUE) {
  query_params <- compact_query(
    id = org_id, name = name, thirdpartyid = third_party_id,
    registrationNumber = registration_number
  )
  selma_fetch_entity(con, "organisations", "organisations",
                     query_params = query_params,
                     cache = cache, cache_dir = cache_dir,
                     cache_hours = cache_hours,
                     items_per_page = items_per_page,
                     .progress = .progress)
}

#' Fetch organisation types from SELMA
#'
#' Retrieves the reference list of organisation types.
#'
#' @inheritParams selma_students
#' @return A tibble of organisation type codes.
#' @export
#' @examples
#' \dontrun{
#' selma_connect()
#' selma_org_types()
#' }
selma_org_types <- function(con = NULL, cache = FALSE, cache_dir = "selma_cache",
                            cache_hours = 24, items_per_page = 100L,
                            .progress = TRUE) {
  selma_fetch_entity(con, "org_types", "org_types",
                     cache = cache, cache_dir = cache_dir,
                     cache_hours = cache_hours,
                     items_per_page = items_per_page,
                     .progress = .progress)
}
