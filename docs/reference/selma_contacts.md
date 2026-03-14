# Fetch external contacts from SELMA

Retrieves contact records (agents, employers, emergency contacts, etc.).
These are external people linked to students, not student records
themselves.

## Usage

``` r
selma_contacts(
  con = NULL,
  other_id = NULL,
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

- other_id:

  Filter by the contact's other/external ID.

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

A tibble of contact records.

## Examples

``` r
if (FALSE) { # \dontrun{
selma_connect()
contacts <- selma_contacts()
} # }
```
