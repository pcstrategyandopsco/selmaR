# Fetch campus locations from SELMA

Retrieves campus/site records with location and contact details.

## Usage

``` r
selma_campuses(
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

A tibble of campus records with columns including `id`, `short_name`,
`site_code`, `city`, `country`, and `campus_manager`.

## Examples

``` r
if (FALSE) { # \dontrun{
con <- selma_connect()
campuses <- selma_campuses(con)
} # }
```
