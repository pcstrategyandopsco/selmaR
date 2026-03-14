# Fetch organisations from SELMA

Retrieves organisation records (employers, agents, partner
institutions).

## Usage

``` r
selma_organisations(
  con = NULL,
  org_id = NULL,
  name = NULL,
  third_party_id = NULL,
  registration_number = NULL,
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

- org_id:

  Filter by organisation ID.

- name:

  Filter by organisation name (exact match).

- third_party_id:

  Filter by third-party ID.

- registration_number:

  Filter by registration number.

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

A tibble of organisation records with columns including `id`, `name`,
`legalname`, `orgtype`, `email`, `phone`, and `country`.

## Examples

``` r
if (FALSE) { # \dontrun{
selma_connect()
orgs <- selma_organisations()
orgs <- selma_organisations(name = "Acme Ltd")
} # }
```
