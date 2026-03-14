# Fetch component definitions from SELMA

Retrieves component (unit standard/course) definitions — the master list
of components available across programmes. This is different from
[`selma_components()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_components.md)
which returns *enrolment* components (instances of components attached
to student enrolments).

## Usage

``` r
selma_component_definitions(
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

A tibble of component definitions with columns including `compid`,
`compcode`, `comptitle`, `compefts`, `comptype`, `compcrediteq`, and
`complevelfw`.

## Examples

``` r
if (FALSE) { # \dontrun{
con <- selma_connect()
comp_defs <- selma_component_definitions(con)
} # }
```
