# Fetch withdrawal reason codes from SELMA

Retrieves reason codes that explain *why* a student was withdrawn (e.g.
personal, academic, financial). For the withdrawal *status* codes (the
status values themselves), see
[`selma_withdrawal_status_codes()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_withdrawal_status_codes.md).

## Usage

``` r
selma_withdrawal_reason_codes(
  con = NULL,
  cache = FALSE,
  cache_dir = "selma_cache",
  cache_hours = 24,
  items_per_page = 100L,
  .progress = TRUE
)

selma_withdrawal_codes(
  con = NULL,
  cache = FALSE,
  cache_dir = "selma_cache",
  cache_hours = 24,
  items_per_page = 100L,
  .progress = TRUE
)
```

## Arguments

- con:

  A `selma_connection` object from
  [`selma_connect()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_connect.md),
  or `NULL` (default) to use the stored connection.

- cache:

  If `TRUE`, use RDS caching (default `FALSE`).

- cache_dir:

  Directory for cache files (default `"selma_cache"`).

- cache_hours:

  Hours before cache is considered stale (default 24).

- items_per_page:

  Items per API page (default 100).

- .progress:

  Show progress messages (default `TRUE`).

## Value

A tibble of withdrawal reason codes.

## Examples

``` r
if (FALSE) { # \dontrun{
selma_connect()
selma_withdrawal_reason_codes()

# selma_withdrawal_codes() is an alias
selma_withdrawal_codes()
} # }
```
