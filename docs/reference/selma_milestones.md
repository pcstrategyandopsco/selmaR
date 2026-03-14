# Fetch a single milestone from SELMA

The SELMA API only supports fetching milestones by ID — there is no
collection (list-all) endpoint for milestones.

## Usage

``` r
selma_milestones(milestone_id, con = NULL)
```

## Arguments

- milestone_id:

  The milestone ID to fetch (required).

- con:

  A `selma_connection` object, or `NULL` to use the stored connection.

## Value

A single-row tibble of milestone fields.

## Examples

``` r
if (FALSE) { # \dontrun{
selma_connect()
milestone <- selma_milestones("42")
} # }
```
