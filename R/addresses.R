#' Fetch addresses from SELMA
#'
#' Retrieves address records linked to students, contacts, or organisations.
#'
#' @inheritParams selma_students
#' @param student_id Filter by student ID.
#' @param contact_id Filter by contact ID.
#' @param org_id Filter by organisation ID.
#' @return A tibble of address records with columns including `addressid`,
#'   `studentid`, `contactid`, `orgid`, `street`, `suburb`, `city`,
#'   `region`, `postcode`, and `country`.
#' @export
#' @examples
#' \dontrun{
#' selma_connect()
#' addresses <- selma_addresses()
#' addresses <- selma_addresses(student_id = "123")
#' }
selma_addresses <- function(con = NULL, student_id = NULL, contact_id = NULL,
                            org_id = NULL,
                            cache = FALSE, cache_dir = "selma_cache",
                            cache_hours = 24, items_per_page = 100L,
                            .progress = TRUE) {
  query_params <- compact_query(
    StudentID = student_id, contactid = contact_id, orgid = org_id
  )
  selma_fetch_entity(con, "addresses", "addresses",
                     query_params = query_params,
                     cache = cache, cache_dir = cache_dir,
                     cache_hours = cache_hours,
                     items_per_page = items_per_page,
                     .progress = .progress)
}

#' Fetch address types from SELMA
#'
#' Retrieves the reference list of address types.
#'
#' @inheritParams selma_students
#' @return A tibble of address type codes.
#' @export
#' @examples
#' \dontrun{
#' selma_connect()
#' selma_address_types()
#' }
selma_address_types <- function(con = NULL, cache = FALSE, cache_dir = "selma_cache",
                                cache_hours = 24, items_per_page = 100L,
                                .progress = TRUE) {
  selma_fetch_entity(con, "address_types", "address_types",
                     cache = cache, cache_dir = cache_dir,
                     cache_hours = cache_hours,
                     items_per_page = items_per_page,
                     .progress = .progress)
}
