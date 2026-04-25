# Join components to enrolments

Links component-level data (individual course units) back to their
parent enrolments. Works on v2 and v3 data.

## Usage

``` r
selma_join_components(components, enrolments)
```

## Arguments

- components:

  A tibble from
  [`selma_components()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_components.md).

- enrolments:

  A tibble from
  [`selma_enrolments()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_enrolments.md).

## Value

A tibble with component and enrolment columns joined.

## Examples

``` r
if (FALSE) { # \dontrun{
con <- selma_connect()
components <- selma_components(con)
enrolments <- selma_enrolments(con)
component_details <- selma_join_components(components, enrolments)
} # }
```
