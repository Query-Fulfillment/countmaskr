library(testthat)

test_that("Primary masking works correctly", {
  x <- c(5, 15, 0, NA)
  expect_equal(
    mask_counts(x, threshold = 11),
    c("<11", "<20", "0", NA_character_)
  )
})

test_that("Secondary masking Condition A is applied", {
  x <- c(5, 15, 20)
  result <- mask_counts(x, threshold = 11)
  expect_true(sum(grepl("<", result)) == 2)
})

test_that("Secondary masking Condition B is applied", {
  x <- c(1, 1, 15, 20)
  result <- mask_counts(x, threshold = 11)
  expect_true(sum(grepl("<", result)) == 3)
})

test_that("Secondary masking Condition C is applied", {
  x <- c(10, 10, 15, 20)
  result <- mask_counts(x, threshold = 11)
  expect_true(sum(grepl("<", result)) == 3)
})

test_that("Zero masking works when zero_masking is TRUE", {
  x <- c(5, 15, 0)
  threshold = 11
  result <- mask_counts(x, zero_masking = TRUE)
  expect_true(all(result[c(1,3)] == paste0("<",threshold)))
})

test_that("Secondary cell selection method 'min' works", {
  x <- c(5, 15, 20)
  result <- mask_counts(x, secondary_cell = "min")
  expect_equal(result[which(result != "<11")], c("<20","20"))
})

test_that("Secondary cell selection method 'max' works", {
  x <- c(5, 15, 20)
  result <- mask_counts(x, secondary_cell = "max")
  expect_equal(result[which(result != "<11")], c("15","<25"))
})

test_that("Secondary cell selection method 'random' works", {
  x <- c(5, 15, 20)
  set.seed(123)
  result <- mask_counts(x, secondary_cell = "random")
  expect_true(sum(grepl("<", result)) == 2)
})

test_that("Function handles NA values correctly", {
  x <- c(5, NA, 15)
  result <- mask_counts(x)
  expect_equal(result, c("<11", NA_character_, "<20"))
})

test_that("Function returns character vector", {
  x <- c(5, 15, 20)
  result <- mask_counts(x)
  expect_true(is.character(result))
})

test_that("Threshold parameter works correctly", {
  x <- c(4, 7, 9, 15)
  result <- mask_counts(x, threshold = 5)
  expect_equal(result, c("<5", "<10", "9", "15"))
})

# ===== Test Series #2

test_that("Function handles character input with numeric strings", {
  x <- c("5", "15", "20")
  result <- mask_counts(x, threshold = 11)
  expect_equal(result, c("<11", "<20", "20"))
})

test_that("Function handles character input with mixed content", {
  x <- c("5 apples", "15 oranges", "20 bananas")
  expect_error(mask_counts(x), "Error: Values contain disallowed characters or invalid format.")
})

test_that("Function handles character input with non-numeric strings", {
  x <- c("five", "fifteen", "twenty")
  expect_error(mask_counts(x), "Error: Values contain disallowed characters or invalid format.")
})

test_that("Function handles character input with special characters", {
  x <- c("$5", "€15", "£20")
  expect_error(mask_counts(x), "Error: Values contain disallowed characters or invalid format.")
})

test_that("Function handles character input with negative numbers", {
  x <- c("-5","4", "15", "20")
  result <- mask_counts(x, threshold = 11)
  expect_equal(result, c("-5","<11","<20", "20"))
})

