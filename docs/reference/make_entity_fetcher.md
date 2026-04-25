# Create a fetch function for any SELMA endpoint

Returns a function that fetches, paginates, and standardises any SELMA
collection endpoint. Use this to query endpoints not yet covered by a
named function in the package — the SELMA API has over 200 collection
endpoints and selmaR does not wrap all of them.

## Usage

``` r
make_entity_fetcher(entity)
```

## Arguments

- entity:

  API endpoint path segment (v3 canonical name), e.g. `"events"`,
  `"placements"`, `"documents"`. Consult the SELMA v3 OpenAPI spec for
  the full list. For v2 connections the endpoint is resolved via the
  version alias table automatically.

## Value

A function with signature:\
`function(con = NULL, filter = list(), cache = FALSE,`\
` cache_dir = "selma_cache", cache_hours = 24,`\
` items_per_page = 100L, .progress = TRUE)`

## Details

The returned function validates `filter` parameter names against the
schema registry for the connected API version (sourced from the OpenAPI
specs at build time). Unknown parameters emit a `cli_warn()` and are
dropped rather than being sent to the API silently.

For a one-off query without creating a named function, use
[`selma_get()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_get.md)
directly.

## Examples

``` r
if (FALSE) { # \dontrun{
con <- selma_connect()

# Create a reusable function for an endpoint not yet in the package:
selma_events     <- make_entity_fetcher("events")
selma_placements <- make_entity_fetcher("placements")

events     <- selma_events(con)
placements <- selma_placements(con, filter = list(placement_status = "active"))

# For a one-off query, use selma_get() directly:
documents <- selma_get(con, "documents")
visas     <- selma_get(con, "visas")
} # }
```
