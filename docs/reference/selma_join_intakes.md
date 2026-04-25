# Join enrolments with intake details

Convenience function that joins enrolments to intakes. Works on both v2
and v3 data — the join key is detected automatically from column names.

## Usage

``` r
selma_join_intakes(enrolments, intakes)
```

## Arguments

- enrolments:

  A tibble from
  [`selma_enrolments()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_enrolments.md).

- intakes:

  A tibble from
  [`selma_intakes()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_intakes.md).

## Value

A tibble with enrolment and intake columns joined.

## Examples

``` r
if (FALSE) { # \dontrun{
con <- selma_connect()
enrolments <- selma_enrolments(con)
intakes <- selma_intakes(con)
enrolment_intakes <- selma_join_intakes(enrolments, intakes)
} # }
```
