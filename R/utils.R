# Date parsing -------------------------------------------------------------

#' Parse SELMA date strings
#'
#' SELMA returns ISO 8601 dates with NZ timezone offsets (e.g.
#' `"2023-07-31T00:00:00+12:00"`). The date portion is already NZ-local, so
#' this function extracts it directly via `substr()` to avoid timezone
#' conversion bugs.
#'
#' @param x Character vector of SELMA date strings.
#' @return A `Date` vector.
#' @export
#' @examples
#' parse_selma_date("2023-07-31T00:00:00+12:00")
#' parse_selma_date(c("2024-01-15T00:00:00+13:00", NA, "2024-06-01"))
parse_selma_date <- function(x) {
  as.Date(substr(as.character(x), 1, 10))
}

# Phone normalisation ------------------------------------------------------

#' Standardise a phone number to E.164 international format
#'
#' Uses the [dialvalidator][dialvalidator::dialvalidator-package] package to
#' parse and format phone numbers. For numbers without a country code, tries
#' each region in `default_regions` in order until a valid parse is found.
#' Numbers that cannot be parsed as valid in any region are returned as `NA`.
#'
#' @param phone A single phone number string.
#' @param default_regions Character vector of ISO 3166-1 alpha-2 region codes
#'   to try when the number lacks a country code (default `c("NZ", "AU")`).
#'   Tried in order; first valid match wins.
#' @return A standardised E.164 phone string (e.g. `"+64211234567"`), or
#'   `NA_character_` if invalid.
#' @export
#' @examples
#' standardize_phone("021 123 4567")
#' standardize_phone("+64211234567")
#' standardize_phone("0412345678")
standardize_phone <- function(phone, default_regions = c("NZ", "AU")) {
  if (is.na(phone) || phone == "" || is.null(phone)) {
    return(NA_character_)
  }

  for (region in default_regions) {
    valid <- dialvalidator::phone_valid(phone, default_region = region)
    if (!is.na(valid) && valid) {
      formatted <- dialvalidator::phone_format(
        phone, format = "E164", default_region = region
      )
      if (!is.na(formatted)) return(formatted)
    }
  }

  NA_character_
}

#' Vectorised phone standardisation
#'
#' Applies [standardize_phone()] to each element of a character vector.
#'
#' @param phones Character vector of phone numbers.
#' @param default_regions Character vector of region codes to try
#'   (default `c("NZ", "AU")`).
#' @return Character vector of standardised E.164 phone numbers.
#' @export
#' @examples
#' standardize_phones(c("021 123 4567", "+61412345678", NA))
standardize_phones <- function(phones, default_regions = c("NZ", "AU")) {
  vapply(
    phones,
    standardize_phone,
    character(1),
    default_regions = default_regions,
    USE.NAMES = FALSE
  )
}

# URL builders -------------------------------------------------------------

#' Build a SELMA student URL
#'
#' @param id Student ID (character or numeric).
#' @param base_url SELMA base URL (e.g. `"https://myorg.selma.co.nz/"`).
#' @return A character URL string, or `NA` if `id` is `NA`.
#' @export
#' @examples
#' selma_student_url(123, "https://myorg.selma.co.nz/")
selma_student_url <- function(id, base_url) {
  ifelse(
    is.na(id),
    NA_character_,
    str_c(base_url, "en/admin/student/", as.character(id), "/1")
  )
}

#' Build a SELMA enrolment URL
#'
#' @param id Enrolment ID (character or numeric).
#' @param base_url SELMA base URL (e.g. `"https://myorg.selma.co.nz/"`).
#' @return A character URL string, or `NA` if `id` is `NA`.
#' @export
#' @examples
#' selma_enrolment_url(456, "https://myorg.selma.co.nz/")
selma_enrolment_url <- function(id, base_url) {
  ifelse(
    is.na(id),
    NA_character_,
    str_c(base_url, "en/admin/enrolment/", as.character(id), "/1")
  )
}
