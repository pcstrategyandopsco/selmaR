# Fetch custom field values for all components in an enrolment

Retrieves custom field data for all enrolment components belonging to a
specific enrolment.

## Usage

``` r
selma_component_custom_fields(enrolment_id, con = NULL)
```

## Arguments

- enrolment_id:

  The enrolment ID (required).

- con:

  A `selma_connection` object, or `NULL` to use the stored connection.

## Value

A tibble of custom field values for the enrolment's components.

## Examples

``` r
if (FALSE) { # \dontrun{
selma_connect()
selma_component_custom_fields("456")
} # }
```
