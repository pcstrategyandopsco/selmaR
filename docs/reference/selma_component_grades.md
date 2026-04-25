# Fetch component grade/attempt records from SELMA (v3)

Retrieves `enrolment_component_grades` records — the v3 equivalent of
[`selma_component_attempts()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_component_attempts.md).
Each record captures one assessment attempt against an enrolment
component, including the attempt date, note, numerical value, and
grading scheme grade.

## Usage

``` r
selma_component_grades(
  con = NULL,
  filter = list(),
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

- filter:

  Named list of API query parameters, e.g.
  `list(surname = "Smith", first_name = "Alice")` (v3) or
  `list(surname = "Smith", forename = "Alice")` (v2). Unknown names emit
  a warning and are dropped.

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

A tibble of enrolment component grade records.

## Details

The `enrolment_component` column contains the IRI-stripped ID of the
parent
[`selma_components()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_components.md)
record. Use
[`selma_join_attempts()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_join_attempts.md)
to join grades back to their parent components.

## Examples

``` r
if (FALSE) { # \dontrun{
con <- selma_connect()
grades <- selma_component_grades(con)
grades <- selma_component_grades(con, filter = list(enrolment_component = "789"))
} # }
```
