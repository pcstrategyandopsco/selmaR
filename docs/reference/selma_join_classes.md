# Join classes to campuses

Links class records to their campus locations. Works on v2 and v3 data.

## Usage

``` r
selma_join_classes(classes, campuses)
```

## Arguments

- classes:

  A tibble from
  [`selma_classes()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_classes.md).

- campuses:

  A tibble from
  [`selma_campuses()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_campuses.md).

## Value

A tibble with class and campus columns joined.

## Examples

``` r
if (FALSE) { # \dontrun{
con <- selma_connect()
class_campuses <- selma_join_classes(
  selma_classes(con), selma_campuses(con)
)
} # }
```
