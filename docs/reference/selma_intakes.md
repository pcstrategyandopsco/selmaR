# Fetch intake definitions from SELMA

Retrieves intake (cohort) records with dates and programme links.

## Usage

``` r
selma_intakes(
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

A tibble of intake records.

## Details

Use the `filter` argument to pass server-side query parameters sourced
directly from the SELMA OpenAPI spec. Valid parameter names for the
active API version are stored in
`.selma_schemas[[version]]$intakes$params`.

## Examples

``` r
if (FALSE) { # \dontrun{
selma_connect()
intakes <- selma_intakes()
intakes <- selma_intakes(filter = list("start_date[after]" = "2025-01-01"))
} # }
```
