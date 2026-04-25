# Join component attempts (or grades) to enrolment components

Links assessment attempt records to their parent enrolment components.
Works on both v2 and v3 data:

## Usage

``` r
selma_join_attempts(attempts, components)
```

## Arguments

- attempts:

  A tibble from
  [`selma_component_attempts()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_component_attempts.md)
  (v2) or
  [`selma_component_grades()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_component_grades.md)
  (v3).

- components:

  A tibble from
  [`selma_components()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_components.md).

## Value

A tibble with attempt/grade and component columns joined.

## Details

- **v2**: pass a tibble from
  [`selma_component_attempts()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_component_attempts.md)
  — joined via the shared `compenrid` key.

- **v3**: pass a tibble from
  [`selma_component_grades()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_component_grades.md)
  — joined via the `enrolment_component` IRI-reference column.

## Examples

``` r
if (FALSE) { # \dontrun{
con <- selma_connect()

# v2
selma_join_attempts(selma_component_attempts(con), selma_components(con))

# v3
selma_join_attempts(selma_component_grades(con), selma_components(con))
} # }
```
