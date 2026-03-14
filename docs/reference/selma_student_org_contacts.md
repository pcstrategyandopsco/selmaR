# Fetch student-organisation-contact links from SELMA

Retrieves the organisation contacts linked to a specific student.

## Usage

``` r
selma_student_org_contacts(student_id, con = NULL)
```

## Arguments

- student_id:

  The student ID (required).

- con:

  A `selma_connection` object, or `NULL` to use the stored connection.

## Value

A tibble of student-org-contact records.

## Examples

``` r
if (FALSE) { # \dontrun{
selma_connect()
selma_student_org_contacts("123")
} # }
```
