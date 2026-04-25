# Tests for version-aware pagination — mocked HTTP responses for v2 and v3

make_con <- function(api_version = "v2") {
  structure(
    list(
      base_url    = "https://test.selma.co.nz/",
      token       = "Bearer testtoken",
      api_version = api_version
    ),
    class = "selma_connection"
  )
}

# ---------------------------------------------------------------------------
# selma_fetch_all_pages() — driven through selma_get() with mocked requests
# ---------------------------------------------------------------------------

test_that("selma_get fetches v2 paginated response via hydra:member", {
  con <- make_con("v2")

  # Single-page v2 response — member must be a data.frame (mirrors simplifyVector=TRUE)
  fake_response <- list(
    "hydra:member"     = data.frame(
      id      = c("/app/students/1", "/app/students/2"),
      id_2    = c(1L, 2L),
      forename = c("Alice", "Bob"),
      stringsAsFactors = FALSE
    ),
    "hydra:totalItems" = 2L,
    "hydra:view"       = list("hydra:next" = NULL)
  )

  testthat::local_mocked_bindings(
    selma_request = function(con, url, query = NULL) fake_response,
    .package = "selmaR"
  )

  result <- selmaR::selma_get(con, "students", items_per_page = 100L,
                              .progress = FALSE)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 2L)
  # clean_names applied — forename passes through as-is
  expect_true("forename" %in% names(result))
})

test_that("selma_get fetches v3 paginated response via member key", {
  con <- make_con("v3")

  fake_response <- list(
    member     = data.frame(
      id         = c("/api/students/1", "/api/students/2"),
      first_name = c("Alice", "Bob"),
      surname    = c("Smith", "Jones"),
      stringsAsFactors = FALSE
    ),
    totalItems = 2L,
    view       = list(next_ = NULL)
  )

  testthat::local_mocked_bindings(
    selma_request = function(con, url, query = NULL) fake_response,
    .package = "selmaR"
  )

  result <- selmaR::selma_get(con, "students", items_per_page = 100L,
                              .progress = FALSE)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 2L)
  expect_true("first_name" %in% names(result))
})

test_that("selma_get uses version-correct URL path prefix", {
  urls_seen <- character(0)

  fake_response_v2 <- list(
    "hydra:member"     = data.frame(id = "/app/students/1", id_2 = 1L,
                                    stringsAsFactors = FALSE),
    "hydra:totalItems" = 1L
  )
  fake_response_v3 <- list(
    member     = data.frame(id = "/api/students/1", stringsAsFactors = FALSE),
    totalItems = 1L
  )

  # v2 — should hit app/ prefix
  testthat::local_mocked_bindings(
    selma_request = function(con, url, query = NULL) {
      urls_seen <<- c(urls_seen, url)
      fake_response_v2
    },
    .package = "selmaR"
  )
  selmaR::selma_get(make_con("v2"), "students", .progress = FALSE)
  expect_true(any(grepl("app/students", urls_seen)))

  urls_seen <- character(0)

  # v3 — should hit api/ prefix
  testthat::local_mocked_bindings(
    selma_request = function(con, url, query = NULL) {
      urls_seen <<- c(urls_seen, url)
      fake_response_v3
    },
    .package = "selmaR"
  )
  selmaR::selma_get(make_con("v3"), "students", .progress = FALSE)
  expect_true(any(grepl("api/students", urls_seen)))
})

test_that("selma_get warns and falls back when member key is wrong version", {
  # v2 connection receiving a v3-style response:
  # has "hydra:totalItems" (so pagination fires) but "member" instead of "hydra:member"
  con <- make_con("v2")

  fake_response <- list(
    "hydra:totalItems" = 1L,
    member = data.frame(id = "/api/students/1", first_name = "Alice",
                        stringsAsFactors = FALSE)
  )

  testthat::local_mocked_bindings(
    selma_request = function(con, url, query = NULL) fake_response,
    .package = "selmaR"
  )

  expect_warning(
    result <- selmaR::selma_get(con, "students", .progress = FALSE),
    "member"
  )
  expect_equal(nrow(result), 1L)
})

test_that("selma_get errors when response has no member data", {
  # Response passes pagination detection (has hydra:totalItems) but has
  # neither "hydra:member" nor "member" — extract_members should error loud
  con <- make_con("v2")

  bad_response <- list("hydra:totalItems" = 2L, results = list(), count = 2L)

  testthat::local_mocked_bindings(
    selma_request = function(con, url, query = NULL) bad_response,
    .package = "selmaR"
  )

  expect_error(
    selmaR::selma_get(con, "students", .progress = FALSE),
    "no member data"
  )
})
