# Fetch custom field values for a student

Retrieves the custom field data stored against a specific student.

## Usage

``` r
selma_student_custom_fields(student_id, con = NULL)
```

## Arguments

- student_id:

  The student ID (required).

- con:

  A `selma_connection` object, or `NULL` to use the stored connection.

## Value

A tibble of custom field values for the student.

## Examples

``` r
if (FALSE) { # \dontrun{
selma_connect()
selma_student_custom_fields("123")
} # }
```
