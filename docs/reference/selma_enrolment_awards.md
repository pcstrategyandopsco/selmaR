# Fetch enrolment awards from SELMA

Retrieves award/qualification records linked to enrolments.

## Usage

``` r
selma_enrolment_awards(
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

A tibble of enrolment award records with columns including `award_id`,
`award_code`, `award_name`, `enrol_id`, `prog_id`, and `prog_type`.

## Examples

``` r
if (FALSE) { # \dontrun{
con <- selma_connect()
awards <- selma_enrolment_awards(con)
} # }
```
