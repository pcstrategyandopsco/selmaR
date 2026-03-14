# Generate EFTS funding report

Pro-rates each component's EFTS across calendar months based on the
proportion of its duration falling within each month. Useful for any NZ
TEO that needs to replicate SELMA's funding report.

## Usage

``` r
selma_efts_report(
  components,
  year = as.integer(format(Sys.Date(), "%Y")),
  funded_statuses = SELMA_ALL_FUNDED_STATUSES,
  exclude_international = TRUE
)
```

## Arguments

- components:

  A tibble of enrolment components (from
  [`selma_components()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_components.md)).
  Must contain columns: `compenrstartdate`, `compenrenddate`,
  `compenrefts`, `compenrstatus`, `compenrsource`,
  `compenrfundingcategory`, `enrolid`.

- year:

  Calendar year to report on (default: current year).

- funded_statuses:

  Character vector of component status codes to include (default:
  `SELMA_ALL_FUNDED_STATUSES`).

- exclude_international:

  If `TRUE` (default), excludes international fee-paying components
  (funding source `"02"`).

## Value

A tibble with columns `funding_source`, `category`,
`efts_01`..`efts_12`, and `total`.

## Examples

``` r
if (FALSE) { # \dontrun{
con <- selma_connect()
components <- selma_components(con)
report <- selma_efts_report(components, year = 2025)
} # }
```
