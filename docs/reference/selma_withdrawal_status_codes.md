# Fetch withdrawal status codes from SELMA

Retrieves the withdrawal *status* codes (distinct from the withdrawal
*reason* codes returned by
[`selma_withdrawal_reason_codes()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_withdrawal_reason_codes.md)).

## Usage

``` r
selma_withdrawal_status_codes(
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

A tibble of withdrawal status codes.

## Examples

``` r
if (FALSE) { # \dontrun{
selma_connect()
selma_withdrawal_status_codes()
} # }
```
