# Fetch a single record from a SELMA API endpoint

Retrieves a single record by ID from any SELMA endpoint. Most SELMA
endpoints support `GET /app/{endpoint}/{id}` for single-record access.

## Usage

``` r
selma_get_one(endpoint, id, con = NULL)
```

## Arguments

- endpoint:

  API endpoint path (e.g. `"students"`, `"enrolments"`).

- id:

  The record ID to fetch.

- con:

  A `selma_connection` object, or `NULL` to use the stored connection.

## Value

A single-row tibble with `clean_names()` applied.

## Examples

``` r
if (FALSE) { # \dontrun{
selma_connect()
student <- selma_get_one("students", "123")
enrolment <- selma_get_one("enrolments", "456")
} # }
```
