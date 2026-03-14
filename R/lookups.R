#' Fetch ethnicity codes from SELMA
#'
#' @inheritParams selma_students
#' @return A tibble of ethnicity codes.
#' @export
#' @examples
#' \dontrun{
#' selma_ethnicities(selma_connect())
#' }
selma_ethnicities <- function(con = NULL, cache = FALSE, cache_dir = "selma_cache",
                              cache_hours = 24, items_per_page = 100L,
                              .progress = TRUE) {
  selma_fetch_entity(con, "ethnicities", "ethnicities",
                     cache = cache, cache_dir = cache_dir,
                     cache_hours = cache_hours,
                     items_per_page = items_per_page,
                     .progress = .progress)
}

#' Fetch country codes from SELMA
#'
#' @inheritParams selma_students
#' @return A tibble of country codes.
#' @export
#' @examples
#' \dontrun{
#' selma_countries(selma_connect())
#' }
selma_countries <- function(con = NULL, cache = FALSE, cache_dir = "selma_cache",
                            cache_hours = 24, items_per_page = 100L,
                            .progress = TRUE) {
  selma_fetch_entity(con, "countries", "countries",
                     cache = cache, cache_dir = cache_dir,
                     cache_hours = cache_hours,
                     items_per_page = items_per_page,
                     .progress = .progress)
}

#' Fetch gender codes from SELMA
#'
#' @inheritParams selma_students
#' @return A tibble of gender codes.
#' @export
#' @examples
#' \dontrun{
#' selma_genders(selma_connect())
#' }
selma_genders <- function(con = NULL, cache = FALSE, cache_dir = "selma_cache",
                          cache_hours = 24, items_per_page = 100L,
                          .progress = TRUE) {
  selma_fetch_entity(con, "genders", "genders",
                     cache = cache, cache_dir = cache_dir,
                     cache_hours = cache_hours,
                     items_per_page = items_per_page,
                     .progress = .progress)
}

#' Fetch title codes from SELMA
#'
#' @inheritParams selma_students
#' @return A tibble of title codes (Mr, Mrs, etc.).
#' @export
#' @examples
#' \dontrun{
#' selma_titles(selma_connect())
#' }
selma_titles <- function(con = NULL, cache = FALSE, cache_dir = "selma_cache",
                         cache_hours = 24, items_per_page = 100L,
                         .progress = TRUE) {
  selma_fetch_entity(con, "titles", "titles",
                     cache = cache, cache_dir = cache_dir,
                     cache_hours = cache_hours,
                     items_per_page = items_per_page,
                     .progress = .progress)
}

#' Fetch disability codes from SELMA
#'
#' @inheritParams selma_students
#' @return A tibble of disability codes.
#' @export
#' @examples
#' \dontrun{
#' selma_disabilities(selma_connect())
#' }
selma_disabilities <- function(con = NULL, cache = FALSE, cache_dir = "selma_cache",
                               cache_hours = 24, items_per_page = 100L,
                               .progress = TRUE) {
  selma_fetch_entity(con, "disabilities", "disabilities",
                     cache = cache, cache_dir = cache_dir,
                     cache_hours = cache_hours,
                     items_per_page = items_per_page,
                     .progress = .progress)
}

#' Fetch disability access codes from SELMA
#'
#' @inheritParams selma_students
#' @return A tibble of disability access codes.
#' @export
#' @examples
#' \dontrun{
#' selma_disability_accesses(selma_connect())
#' }
selma_disability_accesses <- function(con = NULL, cache = FALSE,
                                      cache_dir = "selma_cache",
                                      cache_hours = 24,
                                      items_per_page = 100L,
                                      .progress = TRUE) {
  selma_fetch_entity(con, "disability_accesses", "disability_accesses",
                     cache = cache, cache_dir = cache_dir,
                     cache_hours = cache_hours,
                     items_per_page = items_per_page,
                     .progress = .progress)
}

#' Fetch visa type codes from SELMA
#'
#' @inheritParams selma_students
#' @return A tibble of visa type codes.
#' @export
#' @examples
#' \dontrun{
#' selma_visa_types(selma_connect())
#' }
selma_visa_types <- function(con = NULL, cache = FALSE, cache_dir = "selma_cache",
                             cache_hours = 24, items_per_page = 100L,
                             .progress = TRUE) {
  selma_fetch_entity(con, "visa_types", "visa_types",
                     cache = cache, cache_dir = cache_dir,
                     cache_hours = cache_hours,
                     items_per_page = items_per_page,
                     .progress = .progress)
}

#' Fetch NZ iwi codes from SELMA
#'
#' @inheritParams selma_students
#' @return A tibble of NZ iwi codes.
#' @export
#' @examples
#' \dontrun{
#' selma_nz_iwis(selma_connect())
#' }
selma_nz_iwis <- function(con = NULL, cache = FALSE, cache_dir = "selma_cache",
                          cache_hours = 24, items_per_page = 100L,
                          .progress = TRUE) {
  selma_fetch_entity(con, "nz_iwis", "nz_iwis",
                     cache = cache, cache_dir = cache_dir,
                     cache_hours = cache_hours,
                     items_per_page = items_per_page,
                     .progress = .progress)
}

#' Fetch secondary school codes from SELMA
#'
#' @inheritParams selma_students
#' @return A tibble of secondary school codes.
#' @export
#' @examples
#' \dontrun{
#' selma_secondary_schools(selma_connect())
#' }
selma_secondary_schools <- function(con = NULL, cache = FALSE,
                                    cache_dir = "selma_cache",
                                    cache_hours = 24,
                                    items_per_page = 100L,
                                    .progress = TRUE) {
  selma_fetch_entity(con, "secondary_schools", "secondary_schools",
                     cache = cache, cache_dir = cache_dir,
                     cache_hours = cache_hours,
                     items_per_page = items_per_page,
                     .progress = .progress)
}

#' Fetch secondary qualification codes from SELMA
#'
#' @inheritParams selma_students
#' @return A tibble of secondary qualification codes.
#' @export
#' @examples
#' \dontrun{
#' selma_secondary_quals(selma_connect())
#' }
selma_secondary_quals <- function(con = NULL, cache = FALSE, cache_dir = "selma_cache",
                                  cache_hours = 24, items_per_page = 100L,
                                  .progress = TRUE) {
  selma_fetch_entity(con, "secondary_quals", "secondary_quals",
                     cache = cache, cache_dir = cache_dir,
                     cache_hours = cache_hours,
                     items_per_page = items_per_page,
                     .progress = .progress)
}

#' Fetch previous activity codes from SELMA
#'
#' @inheritParams selma_students
#' @return A tibble of previous activity codes.
#' @export
#' @examples
#' \dontrun{
#' selma_previous_activities(selma_connect())
#' }
selma_previous_activities <- function(con = NULL, cache = FALSE,
                                      cache_dir = "selma_cache",
                                      cache_hours = 24,
                                      items_per_page = 100L,
                                      .progress = TRUE) {
  selma_fetch_entity(con, "previous_activities", "previous_activities",
                     cache = cache, cache_dir = cache_dir,
                     cache_hours = cache_hours,
                     items_per_page = items_per_page,
                     .progress = .progress)
}

#' Fetch student status codes from SELMA
#'
#' @inheritParams selma_students
#' @return A tibble of student status codes.
#' @export
#' @examples
#' \dontrun{
#' selma_student_statuses(selma_connect())
#' }
selma_student_statuses <- function(con = NULL, cache = FALSE, cache_dir = "selma_cache",
                                   cache_hours = 24, items_per_page = 100L,
                                   .progress = TRUE) {
  selma_fetch_entity(con, "student_statuses", "student_statuses",
                     cache = cache, cache_dir = cache_dir,
                     cache_hours = cache_hours,
                     items_per_page = items_per_page,
                     .progress = .progress)
}

#' Fetch NZ residential status codes from SELMA
#'
#' @inheritParams selma_students
#' @return A tibble of NZ residential status codes.
#' @export
#' @examples
#' \dontrun{
#' selma_nz_residential_statuses(selma_connect())
#' }
selma_nz_residential_statuses <- function(con = NULL, cache = FALSE,
                                          cache_dir = "selma_cache",
                                          cache_hours = 24,
                                          items_per_page = 100L,
                                          .progress = TRUE) {
  selma_fetch_entity(con, "n_z_residential_statuses", "nz_residential_statuses",
                     cache = cache, cache_dir = cache_dir,
                     cache_hours = cache_hours,
                     items_per_page = items_per_page,
                     .progress = .progress)
}

#' Fetch NZ disability status codes from SELMA
#'
#' @inheritParams selma_students
#' @return A tibble of NZ disability status codes.
#' @export
#' @examples
#' \dontrun{
#' selma_nz_disability_statuses(selma_connect())
#' }
selma_nz_disability_statuses <- function(con = NULL, cache = FALSE,
                                         cache_dir = "selma_cache",
                                         cache_hours = 24,
                                         items_per_page = 100L,
                                         .progress = TRUE) {
  selma_fetch_entity(con, "new_zealand_disability_statuses",
                     "nz_disability_statuses",
                     cache = cache, cache_dir = cache_dir,
                     cache_hours = cache_hours,
                     items_per_page = items_per_page,
                     .progress = .progress)
}

#' Fetch NZ disability support needs codes from SELMA
#'
#' @inheritParams selma_students
#' @return A tibble of NZ disability support needs codes.
#' @export
#' @examples
#' \dontrun{
#' selma_nz_disability_support_needs(selma_connect())
#' }
selma_nz_disability_support_needs <- function(con = NULL, cache = FALSE,
                                              cache_dir = "selma_cache",
                                              cache_hours = 24,
                                              items_per_page = 100L,
                                              .progress = TRUE) {
  selma_fetch_entity(con, "new_zealand_disability_support_needs",
                     "nz_disability_support_needs",
                     cache = cache, cache_dir = cache_dir,
                     cache_hours = cache_hours,
                     items_per_page = items_per_page,
                     .progress = .progress)
}

#' Fetch withdrawal reason codes from SELMA
#'
#' Retrieves reason codes that explain *why* a student was withdrawn
#' (e.g. personal, academic, financial). For the withdrawal *status* codes
#' (the status values themselves), see [selma_withdrawal_status_codes()].
#'
#' @inheritParams selma_students
#' @return A tibble of withdrawal reason codes.
#' @export
#' @examples
#' \dontrun{
#' selma_connect()
#' selma_withdrawal_reason_codes()
#'
#' # selma_withdrawal_codes() is an alias
#' selma_withdrawal_codes()
#' }
selma_withdrawal_reason_codes <- function(con = NULL, cache = FALSE,
                                          cache_dir = "selma_cache",
                                          cache_hours = 24,
                                          items_per_page = 100L,
                                          .progress = TRUE) {
  selma_fetch_entity(con, "withdrawal_reason_codes", "withdrawal_reason_codes",
                     cache = cache, cache_dir = cache_dir,
                     cache_hours = cache_hours,
                     items_per_page = items_per_page,
                     .progress = .progress)
}

#' @rdname selma_withdrawal_reason_codes
#' @export
selma_withdrawal_codes <- selma_withdrawal_reason_codes

#' Fetch withdrawal status codes from SELMA
#'
#' Retrieves the withdrawal *status* codes (distinct from the withdrawal
#' *reason* codes returned by [selma_withdrawal_reason_codes()]).
#'
#' @inheritParams selma_students
#' @return A tibble of withdrawal status codes.
#' @export
#' @examples
#' \dontrun{
#' selma_connect()
#' selma_withdrawal_status_codes()
#' }
selma_withdrawal_status_codes <- function(con = NULL, cache = FALSE,
                                          cache_dir = "selma_cache",
                                          cache_hours = 24,
                                          items_per_page = 100L,
                                          .progress = TRUE) {
  selma_fetch_entity(con, "withdrawal_codes", "withdrawal_status_codes",
                     cache = cache, cache_dir = cache_dir,
                     cache_hours = cache_hours,
                     items_per_page = items_per_page,
                     .progress = .progress)
}

#' Fetch enrolment status codes from SELMA
#'
#' Retrieves the live reference list of enrolment status codes from
#' the SELMA instance. For the package's built-in constants, see
#' [selma_status_codes].
#'
#' @inheritParams selma_students
#' @return A tibble of enrolment status codes.
#' @export
#' @examples
#' \dontrun{
#' selma_enr_status_codes(selma_connect())
#' }
selma_enr_status_codes <- function(con = NULL, cache = FALSE, cache_dir = "selma_cache",
                                   cache_hours = 24, items_per_page = 100L,
                                   .progress = TRUE) {
  selma_fetch_entity(con, "enr_status_codes", "enr_status_codes",
                     cache = cache, cache_dir = cache_dir,
                     cache_hours = cache_hours,
                     items_per_page = items_per_page,
                     .progress = .progress)
}

#' Fetch enrolments by campus from SELMA
#'
#' Retrieves a campus-grouped view of enrolments.
#'
#' @inheritParams selma_students
#' @return A tibble of enrolment-by-campus records.
#' @export
#' @examples
#' \dontrun{
#' selma_enrolments_by_campus(selma_connect())
#' }
selma_enrolments_by_campus <- function(con = NULL, cache = FALSE,
                                       cache_dir = "selma_cache",
                                       cache_hours = 24,
                                       items_per_page = 100L,
                                       .progress = TRUE) {
  selma_fetch_entity(con, "enr_by_campus", "enr_by_campus",
                     cache = cache, cache_dir = cache_dir,
                     cache_hours = cache_hours,
                     items_per_page = items_per_page,
                     .progress = .progress)
}

#' Fetch a single milestone from SELMA
#'
#' The SELMA API only supports fetching milestones by ID — there is no
#' collection (list-all) endpoint for milestones.
#'
#' @param milestone_id The milestone ID to fetch (required).
#' @param con A `selma_connection` object, or `NULL` to use the stored
#'   connection.
#' @return A single-row tibble of milestone fields.
#' @export
#' @examples
#' \dontrun{
#' selma_connect()
#' milestone <- selma_milestones("42")
#' }
selma_milestones <- function(milestone_id, con = NULL) {
  con <- selma_get_connection(con)
  url <- paste0(con$base_url, "app/milestones/", milestone_id)
  resp <- selma_request(con, url)
  resp[c("@context", "@id", "@type")] <- NULL
  resp <- lapply(resp, function(x) {
    if (is.null(x)) return(NA)
    if (is.list(x)) return(NA)
    x
  })
  result <- as_tibble(as.data.frame(resp, stringsAsFactors = FALSE))
  clean_names(result)
}

#' Fetch wish-to-study codes from SELMA
#'
#' @inheritParams selma_students
#' @return A tibble of wish-to-study codes.
#' @export
#' @examples
#' \dontrun{
#' selma_wish_to_studies(selma_connect())
#' }
selma_wish_to_studies <- function(con = NULL, cache = FALSE, cache_dir = "selma_cache",
                                  cache_hours = 24, items_per_page = 100L,
                                  .progress = TRUE) {
  selma_fetch_entity(con, "wish_to_studies", "wish_to_studies",
                     cache = cache, cache_dir = cache_dir,
                     cache_hours = cache_hours,
                     items_per_page = items_per_page,
                     .progress = .progress)
}
