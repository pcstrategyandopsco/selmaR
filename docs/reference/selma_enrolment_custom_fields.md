# Fetch custom field values for an enrolment

Retrieves the custom field data stored against a specific enrolment.

## Usage

``` r
selma_enrolment_custom_fields(enrolment_id, con = NULL)
```

## Arguments

- enrolment_id:

  The enrolment ID (required).

- con:

  A `selma_connection` object, or `NULL` to use the stored connection.

## Value

A tibble of custom field values for the enrolment.

## Examples

``` r
if (FALSE) { # \dontrun{
selma_connect()
selma_enrolment_custom_fields("456")
} # }
```
