# Connect to the SELMA API

Authenticates with SELMA and stores the connection for the session. Once
connected, all `selma_*()` fetch functions use this connection
automatically — no need to pass it explicitly.

## Usage

``` r
selma_connect(
  base_url = NULL,
  email = NULL,
  password = NULL,
  config_file = "config.yml"
)
```

## Arguments

- base_url:

  SELMA base URL (e.g. `"https://myorg.selma.co.nz/"`).

- email:

  API login email.

- password:

  API login password.

- config_file:

  Path to a config YAML file (default `"config.yml"`). Set to `NULL` to
  skip config file lookup.

## Value

A `selma_connection` object (invisibly). The connection is also stored
in the package environment for automatic use by all fetch functions.

## Details

Credentials are resolved in order:

1.  **Direct arguments** — `base_url`, `email`, `password`

2.  **config.yml** — via the config package (`selma` key; see below)

3.  **Environment variables** — `SELMA_BASE_URL`, `SELMA_EMAIL`,
    `SELMA_PASSWORD`

## config.yml

Create a `config.yml` in your project root (add to `.gitignore`!):

    default:
      selma:
        base_url: "https://myorg.selma.co.nz/"
        email: "api@selma.co.nz"
        password: "secret"

## Examples

``` r
if (FALSE) { # \dontrun{
# Connect once — all functions use it automatically
selma_connect()
students <- selma_students()
enrolments <- selma_enrolments()

# Or pass credentials directly
selma_connect(
  base_url = "https://myorg.selma.co.nz/",
  email = "api@selma.co.nz",
  password = "secret"
)
} # }
```
