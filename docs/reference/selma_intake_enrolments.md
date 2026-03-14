# Fetch intake enrolments with nested components

Retrieves enrolments for a specific intake including nested student and
component details. Unlike other endpoints, this returns non-paginated
nested JSON that is flattened into a tibble.

## Usage

``` r
selma_intake_enrolments(con = NULL, intake_id, .progress = TRUE)
```

## Arguments

- con:

  A `selma_connection` object from
  [`selma_connect()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_connect.md),
  or `NULL` (default) to use the stored connection.

- intake_id:

  Integer intake ID to fetch enrolments for.

- .progress:

  Show progress messages (default `TRUE`).

## Value

A tibble of flattened intake enrolment records.

## Examples

``` r
if (FALSE) { # \dontrun{
selma_connect()
ie <- selma_intake_enrolments(intake_id = 123)
} # }
```
