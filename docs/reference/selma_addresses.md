# Fetch addresses from SELMA

Retrieves address records linked to students, contacts, or
organisations.

## Usage

``` r
selma_addresses(
  con = NULL,
  student_id = NULL,
  contact_id = NULL,
  org_id = NULL,
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

- contact_id:

  Filter by contact ID.

- org_id:

  Filter by organisation ID.

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

A tibble of address records with columns including `addressid`,
`studentid`, `contactid`, `orgid`, `street`, `suburb`, `city`, `region`,
`postcode`, and `country`.

## Examples

``` r
if (FALSE) { # \dontrun{
selma_connect()
addresses <- selma_addresses()
addresses <- selma_addresses(student_id = "123")
} # }
```
