# Fetch class definitions from SELMA

Retrieves timetable class records with capacity and date information.

## Usage

``` r
selma_classes(
  con = NULL,
  class_name = NULL,
  campus_id = NULL,
  enrstatus = NULL,
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

- class_name:

  Filter by class name (exact match).

- campus_id:

  Filter by campus ID.

- enrstatus:

  Filter by enrolment status.

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

A tibble of class records with columns including `id`, `class_name`,
`capacity`, `startdate`, `enddate`, `campusid`, and `enrolment_count`.

## Examples

``` r
if (FALSE) { # \dontrun{
selma_connect()
classes <- selma_classes()
classes <- selma_classes(campus_id = "1")
} # }
```
