test_that("status code constants have correct values", {
  expect_equal(SELMA_STATUS_CONFIRMED, "C")
  expect_equal(SELMA_STATUS_COMPLETED, "FC")
  expect_equal(SELMA_STATUS_INCOMPLETE, "FI")
  expect_equal(SELMA_STATUS_WITHDRAWN, "WR")
  expect_equal(SELMA_STATUS_WITHDRAWN_SDR, "WS")
  expect_equal(SELMA_STATUS_EARLY_WITHDRAWN, "ER")
  expect_equal(SELMA_STATUS_DEFERRED, "D")
  expect_equal(SELMA_STATUS_CANCELLED, "X")
  expect_equal(SELMA_STATUS_PENDING, "P")
})

test_that("funded status groups contain correct values", {
  expect_equal(SELMA_FUNDED_STATUSES, c("C", "FC", "FI"))
  expect_equal(SELMA_ALL_FUNDED_STATUSES, c("C", "FC", "FI", "WR", "WS"))
})

test_that("funding source codes are correct", {
  expect_equal(SELMA_FUNDING_GOVT, "01")
  expect_equal(SELMA_FUNDING_INTL, "02")
  expect_equal(SELMA_FUNDING_MPTT, "29")
  expect_equal(SELMA_FUNDING_YG, "31")
  expect_equal(SELMA_FUNDING_DQ37, "37")
})

test_that("SELMA_FUNDED_STATUSES is a subset of SELMA_ALL_FUNDED_STATUSES", {
  expect_true(all(SELMA_FUNDED_STATUSES %in% SELMA_ALL_FUNDED_STATUSES))
})

test_that("funding labels are named correctly", {
  expect_named(SELMA_FUNDING_LABELS)
  expect_true("01" %in% names(SELMA_FUNDING_LABELS))
  expect_true("02" %in% names(SELMA_FUNDING_LABELS))
})
