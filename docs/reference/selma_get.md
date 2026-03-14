# Fetch data from a SELMA API endpoint

Generic paginated fetcher that handles Hydra JSON-LD pagination. For
most use cases, prefer the entity-specific functions like
[`selma_students()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_students.md)
or
[`selma_enrolments()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_enrolments.md).

## Usage

``` r
selma_get(
  con = NULL,
  endpoint,
  query_params = NULL,
  items_per_page = 30L,
  max_pages = Inf,
  .progress = TRUE
)
```

## Arguments

- con:

  A `selma_connection` object from
  [`selma_connect()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_connect.md),
  or `NULL` to use the connection stored by
  [`selma_connect()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_connect.md).

- endpoint:

  API endpoint path (e.g. `"students"`, `"enrolments"`).

- query_params:

  Named list of additional query parameters.

- items_per_page:

  Number of items per page (default 30).

- max_pages:

  Maximum pages to fetch (default `Inf` for all).

- .progress:

  Show progress messages via cli (default `TRUE`).

## Value

A tibble of results with `clean_names()` applied.

## Examples

``` r
if (FALSE) { # \dontrun{
selma_connect()
students <- selma_get(endpoint = "students", items_per_page = 100)
} # }
```
