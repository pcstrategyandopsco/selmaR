test_that("selma_get rejects non-connection objects", {
  expect_error(selma_get("not_a_connection", "students"), "selma_connection")
})

test_that("standardize_selma_data: id arrives as integer after upstream @id drop", {
  # Simulates data as it arrives from selma_fetch_all_pages() —
  # @id/@type/@context have already been dropped; id is the integer primary key.
  df <- data.frame(
    id         = c(1L, 2L),
    first_name = c("Alice", "Bob"),
    stringsAsFactors = FALSE
  )

  result <- suppressWarnings(selmaR:::standardize_selma_data(df, "students", api_version = "v3"))

  expect_true("id" %in% names(result))
  expect_equal(result$id, c(1L, 2L))
  expect_true("first_name" %in% names(result))
})

test_that("standardize_selma_data: v3 IRI foreign keys are stripped to bare segment", {
  df <- data.frame(
    id      = c(1L, 2L),
    student = c("/api/students/42", "/api/students/99"),
    intake  = c("/api/intakes/10", "/api/intakes/10"),
    stringsAsFactors = FALSE
  )

  result <- suppressWarnings(selmaR:::standardize_selma_data(df, "enrolments", api_version = "v3"))

  expect_equal(result$student, c("42", "99"))
  expect_equal(result$intake,  c("10", "10"))
  expect_equal(result$id,      c(1L, 2L))
})

test_that("standardize_selma_data: v2 integer foreign keys are not modified", {
  df <- data.frame(
    id        = c(1L, 2L),
    student_id = c(42L, 99L),
    intake_id  = c(10L, 10L),
    stringsAsFactors = FALSE
  )

  result <- suppressWarnings(selmaR:::standardize_selma_data(df, "enrolments", api_version = "v2"))

  expect_equal(result$student_id, c(42L, 99L))
  expect_equal(result$intake_id,  c(10L, 10L))
})

test_that("standardize_selma_data applies clean_names", {
  df <- data.frame(
    FirstName = "Alice",
    LastName  = "Smith",
    stringsAsFactors = FALSE
  )

  result <- suppressWarnings(selmaR:::standardize_selma_data(df, "students"))
  expect_true("first_name" %in% names(result))
  expect_true("last_name"  %in% names(result))
})

test_that("standardize_selma_data handles empty data frame", {
  df <- data.frame(id = character(0), name = character(0))
  result <- selmaR:::standardize_selma_data(df, "students")
  expect_equal(nrow(result), 0)
})

test_that("flatten_intake_enrolment_json handles empty input", {
  result <- selmaR:::flatten_intake_enrolment_json(list())
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0)
})
