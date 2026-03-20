# Get the active SELMA connection

Returns the stored connection, or errors with a helpful message if no
connection exists. Used internally by all fetch functions and the MCP
server.

## Usage

``` r
selma_get_connection(con = NULL)
```

## Arguments

- con:

  Optional explicit connection. If `NULL`, uses the stored connection
  from
  [`selma_connect()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_connect.md).

## Value

A `selma_connection` object.
