# Fetch notes and events from SELMA

Retrieves notes and event records linked to students and enrolments.
Notes include pastoral care records, meeting notes, and other
student-related documentation.

## Usage

``` r
selma_notes(
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

A tibble of note/event records with columns including `noteid`,
`student_id`, `enrolmentid`, `notetype`, `notearea`, `note1`, and
`confidential`.

## Examples

``` r
if (FALSE) { # \dontrun{
con <- selma_connect()
notes <- selma_notes(con)

# Notes for a specific student
student_notes <- notes |>
  dplyr::filter(student_id == "123")
} # }
```
