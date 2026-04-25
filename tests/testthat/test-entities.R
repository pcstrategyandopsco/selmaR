# Tests for schema-registry-driven entity fetch functions

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

# Helper: run an entity function with a mocked selma_get; return captured query
capture_query <- function(entity_fn, ..., api_version = "v2") {
  captured <- NULL
  con <- make_con(api_version)

  testthat::local_mocked_bindings(
    selma_get = function(con, endpoint, query_params = NULL, ...) {
      captured <<- query_params
      tibble::tibble()
    },
    .package = "selmaR"
  )

  entity_fn(con = con, ...)
  captured
}

# ---------------------------------------------------------------------------
# make_entity_fetcher — filter passthrough
# ---------------------------------------------------------------------------

test_that("valid filter params are passed to selma_get", {
  q <- suppressWarnings(capture_query(selma_enrolments,
    filter = list(intake = "42", student = "7"),
    api_version = "v3"
  ))
  expect_equal(q$intake, "42")
  expect_equal(q$student, "7")
})

test_that("unknown filter params emit a warning and are dropped", {
  con <- make_con("v3")
  captured <- NULL

  testthat::local_mocked_bindings(
    selma_get = function(con, endpoint, query_params = NULL, ...) {
      captured <<- query_params
      tibble::tibble()
    },
    .package = "selmaR"
  )

  expect_warning(
    selma_enrolments(con = con, filter = list(intake = "42", not_a_real_param = "x")),
    "not_a_real_param"
  )

  expect_equal(captured$intake, "42")
  expect_null(captured$not_a_real_param)
})

test_that("empty filter sends NULL query params", {
  q <- suppressWarnings(capture_query(selma_enrolments, api_version = "v3"))
  expect_null(q)
})

test_that("enrolments date filter passes bracket-notation param", {
  q <- suppressWarnings(capture_query(selma_enrolments,
    filter = list("enrolment_status_date[after]" = "2026-01-01"),
    api_version = "v3"
  ))
  expect_equal(q[["enrolment_status_date[after]"]], "2026-01-01")
})

test_that("students filter passes v3 param names", {
  q <- suppressWarnings(capture_query(selma_students,
    filter = list(surname = "Smith", first_name = "Alice"),
    api_version = "v3"
  ))
  expect_equal(q$surname, "Smith")
  expect_equal(q$first_name, "Alice")
})

test_that("intakes start_date filter passes through on v3", {
  q <- suppressWarnings(capture_query(selma_intakes,
    filter = list("start_date[after]" = "2025-01-01"),
    api_version = "v3"
  ))
  expect_equal(q[["start_date[after]"]], "2025-01-01")
})

test_that("components enrolment filter passes through on v3", {
  q <- suppressWarnings(capture_query(selma_components,
    filter = list(enrolment = "10"),
    api_version = "v3"
  ))
  expect_equal(q$enrolment, "10")
})

test_that("unknown param warning mentions valid params", {
  expect_warning(
    capture_query(selma_students,
      filter = list(bad_param = "x"),
      api_version = "v3"
    ),
    "bad_param"
  )
})

# ---------------------------------------------------------------------------
# selma_intake_enrolments() — unchanged, v3 guard still in place
# ---------------------------------------------------------------------------

test_that("selma_intake_enrolments errors on v3 connection", {
  con <- make_con("v3")
  expect_error(
    selma_intake_enrolments(con = con, intake_id = 42),
    "not available for SELMA v3"
  )
})

test_that("selma_intake_enrolments error message mentions selma_enrolments", {
  con <- make_con("v3")
  expect_error(
    selma_intake_enrolments(con = con, intake_id = 42),
    "selma_enrolments"
  )
})

test_that("selma_intake_enrolments requires intake_id on v2", {
  con <- make_con("v2")
  expect_error(
    selma_intake_enrolments(con = con),
    "intake_id"
  )
})
