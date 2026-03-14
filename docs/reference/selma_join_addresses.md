# Join addresses to students

Links address records to their associated students.

## Usage

``` r
selma_join_addresses(addresses, students)
```

## Arguments

- addresses:

  A tibble from
  [`selma_addresses()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_addresses.md).

- students:

  A tibble from
  [`selma_students()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_students.md).

## Value

A tibble with address and student columns joined.

## Examples

``` r
if (FALSE) { # \dontrun{
con <- selma_connect()
student_addresses <- selma_join_addresses(
  selma_addresses(con), selma_students(con)
)
} # }
```
