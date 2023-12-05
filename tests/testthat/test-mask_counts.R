test_that("mask_counts_output_test1", {
  x <- c(5, 11, 43, 55, 65, 121, 1213, 0, NA)
  expect_equal(
    mask_counts(x), 
    c('<11', '<20', '43', '55', '65', '121', '1,213', '0', NA)
  )
})

test_that("mask_counts_output_w_threshold", {
  x <- c(5, 11, 43, 55, 65, 121, 1213, 0, NA)
  expect_equal(
    mask_counts(x, threshold = 12), 
    c('<12', '<12', '43', '55', '65', '121', '1,213', '0', NA)
  )
})

test_that("mask_counts_output_w_nonnumeric", {
  x <- c(5, 11, 'abc', 55, 65, 121, 1213, 0, NA)
  expect_equal(
    mask_counts(x), 
    c('<11', '<20', NA, '55', '65', '121', '1,213', '0', NA)
  )
})