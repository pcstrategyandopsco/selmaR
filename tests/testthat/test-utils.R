test_that("parse_selma_date handles ISO 8601 with NZ offsets", {
  expect_equal(
    parse_selma_date("2023-07-31T00:00:00+12:00"),
    as.Date("2023-07-31")
  )
  expect_equal(
    parse_selma_date("2024-11-15T00:00:00+13:00"),
    as.Date("2024-11-15")
  )
})

test_that("parse_selma_date handles plain dates", {
  expect_equal(parse_selma_date("2024-01-15"), as.Date("2024-01-15"))
})

test_that("parse_selma_date handles NA", {
  expect_true(is.na(parse_selma_date(NA)))
})

test_that("parse_selma_date is vectorized", {
  result <- parse_selma_date(c("2024-01-15T00:00:00+12:00", NA, "2024-06-01"))
  expect_length(result, 3)
  expect_equal(result[1], as.Date("2024-01-15"))
  expect_true(is.na(result[2]))
  expect_equal(result[3], as.Date("2024-06-01"))
})

# Phone standardization (via dialvalidator) --------------------------------

test_that("standardize_phone handles NZ mobile with leading 0", {
  expect_equal(standardize_phone("021 123 4567"), "+64211234567")
  expect_equal(standardize_phone("0211234567"), "+64211234567")
})

test_that("standardize_phone handles NZ with +64", {
  expect_equal(standardize_phone("+64211234567"), "+64211234567")
})

test_that("standardize_phone handles NZ mobile without leading 0", {
  expect_equal(standardize_phone("211234567"), "+64211234567")
})

test_that("standardize_phone handles AU mobile with +61", {
  expect_equal(standardize_phone("+61412345678"), "+61412345678")
})

test_that("standardize_phone handles AU local numbers via fallback", {
  # 04xx is not valid NZ, so falls back to AU

  expect_equal(standardize_phone("0412345678"), "+61412345678")
})

test_that("standardize_phone handles short/invalid numbers", {
  expect_true(is.na(standardize_phone("1234")))
  expect_true(is.na(standardize_phone("abc")))
})

test_that("standardize_phone handles NA and empty", {
  expect_true(is.na(standardize_phone(NA)))
  expect_true(is.na(standardize_phone("")))
  expect_true(is.na(standardize_phone(NULL)))
})

test_that("standardize_phones is vectorized", {
  result <- standardize_phones(c("021 123 4567", "+61412345678", NA))
  expect_length(result, 3)
  expect_equal(result[1], "+64211234567")
  expect_equal(result[2], "+61412345678")
  expect_true(is.na(result[3]))
})

test_that("standardize_phones handles mixed NZ and AU numbers", {
  result <- standardize_phones(c("021 123 4567", "0412345678", "+61412345678"))
  expect_equal(result, c("+64211234567", "+61412345678", "+61412345678"))
})

# URL builders -------------------------------------------------------------

test_that("selma_student_url builds correct URL", {
  url <- selma_student_url(123, "https://myorg.selma.co.nz/")
  expect_equal(url, "https://myorg.selma.co.nz/en/admin/student/123/1")
})

test_that("selma_student_url handles NA", {
  expect_true(is.na(selma_student_url(NA, "https://myorg.selma.co.nz/")))
})

test_that("selma_enrolment_url builds correct URL", {
  url <- selma_enrolment_url(456, "https://myorg.selma.co.nz/")
  expect_equal(url, "https://myorg.selma.co.nz/en/admin/enrolment/456/1")
})

test_that("selma_enrolment_url handles NA", {
  expect_true(is.na(selma_enrolment_url(NA, "https://myorg.selma.co.nz/")))
})

test_that("URL builders are vectorized", {
  urls <- selma_student_url(c(1, 2, NA), "https://x.selma.co.nz/")
  expect_length(urls, 3)
  expect_true(is.na(urls[3]))
})
