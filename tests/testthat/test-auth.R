test_that("selma_connect requires base_url", {
  withr::local_envvar(SELMA_BASE_URL = "", SELMA_EMAIL = "a", SELMA_PASSWORD = "b")
  expect_error(selma_connect(config_file = NULL), "base_url")
})

test_that("selma_connect requires email", {
  withr::local_envvar(SELMA_BASE_URL = "https://x.selma.co.nz/", SELMA_EMAIL = "", SELMA_PASSWORD = "b")
  expect_error(selma_connect(config_file = NULL), "email")
})

test_that("selma_connect requires password", {
  withr::local_envvar(SELMA_BASE_URL = "https://x.selma.co.nz/", SELMA_EMAIL = "a", SELMA_PASSWORD = "")
  expect_error(selma_connect(config_file = NULL), "password")
})

test_that("selma_resolve_config prefers direct args", {
  withr::local_envvar(SELMA_BASE_URL = "https://env.selma.co.nz/")
  cfg <- selmaR:::selma_resolve_config(
    base_url = "https://arg.selma.co.nz/",
    email = "arg@test.com",
    password = "argpass",
    config_file = NULL
  )
  expect_equal(cfg$base_url, "https://arg.selma.co.nz/")
  expect_equal(cfg$email, "arg@test.com")
})

test_that("selma_resolve_config falls back to env vars", {
  withr::local_envvar(
    SELMA_BASE_URL = "https://env.selma.co.nz/",
    SELMA_EMAIL = "env@test.com",
    SELMA_PASSWORD = "envpass"
  )
  cfg <- selmaR:::selma_resolve_config(NULL, NULL, NULL, config_file = NULL)
  expect_equal(cfg$base_url, "https://env.selma.co.nz/")
  expect_equal(cfg$email, "env@test.com")
  expect_equal(cfg$password, "envpass")
})

test_that("selma_resolve_config reads config.yml", {
  tmp <- withr::local_tempfile(fileext = ".yml")
  writeLines(c(
    "default:",
    "  selma:",
    '    base_url: "https://cfg.selma.co.nz/"',
    '    email: "cfg@test.com"',
    '    password: "cfgpass"'
  ), tmp)

  withr::local_envvar(SELMA_BASE_URL = "", SELMA_EMAIL = "", SELMA_PASSWORD = "")
  cfg <- selmaR:::selma_resolve_config(NULL, NULL, NULL, config_file = tmp)
  expect_equal(cfg$base_url, "https://cfg.selma.co.nz/")
  expect_equal(cfg$email, "cfg@test.com")
  expect_equal(cfg$password, "cfgpass")
})

test_that("print.selma_connection works", {
  con <- structure(
    list(base_url = "https://test.selma.co.nz/", token = "Bearer eyJhbGciOiJSUzI1NiJ9.test"),
    class = "selma_connection"
  )
  expect_output(print(con), "selma_connection")
  expect_output(print(con), "test.selma.co.nz")
})

# Connection storage -------------------------------------------------------

test_that("selma_get_connection returns explicit con when provided", {
  con <- structure(
    list(base_url = "https://x.selma.co.nz/", token = "Bearer abc"),
    class = "selma_connection"
  )
  result <- selmaR:::selma_get_connection(con)
  expect_identical(result, con)
})

test_that("selma_get_connection errors when no connection stored", {
  # Clear any stored connection
  env <- getFromNamespace("selma_env", "selmaR")
  old <- env$connection
  env$connection <- NULL
  expect_error(getFromNamespace("selma_get_connection", "selmaR")(NULL),
               "No SELMA connection found")
  env$connection <- old
})

test_that("selma_get_connection retrieves stored connection", {
  con <- structure(
    list(base_url = "https://stored.selma.co.nz/", token = "Bearer stored"),
    class = "selma_connection"
  )
  env <- getFromNamespace("selma_env", "selmaR")
  old <- env$connection
  env$connection <- con
  result <- getFromNamespace("selma_get_connection", "selmaR")(NULL)
  expect_identical(result, con)
  env$connection <- old
})

test_that("selma_get_connection rejects non-connection objects", {
  expect_error(
    getFromNamespace("selma_get_connection", "selmaR")("not a connection"),
    "selma_connection"
  )
})

test_that("selma_disconnect clears stored connection", {
  env <- getFromNamespace("selma_env", "selmaR")
  old <- env$connection
  env$connection <- structure(
    list(base_url = "https://x.selma.co.nz/", token = "Bearer x"),
    class = "selma_connection"
  )
  expect_message(selma_disconnect(), "cleared")
  expect_null(env$connection)
  env$connection <- old
})

# Version-specific credential resolution ----------------------------------

test_that("selma_resolve_config reads version-specific config block", {
  tmp <- withr::local_tempfile(fileext = ".yml")
  writeLines(c(
    "default:",
    "  selma:",
    '    base_url: "https://myorg.selma.co.nz/"',
    '    email: "v2@selma.co.nz"',
    '    password: "v2pass"',
    "    v3:",
    '      email: "v3@selma.co.nz"',
    '      password: "v3pass"'
  ), tmp)

  withr::local_envvar(SELMA_BASE_URL = "", SELMA_EMAIL = "", SELMA_PASSWORD = "")

  # v3 block used for v3
  cfg_v3 <- selmaR:::selma_resolve_config(NULL, NULL, NULL,
                                           config_file = tmp, api_version = "v3")
  expect_equal(cfg_v3$email,    "v3@selma.co.nz")
  expect_equal(cfg_v3$password, "v3pass")
  # base_url falls back to flat block
  expect_equal(cfg_v3$base_url, "https://myorg.selma.co.nz/")

  # flat block used for v2 (no v2 block present)
  cfg_v2 <- selmaR:::selma_resolve_config(NULL, NULL, NULL,
                                           config_file = tmp, api_version = "v2")
  expect_equal(cfg_v2$email,    "v2@selma.co.nz")
  expect_equal(cfg_v2$password, "v2pass")
})

test_that("selma_resolve_config falls back to flat block when version block absent", {
  tmp <- withr::local_tempfile(fileext = ".yml")
  writeLines(c(
    "default:",
    "  selma:",
    '    base_url: "https://myorg.selma.co.nz/"',
    '    email: "flat@selma.co.nz"',
    '    password: "flatpass"'
  ), tmp)

  withr::local_envvar(SELMA_BASE_URL = "", SELMA_EMAIL = "", SELMA_PASSWORD = "")

  # No v3 block — falls back to flat credentials
  cfg <- selmaR:::selma_resolve_config(NULL, NULL, NULL,
                                        config_file = tmp, api_version = "v3")
  expect_equal(cfg$email,    "flat@selma.co.nz")
  expect_equal(cfg$password, "flatpass")
})

test_that("selma_resolve_config uses version-specific env vars", {
  withr::local_envvar(
    SELMA_BASE_URL    = "https://shared.selma.co.nz/",
    SELMA_EMAIL       = "generic@selma.co.nz",
    SELMA_PASSWORD    = "genericpass",
    SELMA_V3_EMAIL    = "v3env@selma.co.nz",
    SELMA_V3_PASSWORD = "v3envpass"
  )

  cfg <- selmaR:::selma_resolve_config(NULL, NULL, NULL,
                                        config_file = NULL, api_version = "v3")
  expect_equal(cfg$email,    "v3env@selma.co.nz")
  expect_equal(cfg$password, "v3envpass")
  # base_url falls back to generic since no SELMA_V3_BASE_URL set
  expect_equal(cfg$base_url, "https://shared.selma.co.nz/")
})

test_that("selma_resolve_config falls back to generic env vars when version-specific absent", {
  withr::local_envvar(
    SELMA_BASE_URL    = "https://shared.selma.co.nz/",
    SELMA_EMAIL       = "generic@selma.co.nz",
    SELMA_PASSWORD    = "genericpass",
    SELMA_V3_EMAIL    = "",
    SELMA_V3_PASSWORD = ""
  )

  cfg <- selmaR:::selma_resolve_config(NULL, NULL, NULL,
                                        config_file = NULL, api_version = "v3")
  expect_equal(cfg$email,    "generic@selma.co.nz")
  expect_equal(cfg$password, "genericpass")
})
