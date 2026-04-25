# Join intakes to programme details

Links intakes to their parent programme definitions. Works on v2 and v3
data.

## Usage

``` r
selma_join_programmes(intakes, programmes)
```

## Arguments

- intakes:

  A tibble from
  [`selma_intakes()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_intakes.md).

- programmes:

  A tibble from
  [`selma_programmes()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_programmes.md).

## Value

A tibble with intake and programme columns joined.

## Examples

``` r
if (FALSE) { # \dontrun{
con <- selma_connect()
intakes <- selma_intakes(con)
programmes <- selma_programmes(con)
intake_programmes <- selma_join_programmes(intakes, programmes)
} # }
```
