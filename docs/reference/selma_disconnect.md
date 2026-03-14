# Disconnect from the SELMA API

Clears the stored connection. Subsequent fetch calls will require a new
[`selma_connect()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_connect.md).

## Usage

``` r
selma_disconnect()
```

## Examples

``` r
if (FALSE) { # \dontrun{
selma_connect()
selma_disconnect()
} # }
```
