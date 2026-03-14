# Join component attempts to enrolment components

Links assessment attempt records to their parent enrolment components.

## Usage

``` r
selma_join_attempts(attempts, components)
```

## Arguments

- attempts:

  A tibble from
  [`selma_component_attempts()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_component_attempts.md).

- components:

  A tibble from
  [`selma_components()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_components.md).

## Value

A tibble with attempt and component columns joined.

## Examples

``` r
if (FALSE) { # \dontrun{
con <- selma_connect()
attempt_details <- selma_join_attempts(
  selma_component_attempts(con), selma_components(con)
)
} # }
```
