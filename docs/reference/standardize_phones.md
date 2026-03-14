# Vectorised phone standardisation

Applies
[`standardize_phone()`](https://pcstrategyandopsco.github.io/selmaR/reference/standardize_phone.md)
to each element of a character vector.

## Usage

``` r
standardize_phones(phones, default_regions = c("NZ", "AU"))
```

## Arguments

- phones:

  Character vector of phone numbers.

- default_regions:

  Character vector of region codes to try (default `c("NZ", "AU")`).

## Value

Character vector of standardised E.164 phone numbers.

## Examples

``` r
standardize_phones(c("021 123 4567", "+61412345678", NA))
#> [1] "+64211234567" "+61412345678" NA            
```
