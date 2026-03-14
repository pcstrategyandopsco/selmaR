# Fetch programme definitions from SELMA

Retrieves programme (qualification) records.

## Usage

``` r
selma_programmes(
  con = NULL,
  status = NULL,
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

- status:

  Filter by programme status (e.g. `"Active"`, `"Inactive"`).

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

A tibble of programme records.

## Examples

``` r
if (FALSE) { # \dontrun{
selma_connect()
programmes <- selma_programmes()
programmes <- selma_programmes(status = "Active")
} # }
```
