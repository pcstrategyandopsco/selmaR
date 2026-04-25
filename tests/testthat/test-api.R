test_that("selma_get rejects non-connection objects", {
  expect_error(selma_get("not_a_connection", "students"), "selma_connection")
})

test_that("standardize_selma_data drops Hydra @id column", {
  df <- data.frame(
    id = c("/app/students/1", "/app/students/2"),
    id_2 = c(1L, 2L),
    type = c("Student", "Student"),
    forename = c("Alice", "Bob"),
    stringsAsFactors = FALSE
  )

  result <- suppressWarnings(selmaR:::standardize_selma_data(df, "students"))

  expect_false("type" %in% names(result))
  expect_true("id" %in% names(result))
  expect_equal(result$id, c("1", "2"))
  expect_true("forename" %in% names(result))
})

test_that("standardize_selma_data handles id without id_2", {
  df <- data.frame(
    id = c("/app/intakes/10", "/app/intakes/20"),
    intakeid = c(10L, 20L),
    stringsAsFactors = FALSE
  )

  result <- suppressWarnings(selmaR:::standardize_selma_data(df, "intakes"))
  expect_true("intakeid" %in% names(result))
  expect_equal(result$intakeid, c("10", "20"))
})

test_that("standardize_selma_data converts IDs to character", {
  df <- data.frame(
    id_2 = 1:3,
    student_id = 10:12,
    intake_id = 100:102,
    id = c("/app/enrolments/1", "/app/enrolments/2", "/app/enrolments/3"),
    stringsAsFactors = FALSE
  )

  result <- suppressWarnings(selmaR:::standardize_selma_data(df, "enrolments"))
  expect_type(result$id, "character")
  expect_type(result$student_id, "character")
  expect_type(result$intake_id, "character")
})

test_that("standardize_selma_data applies clean_names", {
  df <- data.frame(
    FirstName = "Alice",
    LastName = "Smith",
    stringsAsFactors = FALSE
  )

  result <- suppressWarnings(selmaR:::standardize_selma_data(df, "students"))
  expect_true("first_name" %in% names(result))
  expect_true("last_name" %in% names(result))
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
