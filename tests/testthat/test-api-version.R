# Tests for R/api_version.R — version config registry and helpers

# ---------------------------------------------------------------------------
# api_cfg()
# ---------------------------------------------------------------------------

test_that("api_cfg returns v2 config", {
  cfg <- selmaR:::api_cfg("v2")
  expect_equal(cfg$path_prefix,  "app/")
  expect_equal(cfg$member_key,   "hydra:member")
  expect_equal(cfg$total_key,    "hydra:totalItems")
  expect_equal(cfg$auth_endpoint, "api/login_check")
})

test_that("api_cfg returns v3 config", {
  cfg <- selmaR:::api_cfg("v3")
  expect_equal(cfg$path_prefix,  "api/")
  expect_equal(cfg$member_key,   "member")
  expect_equal(cfg$total_key,    "totalItems")
  expect_equal(cfg$auth_endpoint, "api/auth")
})

test_that("api_cfg errors on unknown version", {
  expect_error(selmaR:::api_cfg("v99"), "Unknown api_version")
  expect_error(selmaR:::api_cfg("v99"), "v99")
})

# ---------------------------------------------------------------------------
# extract_members()
# ---------------------------------------------------------------------------

test_that("extract_members returns v2 members from hydra:member key", {
  page_data <- list(
    "hydra:member"     = list(list(id = 1, name = "Alice"), list(id = 2, name = "Bob")),
    "hydra:totalItems" = 2L
  )
  members <- selmaR:::extract_members(page_data, "v2")
  expect_length(members, 2L)
  expect_equal(members[[1]]$name, "Alice")
})

test_that("extract_members returns v3 members from member key", {
  page_data <- list(
    member     = list(list(id = 1, first_name = "Alice")),
    totalItems = 1L
  )
  members <- selmaR:::extract_members(page_data, "v3")
  expect_length(members, 1L)
  expect_equal(members[[1]]$first_name, "Alice")
})

test_that("extract_members falls back to other version key with warning", {
  # v2 connection but response uses v3 key (upgraded instance)
  page_data <- list(
    member     = list(list(id = 1, name = "Alice")),
    totalItems = 1L
  )
  expect_warning(
    members <- selmaR:::extract_members(page_data, "v2"),
    "member"
  )
  expect_length(members, 1L)
})

test_that("extract_members errors loud when neither key found", {
  page_data <- list(
    data  = list(list(id = 1)),
    count = 1L
  )
  expect_error(
    selmaR:::extract_members(page_data, "v2"),
    "no member data"
  )
  # Error message should list the available keys
  expect_error(
    selmaR:::extract_members(page_data, "v2"),
    "data"
  )
})

# ---------------------------------------------------------------------------
# selma_connect() — api_version parameter
# ---------------------------------------------------------------------------

test_that("selma_connect rejects invalid api_version", {
  withr::local_envvar(
    SELMA_BASE_URL = "https://x.selma.co.nz/",
    SELMA_EMAIL    = "a@b.com",
    SELMA_PASSWORD = "pass"
  )
  expect_error(
    selma_connect(api_version = "v99", config_file = NULL),
    "Invalid api_version"
  )
})

test_that("print.selma_connection shows api_version", {
  con <- structure(
    list(
      base_url    = "https://test.selma.co.nz/",
      token       = "Bearer eyJtest",
      api_version = "v3"
    ),
    class = "selma_connection"
  )
  expect_output(print(con), "v3")
  expect_output(print(con), "selma_connection")
})

# ---------------------------------------------------------------------------
# standardize_selma_data() — v3 URI pattern
# ---------------------------------------------------------------------------

test_that("standardize_selma_data: v3 @id drop happens upstream, id is integer on arrival", {
  # @id/@type/@context are dropped in selma_fetch_all_pages() before clean_names().
  # By the time data reaches standardize_selma_data(), id is already the integer PK.
  df <- data.frame(
    id         = c(1L, 2L),
    first_name = c("Alice", "Bob"),
    stringsAsFactors = FALSE
  )

  result <- suppressWarnings(
    selmaR:::standardize_selma_data(df, "students", api_version = "v3")
  )

  expect_true("id" %in% names(result))
  expect_equal(result$id, c(1L, 2L))
  expect_true("first_name" %in% names(result))
})

test_that("standardize_selma_data warns when expected fields missing", {
  # Provide a minimal data frame missing most expected v2 student fields
  df <- data.frame(id = "1", stringsAsFactors = FALSE)

  expect_warning(
    selmaR:::standardize_selma_data(df, "students", api_version = "v2"),
    "expected field"
  )
})

test_that("standardize_selma_data does not warn for unknown entity type", {
  # Unknown entity → falls back to heuristic, no schema, no warning
  df <- data.frame(id = "1", name = "x", stringsAsFactors = FALSE)

  expect_no_warning(
    selmaR:::standardize_selma_data(df, "unknown_entity_xyz", api_version = "v2")
  )
})
