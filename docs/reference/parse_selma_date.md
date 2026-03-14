# Parse SELMA date strings

SELMA returns ISO 8601 dates with NZ timezone offsets (e.g.
`"2023-07-31T00:00:00+12:00"`). The date portion is already NZ-local, so
this function extracts it directly via
[`substr()`](https://rdrr.io/r/base/substr.html) to avoid timezone
conversion bugs.

## Usage

``` r
parse_selma_date(x)
```

## Arguments

- x:

  Character vector of SELMA date strings.

## Value

A `Date` vector.

## Examples

``` r
parse_selma_date("2023-07-31T00:00:00+12:00")
#> [1] "2023-07-31"
parse_selma_date(c("2024-01-15T00:00:00+13:00", NA, "2024-06-01"))
#> [1] "2024-01-15" NA           "2024-06-01"
```
