# Fetch student records from SELMA

Retrieves student records with contact information. Returns a tibble
with `clean_names()` applied and IDs as character.

## Usage

``` r
selma_students(
  con = NULL,
  surname = NULL,
  forename = NULL,
  email1 = NULL,
  dob = NULL,
  third_party_id = NULL,
  third_party_id2 = NULL,
  organisation = NULL,
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

- surname:

  Filter by surname (exact match).

- forename:

  Filter by forename (exact match).

- email1:

  Filter by primary email (exact match).

- dob:

  Filter by date of birth (ISO date string, e.g. `"1990-01-15"`).

- third_party_id:

  Filter by ThirdPartyID.

- third_party_id2:

  Filter by ThirdPartyID2.

- organisation:

  Filter by organisation ID.

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

A tibble of student records.

## Examples

``` r
if (FALSE) { # \dontrun{
selma_connect()
students <- selma_students()
students <- selma_students(surname = "Smith")
students <- selma_students(cache = TRUE, cache_dir = "data")
} # }
```
