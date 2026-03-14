# Fetch intake definitions from SELMA

Retrieves intake (cohort) records with dates and programme links.

## Usage

``` r
selma_intakes(
  con = NULL,
  prog_id = NULL,
  status = NULL,
  start_before = NULL,
  start_after = NULL,
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

- prog_id:

  Filter by programme ID.

- status:

  Filter by intake status (e.g. `"Open"`, `"Closed"`).

- start_before:

  Filter intakes starting before this date (ISO string).

- start_after:

  Filter intakes starting after this date (ISO string).

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

A tibble of intake records.

## Examples

``` r
if (FALSE) { # \dontrun{
selma_connect()
intakes <- selma_intakes()
intakes <- selma_intakes(prog_id = "42")
intakes <- selma_intakes(start_after = "2025-01-01")
} # }
```
