test_that("cache_is_fresh returns FALSE for missing file", {
  expect_false(selmaR:::cache_is_fresh("/nonexistent/path.rds", 24))
})

test_that("cache_is_fresh returns TRUE for recent file", {
  tmp <- withr::local_tempfile(fileext = ".rds")
  saveRDS(iris, tmp)
  expect_true(selmaR:::cache_is_fresh(tmp, 24))
})

test_that("cache_save and cache_load round-trip", {
  tmp_dir <- withr::local_tempdir()
  path <- file.path(tmp_dir, "test.rds")
  data <- tibble::tibble(x = 1:3, y = letters[1:3])

  selmaR:::cache_save(data, path, "test_entity")
  expect_true(file.exists(path))

  loaded <- selmaR:::cache_load(path, "test_entity")
  expect_equal(loaded, data)
})

test_that("cache_load returns NULL for missing file", {
  expect_null(selmaR:::cache_load("/nonexistent/path.rds", "test"))
})

test_that("cache_path builds correct path", {
  path <- selmaR:::cache_path("my_cache", "students")
  expect_equal(path, file.path("my_cache", "selma_students.rds"))
})
