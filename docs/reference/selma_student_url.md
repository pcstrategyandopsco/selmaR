# Build a SELMA student URL

Build a SELMA student URL

## Usage

``` r
selma_student_url(id, base_url)
```

## Arguments

- id:

  Student ID (character or numeric).

- base_url:

  SELMA base URL (e.g. `"https://myorg.selma.co.nz/"`).

## Value

A character URL string, or `NA` if `id` is `NA`.

## Examples

``` r
selma_student_url(123, "https://myorg.selma.co.nz/")
#> [1] "https://myorg.selma.co.nz/en/admin/student/123/1"
```
