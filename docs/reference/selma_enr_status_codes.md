# Fetch enrolment status codes from SELMA

Retrieves the live reference list of enrolment status codes from the
SELMA instance. For the package's built-in constants, see
[selma_status_codes](https://pcstrategyandopsco.github.io/selmaR/reference/selma_status_codes.md).

## Usage

``` r
selma_enr_status_codes(
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

A tibble of enrolment status codes.

## Examples

``` r
if (FALSE) { # \dontrun{
selma_enr_status_codes(selma_connect())
} # }
```
