# Build a SELMA enrolment URL

Build a SELMA enrolment URL

## Usage

``` r
selma_enrolment_url(id, base_url)
```

## Arguments

- id:

  Enrolment ID (character or numeric).

- base_url:

  SELMA base URL (e.g. `"https://myorg.selma.co.nz/"`).

## Value

A character URL string, or `NA` if `id` is `NA`.

## Examples

``` r
selma_enrolment_url(456, "https://myorg.selma.co.nz/")
#> [1] "https://myorg.selma.co.nz/en/admin/enrolment/456/1"
```
