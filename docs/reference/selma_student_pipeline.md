# Build a complete student enrolment pipeline

Joins enrolments to both students and intakes in one step — the most
common starting point for SELMA analysis.

## Usage

``` r
selma_student_pipeline(enrolments, students, intakes)
```

## Arguments

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

A tibble combining enrolment, student, and intake data.

## Examples

``` r
if (FALSE) { # \dontrun{
con <- selma_connect()
pipeline <- selma_student_pipeline(
  selma_enrolments(con),
  selma_students(con),
  selma_intakes(con)
)

# Filter to funded students
active <- pipeline |>
  dplyr::filter(enrstatus %in% SELMA_FUNDED_STATUSES)
} # }
```
