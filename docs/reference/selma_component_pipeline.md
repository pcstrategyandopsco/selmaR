# Build a full component pipeline

Joins components to enrolments, students, and intakes in one step. Works
on v2 and v3 data — join keys are detected automatically.

## Usage

``` r
selma_component_pipeline(components, enrolments, students, intakes)
```

## Arguments

- components:

  A tibble from
  [`selma_components()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_components.md).

- enrolments:

  A tibble from
  [`selma_enrolments()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_enrolments.md).

- students:

  A tibble from
  [`selma_students()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_students.md).

- intakes:

  A tibble from
  [`selma_intakes()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_intakes.md).

## Value

A tibble combining component, enrolment, student, and intake data.

## Examples

``` r
if (FALSE) { # \dontrun{
con <- selma_connect()
full_components <- selma_component_pipeline(
  selma_components(con),
  selma_enrolments(con),
  selma_students(con),
  selma_intakes(con)
)
} # }
```
