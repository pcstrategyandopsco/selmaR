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
