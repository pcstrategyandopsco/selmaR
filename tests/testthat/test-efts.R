test_that("selma_efts_report calculates pro-rata EFTS correctly", {
  # A component running Jan 1 - Dec 31 (365 days) with 1.0 EFTS
  # should have ~1/12 EFTS in each month
  components <- tibble::tibble(
    compenrid = "1",
    compid = "100",
    enrolid = "10",
    studentid = "1000",
    compenrstartdate = "2025-01-01T00:00:00+13:00",
    compenrenddate = "2025-12-31T00:00:00+13:00",
    compenrefts = "1.0",
    compenrstatus = "C",
    compenrsource = "01",
    compenrfundingcategory = "A"
  )

  result <- selma_efts_report(components, year = 2025)

  expect_s3_class(result, "tbl_df")
  expect_true("total" %in% names(result))
  expect_equal(nrow(result), 1)
  # Total should be close to 1.0 (rounding may cause slight difference)
  expect_true(abs(result$total - 1.0) < 0.01)
})

test_that("selma_efts_report excludes international when requested", {
  components <- tibble::tibble(
    compenrid = c("1", "2"),
    compid = c("100", "101"),
    enrolid = c("10", "11"),
    studentid = c("1000", "1001"),
    compenrstartdate = c("2025-01-01", "2025-01-01"),
    compenrenddate = c("2025-12-31", "2025-12-31"),
    compenrefts = c("1.0", "0.5"),
    compenrstatus = c("C", "C"),
    compenrsource = c("01", "02"),
    compenrfundingcategory = c("A", "A")
  )

  result_excl <- selma_efts_report(components, year = 2025, exclude_international = TRUE)
  result_incl <- selma_efts_report(components, year = 2025, exclude_international = FALSE)

  expect_equal(nrow(result_excl), 1)
  expect_true(nrow(result_incl) >= 1)
})

test_that("selma_efts_report filters by funded statuses", {
  components <- tibble::tibble(
    compenrid = c("1", "2"),
    compid = c("100", "101"),
    enrolid = c("10", "11"),
    studentid = c("1000", "1001"),
    compenrstartdate = c("2025-01-01", "2025-01-01"),
    compenrenddate = c("2025-12-31", "2025-12-31"),
    compenrefts = c("1.0", "0.5"),
    compenrstatus = c("C", "X"),
    compenrsource = c("01", "01"),
    compenrfundingcategory = c("A", "A")
  )

  result <- selma_efts_report(components, year = 2025)
  # Only the "C" component should be included
  expect_true(abs(result$total - 1.0) < 0.01)
})

test_that("selma_efts_report handles partial year overlap", {
  # Component runs Jul 1 - Dec 31 (184 days)
  components <- tibble::tibble(
    compenrid = "1",
    compid = "100",
    enrolid = "10",
    studentid = "1000",
    compenrstartdate = "2025-07-01",
    compenrenddate = "2025-12-31",
    compenrefts = "0.5",
    compenrstatus = "C",
    compenrsource = "01",
    compenrfundingcategory = "A"
  )

  result <- selma_efts_report(components, year = 2025)

  # Jan-Jun should be 0
  expect_equal(result$efts_01, 0)
  expect_equal(result$efts_06, 0)
  # Jul onwards should be positive
  expect_true(result$efts_07 > 0)
  expect_equal(result$total, 0.5, tolerance = 0.01)
})

test_that("selma_efts_report excludes cross-credited enrolments", {
  # Two components in same enrolment, EFTS sum to 0
  components <- tibble::tibble(
    compenrid = c("1", "2"),
    compid = c("100", "101"),
    enrolid = c("10", "10"),
    studentid = c("1000", "1000"),
    compenrstartdate = c("2025-01-01", "2025-01-01"),
    compenrenddate = c("2025-12-31", "2025-12-31"),
    compenrefts = c("0.5", "-0.5"),
    compenrstatus = c("C", "C"),
    compenrsource = c("01", "01"),
    compenrfundingcategory = c("A", "A")
  )

  result <- selma_efts_report(components, year = 2025)
  expect_equal(nrow(result), 0)
})
