# Tests for Phase 12 — version-aware query parameter routing in entity functions

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

# Fake selma_get that captures query_params and returns an empty tibble
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

  suppressWarnings(entity_fn(con = con, ...))
  captured
}

# ---------------------------------------------------------------------------
# selma_students()
# ---------------------------------------------------------------------------

test_that("selma_students sends v2 query param names", {
  q <- capture_query(selma_students,
    forename = "Alice", email1 = "a@b.com", dob = "1990-01-01",
    third_party_id = "TP1", organisation = "99",
    api_version = "v2"
  )
  expect_equal(q$forename, "Alice")
  expect_equal(q$email1, "a@b.com")
  expect_equal(q$dob, "1990-01-01")
  expect_equal(q$ThirdPartyID1, "TP1")
  expect_equal(q$Organisation, "99")
  expect_null(q$first_name)
})

test_that("selma_students sends v3 query param names", {
  q <- capture_query(selma_students,
    forename = "Alice", email1 = "a@b.com", dob = "1990-01-01",
    third_party_id = "TP1",
    api_version = "v3"
  )
  expect_equal(q$first_name, "Alice")
  expect_equal(q$email_primary, "a@b.com")
  expect_equal(q$date_of_birth, "1990-01-01")
  expect_equal(q$other_id_1, "TP1")
  expect_null(q$forename)
  expect_null(q$email1)
})

test_that("selma_students warns about organisation on v3", {
  con <- make_con("v3")
  testthat::local_mocked_bindings(
    selma_get = function(...) tibble::tibble(),
    .package = "selmaR"
  )
  expect_warning(
    selma_students(con = con, organisation = "99"),
    "organisation"
  )
})

# ---------------------------------------------------------------------------
# selma_enrolments()
# ---------------------------------------------------------------------------

test_that("selma_enrolments sends intake and student filters on v3", {
  q <- capture_query(selma_enrolments,
    intake_id = "42", student_id = "7",
    api_version = "v3"
  )
  expect_equal(q$intake, "42")
  expect_equal(q$student, "7")
})

test_that("selma_enrolments warns about v3-only filters on v2", {
  con <- make_con("v2")
  testthat::local_mocked_bindings(
    selma_get = function(...) tibble::tibble(),
    .package = "selmaR"
  )
  expect_warning(
    selma_enrolments(con = con, intake_id = "42"),
    "intake_id"
  )
})

test_that("selma_enrolments sends no query params on v2", {
  q <- capture_query(selma_enrolments, api_version = "v2")
  expect_null(q)
})

# ---------------------------------------------------------------------------
# selma_components()
# ---------------------------------------------------------------------------

test_that("selma_components sends v2 query param names", {
  q <- capture_query(selma_components,
    student_id = "5", enrol_id = "10",
    api_version = "v2"
  )
  expect_equal(q$studentid, "5")
  expect_equal(q$enrolid, "10")
})

test_that("selma_components sends enrolment param on v3", {
  q <- capture_query(selma_components,
    enrol_id = "10",
    api_version = "v3"
  )
  expect_equal(q$enrolment, "10")
  expect_null(q$enrolid)
})

test_that("selma_components warns about student_id on v3", {
  con <- make_con("v3")
  testthat::local_mocked_bindings(
    selma_get = function(...) tibble::tibble(),
    .package = "selmaR"
  )
  expect_warning(
    selma_components(con = con, student_id = "5"),
    "student_id"
  )
})

# ---------------------------------------------------------------------------
# selma_intakes()
# ---------------------------------------------------------------------------

test_that("selma_intakes sends v2 query param names", {
  q <- capture_query(selma_intakes,
    prog_id = "3", status = "Open",
    start_before = "2025-12-31", start_after = "2025-01-01",
    api_version = "v2"
  )
  expect_equal(q$ProgID, "3")
  expect_equal(q$intakestatus, "Open")
  expect_equal(q[["intakestartdate[before]"]], "2025-12-31")
  expect_equal(q[["intakestartdate[after]"]], "2025-01-01")
})

test_that("selma_intakes sends v3 date param names", {
  q <- capture_query(selma_intakes,
    start_before = "2025-12-31", start_after = "2025-01-01",
    api_version = "v3"
  )
  expect_equal(q[["start_date[before]"]], "2025-12-31")
  expect_equal(q[["start_date[after]"]], "2025-01-01")
  expect_null(q[["intakestartdate[before]"]])
})

test_that("selma_intakes warns about prog_id and status on v3", {
  con <- make_con("v3")
  testthat::local_mocked_bindings(
    selma_get = function(...) tibble::tibble(),
    .package = "selmaR"
  )
  expect_warning(
    selma_intakes(con = con, prog_id = "3", status = "Open"),
    "prog_id"
  )
})

# ---------------------------------------------------------------------------
# selma_programmes()
# ---------------------------------------------------------------------------

test_that("selma_programmes sends progstatus on v2", {
  q <- capture_query(selma_programmes, status = "Active", api_version = "v2")
  expect_equal(q$progstatus, "Active")
})

test_that("selma_programmes sends no query params on v3", {
  q <- capture_query(selma_programmes, api_version = "v3")
  expect_null(q)
})

test_that("selma_programmes warns about status on v3", {
  con <- make_con("v3")
  testthat::local_mocked_bindings(
    selma_get = function(...) tibble::tibble(),
    .package = "selmaR"
  )
  expect_warning(
    selma_programmes(con = con, status = "Active"),
    "status"
  )
})

# ---------------------------------------------------------------------------
# selma_intake_enrolments()
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
