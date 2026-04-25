# Fetch component assessment attempts from SELMA (v2 only)

Retrieves individual assessment attempt records for enrolment
components. This endpoint exists in SELMA v2 only. For v3, use
[`selma_component_grades()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_component_grades.md).

## Usage

``` r
selma_component_attempts(
  con = NULL,
  compenrid = NULL,
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

- compenrid:

  Filter by enrolment component ID (v2 only).

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

A tibble of component attempt records.

## Examples

``` r
if (FALSE) { # \dontrun{
selma_connect()
attempts <- selma_component_attempts()
attempts <- selma_component_attempts(compenrid = "789")
} # }
```
