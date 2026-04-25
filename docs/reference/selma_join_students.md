# Join enrolments with student details

Convenience function that joins enrolments to students. Works on both v2
and v3 data — the join key is detected automatically from column names.

## Usage

``` r
selma_join_students(enrolments, students)
```

## Arguments

- enrolments:

  A tibble from
  [`selma_enrolments()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_enrolments.md).

- students:

  A tibble from
  [`selma_students()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_students.md).

## Value

A tibble with enrolment and student columns joined.

## Examples

``` r
if (FALSE) { # \dontrun{
con <- selma_connect()
enrolments <- selma_enrolments(con)
students <- selma_students(con)
student_enrolments <- selma_join_students(enrolments, students)
} # }
```
