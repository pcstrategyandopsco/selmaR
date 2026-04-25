# Join notes to students

Links note records to student records. Works on both v2 and v3 data:

## Usage

``` r
selma_join_notes(notes, students, events = NULL)
```

## Arguments

- notes:

  A tibble from
  [`selma_notes()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_notes.md).

- students:

  A tibble from
  [`selma_students()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_students.md).

- events:

  A tibble from
  [`selma_events()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_events.md)
  (required for v3 data, ignored on v2).

## Value

A tibble with note and student columns joined.

## Details

- **v2**: notes have a direct `student_id` foreign key — joined in one
  step.

- **v3**: notes (comments) link to students via events. Pass the events
  tibble from
  [`selma_events()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_events.md)
  via the `events` argument to enable the two-step join: comments →
  events → students.

## Examples

``` r
if (FALSE) { # \dontrun{
con <- selma_connect()

# v2
selma_join_notes(selma_notes(con), selma_students(con))

# v3
selma_join_notes(
  selma_notes(con),
  selma_students(con),
  events = selma_events(con)
)
} # }
```
