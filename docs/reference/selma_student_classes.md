# Fetch student class assignments from SELMA

Retrieves which students are assigned to which classes.

## Usage

``` r
selma_student_classes(
  con = NULL,
  student_id = NULL,
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

A tibble of student-class records with columns including `student_id`,
`class`, `campus_id`, `start_date`, and `end_date`.

## Examples

``` r
if (FALSE) { # \dontrun{
selma_connect()
student_classes <- selma_student_classes()
student_classes <- selma_student_classes(student_id = "123")
} # }
```
