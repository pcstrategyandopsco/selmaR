# Fetch marketing sources from SELMA

Retrieves the reference list of marketing/lead sources used to track how
students discovered the organisation.

## Usage

``` r
selma_marketing_sources(
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

A tibble of marketing source records with columns including `id`,
`code`, `name`, and `active`.

## Examples

``` r
if (FALSE) { # \dontrun{
con <- selma_connect()
sources <- selma_marketing_sources(con)
} # }
```
