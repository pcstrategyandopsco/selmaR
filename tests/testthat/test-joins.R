# Test data ---------------------------------------------------------------
mock_students <- tibble::tibble(
  id = c("1", "2", "3"),
  first_name = c("Alice", "Bob", "Carol")
)

mock_enrolments <- tibble::tibble(
  id = c("100", "101", "102"),
  student_id = c("1", "2", "1"),
  intake_id = c("10", "10", "11"),
  enrstatus = c("C", "FC", "WR")
)

mock_intakes <- tibble::tibble(
  intakeid = c("10", "11"),
  progid = c("P1", "P2"),
  intake_name = c("Intake A", "Intake B")
)

mock_components <- tibble::tibble(
  compenrid = c("500", "501"),
  enrolid = c("100", "101"),
  compname = c("Unit 1", "Unit 2")
)

mock_programmes <- tibble::tibble(
  progid = c("P1", "P2"),
  prog_name = c("Programme X", "Programme Y")
)

# Join tests --------------------------------------------------------------

test_that("selma_join_students joins enrolments to students", {
  result <- selma_join_students(mock_enrolments, mock_students)
  expect_equal(nrow(result), 3)
  expect_true("first_name" %in% names(result))
  expect_equal(result$first_name[1], "Alice")
})

test_that("selma_join_intakes joins enrolments to intakes", {
  result <- selma_join_intakes(mock_enrolments, mock_intakes)
  expect_equal(nrow(result), 3)
  expect_true("intake_name" %in% names(result))
})

test_that("selma_student_pipeline joins all three", {
  result <- selma_student_pipeline(mock_enrolments, mock_students, mock_intakes)
  expect_equal(nrow(result), 3)
  expect_true("first_name" %in% names(result))
  expect_true("intake_name" %in% names(result))
})

test_that("selma_join_components joins components to enrolments", {
  result <- selma_join_components(mock_components, mock_enrolments)
  expect_equal(nrow(result), 2)
  expect_true("student_id" %in% names(result))
})

test_that("selma_join_programmes joins intakes to programmes", {
  result <- selma_join_programmes(mock_intakes, mock_programmes)
  expect_equal(nrow(result), 2)
  expect_true("prog_name" %in% names(result))
})
