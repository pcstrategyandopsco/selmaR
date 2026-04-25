#' Generate EFTS funding report
#'
#' Pro-rates each component's EFTS across calendar months based on the
#' proportion of its duration falling within each month. Useful for any NZ
#' TEO that needs to replicate SELMA's funding report.
#'
#' @param components A tibble of enrolment components (from
#'   [selma_components()]). Must contain columns: `compenrstartdate`,
#'   `compenrenddate`, `compenrefts`, `compenrstatus`, `compenrsource`,
#'   `compenrfundingcategory`, `enrolid`.
#' @param year Calendar year to report on (default: current year).
#' @param funded_statuses Character vector of component status codes to
#'   include (default: `SELMA_ALL_FUNDED_STATUSES`).
#' @param exclude_international If `TRUE` (default), excludes international
#'   fee-paying components (funding source `"02"`).
#' @return A tibble with columns `funding_source`, `category`,
#'   `efts_01`..`efts_12`, and `total`.
#' @export
#' @examples
#' \dontrun{
#' con <- selma_connect()
#' components <- selma_components(con)
#' report <- selma_efts_report(components, year = 2025)
#' }
selma_efts_report <- function(components,
                              year = as.integer(format(Sys.Date(), "%Y")),
                              funded_statuses = SELMA_ALL_FUNDED_STATUSES,
                              exclude_international = TRUE) {

  year_start <- as.Date(str_c(year, "-01-01"))
  year_end <- as.Date(str_c(year, "-12-31"))

  df <- components |>
    mutate(
      start_date = parse_selma_date(.data$compenrstartdate),
      end_date = parse_selma_date(.data$compenrenddate),
      efts = as.numeric(.data$compenrefts)
    ) |>
    filter(
      .data$compenrstatus %in% .env$funded_statuses,
      !is.na(.data$start_date),
      !is.na(.data$end_date),
      !is.na(.data$efts),
      .data$start_date <= .env$year_end,
      .data$end_date >= .env$year_start
    )

  if (exclude_international) {
    df <- filter(df, .data$compenrsource != SELMA_FUNDING_INTL)
  }

  # Exclude cross-credited enrolments (all funded components sum to zero EFTS)
  df <- df |>
    group_by(.data$enrolid) |>
    mutate(enrol_total_efts = sum(.data$efts, na.rm = TRUE)) |>
    ungroup() |>
    filter(.data$enrol_total_efts > 0) |>
    select(-"enrol_total_efts") |>
    mutate(total_days = as.numeric(.data$end_date - .data$start_date) + 1) |>
    filter(.data$total_days > 0)

  # Calculate monthly EFTS
  months <- 1:12
  month_cols <- str_c("efts_", sprintf("%02d", months))

  for (m in months) {
    month_start <- as.Date(str_c(year, "-", sprintf("%02d", m), "-01"))
    month_end <- ceiling_date(month_start, "month") - days(1)
    col_name <- month_cols[m]

    df <- df |>
      mutate(
        overlap_start = pmax(.data$start_date, .env$month_start),
        overlap_end = pmin(.data$end_date, .env$month_end),
        overlap_days = pmax(as.numeric(.data$overlap_end - .data$overlap_start) + 1, 0),
        !!col_name := round((.data$overlap_days / .data$total_days) * .data$efts, 4)
      )
  }

  # Summarise by funding source and category
  result <- df |>
    group_by(
      funding_source = .data$compenrsource,
      category = .data$compenrfundingcategory
    ) |>
    summarise(
      across(all_of(month_cols), \(x) round(sum(x, na.rm = TRUE), 3)),
      .groups = "drop"
    ) |>
    mutate(
      funding_source = if_else(
        .data$funding_source %in% names(SELMA_FUNDING_LABELS),
        SELMA_FUNDING_LABELS[.data$funding_source],
        .data$funding_source
      ),
      total = rowSums(across(all_of(month_cols)), na.rm = TRUE) |> round(3)
    ) |>
    arrange(.data$funding_source, .data$category)

  cli_alert_success(
    "EFTS report for {year}: {nrow(result)} rows, {round(sum(result$total), 3)} total EFTS"
  )

  result
}
