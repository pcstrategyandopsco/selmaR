# Fetch enrolment records from SELMA

Retrieves all enrolment records linking students to intakes. Use the
`filter` argument to pass server-side query parameters sourced directly
from the SELMA OpenAPI spec. Valid parameter names for the active API
version are stored in `.selma_schemas[[version]]$enrolments$params`.

## Usage

``` r
selma_enrolments(
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
  `list("enrolment_status_date[after]" = "2026-01-01")`. Unknown names
  emit a warning and are dropped.

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

A tibble of enrolment records.

## Examples

``` r
if (FALSE) { # \dontrun{
selma_connect()

# All enrolments
enrolments <- selma_enrolments()

# Status changed yesterday (v3)
enrolments <- selma_enrolments(
  filter = list("enrolment_status_date[after]" = "2026-04-23")
)

# Filter by intake (v3)
enrolments <- selma_enrolments(filter = list(intake = "123"))
} # }
```
