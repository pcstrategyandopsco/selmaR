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
  api_version = NULL,
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

- api_version:

  SELMA API version: `"v2"`, `"v3"`, or `NULL` (default) to auto-detect.
  A SELMA instance runs one version — the value is stored on the
  connection object and used for all subsequent requests.

- config_file:

  Path to a config YAML file (default `"config.yml"`). Set to `NULL` to
  skip config file lookup.

## Value

A `selma_connection` object (invisibly). The connection is also stored
in the package environment for automatic use by all fetch functions.

## Details

Credentials are resolved in order:

1.  **Direct arguments** — `base_url`, `email`, `password`

2.  **config.yml** — version-specific block (`selma.v2` or `selma.v3`)
    if `api_version` is set, then flat `selma` block as fallback

3.  **Environment variables** — version-specific (`SELMA_V3_EMAIL` etc.)
    then generic (`SELMA_EMAIL` etc.)

## config.yml

Create a `config.yml` in your project root (add to `.gitignore`!).

**Single version** (flat structure, backward-compatible):

    default:
      selma:
        base_url: "https://myorg.selma.co.nz/"
        email: "api@selma.co.nz"
        password: "secret"

**Dual version** (v2 and v3 credentials stored separately):

    default:
      selma:
        v2:
          base_url: "https://myorg.selma.co.nz/"
          email: "v2_api@selma.co.nz"
          password: "v2secret"
        v3:
          base_url: "https://myorg.selma.app/"
          email: "v3_api@selma.app"
          password: "v3secret"

When `api_version = "v3"` is set (or auto-detected), selmaR reads
`selma.v3.email` / `selma.v3.password` first, falling back to the flat
`selma.email` / `selma.password` if not present.

## Examples

``` r
if (FALSE) { # \dontrun{
# Connect once — all functions use it automatically (api_version auto-detected)
selma_connect()
students <- selma_students()
enrolments <- selma_enrolments()

# Specify API version explicitly
selma_connect(
  base_url = "https://myorg.selma.co.nz/",
  email = "api@selma.co.nz",
  password = "secret",
  api_version = "v3"
)
} # }
```
