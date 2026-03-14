# EFTS Pro-Rata Reporting

## Overview

EFTS (Equivalent Full-Time Student) is the standard funding metric for
tertiary education in New Zealand. selmaR includes
[`selma_efts_report()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_efts_report.md)
to pro-rate each component’s EFTS across calendar months — replicating
SELMA’s built-in funding report.

## How Pro-Rata Calculation Works

For each component:

1.  Calculate `total_days` = end_date - start_date + 1
2.  For each calendar month, calculate the overlap days between the
    component’s date range and the month
3.  Monthly EFTS = (overlap_days / total_days) \* component_efts

This distributes a component’s EFTS across months proportionally to how
much of its duration falls within each month.

## Usage

``` r

library(selmaR)

con <- selma_connect()
components <- selma_components(con)

# Single year
report_2025 <- selma_efts_report(components, year = 2025)
```

The result contains:

| Column               | Description                                        |
|----------------------|----------------------------------------------------|
| `funding_source`     | Funding source label (e.g. “01 Government Funded”) |
| `category`           | Funding category from SELMA                        |
| `efts_01`..`efts_12` | Pro-rata EFTS for Jan through Dec                  |
| `total`              | Row total                                          |

## Filtering

By default,
[`selma_efts_report()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_efts_report.md):

- Includes statuses: C, FC, FI, WR, WS (all funded)
- **Excludes** international fee-paying (source “02”)
- **Excludes** cross-credited enrolments (components summing to zero
  EFTS)

Customise these:

``` r

# Only confirmed and completed
report <- selma_efts_report(
  components,
  year = 2025,
  funded_statuses = c("C", "FC")
)

# Include international students
report <- selma_efts_report(
  components,
  year = 2025,
  exclude_international = FALSE
)
```

## Funding Source Codes

| Code | Label                         |
|------|-------------------------------|
| 01   | Government Funded             |
| 02   | International Fee-Paying      |
| 29   | MPTT Level 3 and 4            |
| 31   | Youth Guarantee               |
| 37   | Non-degree L3-7 NZQCF (DQ3-7) |

These are available as package constants: `SELMA_FUNDING_GOVT`,
`SELMA_FUNDING_INTL`, etc.
