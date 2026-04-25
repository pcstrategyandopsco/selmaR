# Fetch event records from SELMA (v3)

Retrieves event records from SELMA v3. Events are the v3 equivalent of
notes — they link activity records (comments, tasks, emails) to
students, enrolments, intakes, contacts, or organisations.

## Usage

``` r
selma_events(
  con = NULL,
  filter = list(),
  cache = FALSE,
  cache_dir = "selma_cache",
  cache_hours = 24,
  items_per_page = 100L,
  .progress = TRUE
)
```

## Arguments

- con:

  A `selma_connection` object from
  [`selma_connect()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_connect.md),
  or `NULL` (default) to use the stored connection.

- filter:

  Named list of API query parameters, e.g.
  `list(surname = "Smith", first_name = "Alice")` (v3) or
  `list(surname = "Smith", forename = "Alice")` (v2). Unknown names emit
  a warning and are dropped.

- cache:

  If `TRUE`, use RDS caching (default `FALSE`).

- cache_dir:

  Directory for cache files (default `"selma_cache"`).

- cache_hours:

  Hours before cache is considered stale (default 24).

- items_per_page:

  Items per API page (default 100).

- .progress:

  Show progress messages (default `TRUE`).

## Value

A tibble of event records with columns including `id`, `student`,
`enrolment`, `intake`, `event_type`, `event_subject`, `event_body`,
`event_priority`, `event_complete`, and `event_due_date`.

## Details

In v3, comments (notes) are attached to events rather than directly to
students. To get notes with student context, fetch both and use
[`selma_join_notes()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_join_notes.md):

    con <- selma_connect()
    notes  <- selma_notes(con)
    events <- selma_events(con)
    students <- selma_students(con)
    notes_with_students <- selma_join_notes(notes, students, events = events)

## Examples

``` r
if (FALSE) { # \dontrun{
con <- selma_connect()
events <- selma_events(con)
events <- selma_events(con, filter = list(student = "42"))
} # }
```
