# Join notes to students

Links notes/events to student records.

## Usage

``` r
selma_join_notes(notes, students)
```

## Arguments

- notes:

  A tibble from
  [`selma_notes()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_notes.md).

- students:

  A tibble from
  [`selma_students()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_students.md).

## Value

A tibble with note and student columns joined.

## Examples

``` r
if (FALSE) { # \dontrun{
con <- selma_connect()
notes_with_students <- selma_join_notes(
  selma_notes(con), selma_students(con)
)
} # }
```
