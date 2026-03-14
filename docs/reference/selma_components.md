# Fetch enrolment components from SELMA

Retrieves component-level data (individual course units within a
programme). This is typically the largest dataset.

## Usage

``` r
selma_components(
  con = NULL,
  student_id = NULL,
  enrol_id = NULL,
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

- student_id:

  Filter by student ID.

- enrol_id:

  Filter by enrolment ID.

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

A tibble of enrolment component records.

## Examples

``` r
if (FALSE) { # \dontrun{
selma_connect()
components <- selma_components()
components <- selma_components(student_id = "123")
components <- selma_components(enrol_id = "456")
} # }
```
