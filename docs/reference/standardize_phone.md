# Standardise a phone number to E.164 international format

Uses the
[dialvalidator](https://pcstrategyandopsco.github.io/dialvalidator/reference/dialvalidator-package.html)
package to parse and format phone numbers. For numbers without a country
code, tries each region in `default_regions` in order until a valid
parse is found. Numbers that cannot be parsed as valid in any region are
returned as `NA`.

## Usage

``` r
standardize_phone(phone, default_regions = c("NZ", "AU"))
```

## Arguments

- phone:

  A single phone number string.

- default_regions:

  Character vector of ISO 3166-1 alpha-2 region codes to try when the
  number lacks a country code (default `c("NZ", "AU")`). Tried in order;
  first valid match wins.

## Value

A standardised E.164 phone string (e.g. `"+64211234567"`), or
`NA_character_` if invalid.

## Examples

``` r
standardize_phone("021 123 4567")
#> [1] "+64211234567"
standardize_phone("+64211234567")
#> [1] "+64211234567"
standardize_phone("0412345678")
#> [1] "+61412345678"
```
