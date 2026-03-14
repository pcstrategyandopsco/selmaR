# Fetch student-contact links from SELMA

Retrieves the relationships between students and their contacts,
including emergency contact and primary contact flags.

## Usage

``` r
selma_student_contacts(
  con = NULL,
  student_id = NULL,
  contact_id = NULL,
  relationship = NULL,
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

- student_id:

  Filter by student ID.

- contact_id:

  Filter by contact ID.

- relationship:

  Filter by relationship type.

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

A tibble with columns including `studentid`, `contactid`, `isemergency`,
`isprimary`, and `relationship`.

## Examples

``` r
if (FALSE) { # \dontrun{
selma_connect()
student_contacts <- selma_student_contacts()
student_contacts <- selma_student_contacts(student_id = "123")
} # }
```
