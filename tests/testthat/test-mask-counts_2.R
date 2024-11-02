library(testthat)

# Assuming mask_counts_2 function is already defined or sourced

# Test 1: Basic functionality with default threshold
test_that("Basic masking with default threshold", {
  counts <- c(5, 11, 43, 55, 65, 121, 1213, 0, NA)
  expected <- c("<11", "11", "43", "55", "65", "121", ">1,207", "0", NA)
  result <- mask_counts_2(counts)
  expect_equal(result, expected)
})

# Test 2: Counts with multiple values below threshold
test_that("Masking multiple values below threshold", {
  counts <- c(1, 1, 1, 55, 65, 121, 1213, 0, NA)
  expected <- c("<11", "<11", "<11", "55", "65", "121", ">1,183", "0", NA)
  result <- mask_counts_2(counts)
  expect_equal(result, expected)
})

# Test 3: Counts with values equal to threshold
test_that("Values equal to threshold are not masked", {
  counts <- c(11, 10, 10, 55, 65, 121, 1213, 0, NA)
  expected <- c("11", "<11", "<11", "55", "65", "121", ">1,211", "0", NA)
  result <- mask_counts_2(counts)
  expect_equal(result, expected)
})

# Test 4: Custom threshold
test_that("Masking with custom threshold", {
  counts <- c(5, 15, 20, 25)
  threshold <- 20
  expected <- c("<20", "<20", "20", "25")
  result <- mask_counts_2(counts, threshold = threshold)
  expect_equal(result, expected)
})

# Test 5: Zero masking enabled
test_that("Zero masking enabled", {
  counts <- c(0, 5, 13, 15)
  expected <- c("<11", "<11", "13", "15")
  result <- mask_counts_2(counts, zero_masking = TRUE)
  expect_equal(result, expected)
})

# Test 6: Non-numeric input with special characters
test_that("Non-numeric input with special characters", {
  counts <- c("5 people", "<11", "20+", NA)
  expect_error(mask_counts_2(counts),"Error: Values contain disallowed characters or invalid format.")
})

# Test 7: All counts below threshold
test_that("All counts below threshold", {
  counts <- c(1, 2, 3, 4)
  expected <- rep("<11", length(counts))
  result <- mask_counts_2(counts)
  expect_equal(result, expected)
})

# Test 8: All counts above threshold
test_that("All counts above threshold", {
  counts <- c(12, 13, 14, 15)
  expected <- format(counts, digits = 1, big.mark = ",", trim = TRUE)
  result <- mask_counts_2(counts)
  expect_equal(result, expected)
})

# Test 9: Counts with NA values
test_that("Counts with NA values", {
  counts <- c(5, NA, 15, NA)
  expected <- c("<11", NA, ">11", NA)
  result <- mask_counts_2(counts)
  expect_equal(result, expected)
})

# Test 10: Threshold as a non-integer value
test_that("Non-integer threshold", {
  counts <- c(5, 10, 15, 20)
  threshold <- 12.5
  expected <- c("<12.5", "<12.5", "15", "20")
  result <- mask_counts_2(counts, threshold = threshold)
  expect_equal(result, expected)
})

# Test 11: Negative counts
test_that("Negative counts", {
  counts <- c(-5, -10, 5, 10)
  expected <- c("-5", "-10", "<11", "<11")
  result <- mask_counts_2(counts)
  expect_equal(result, expected)
})

# Test 12: Zero counts without zero masking
test_that("Zero counts without zero masking", {
  counts <- c(0, 5, 10, 15)
  expected <- c("0", "<11", "<11", "15")
  result <- mask_counts_2(counts)
  expect_equal(result, expected)
})

# Test 13: Secondary masking when only one primary masked cell is present
test_that("Secondary masking with one primary masked cell", {
  counts <- c(5, 15, 80)
  expected <- c("<11", "15", ">74")
  result <- mask_counts_2(counts)
  expect_equal(result, expected)
})

# Test 14: Secondary masking when two primary masked cells are present
test_that("Secondary masking with two primary masked cells", {
  counts <- c(5, 6, 89)
  expected <- c("<11", "<11", "89")
  result <- mask_counts_2(counts)
  expect_equal(result, expected)
})

# Test 15: Large numbers
test_that("Handling large numbers", {
  counts <- c(1e6, 5e6, 1e7)
  expected <- format(counts, digits = 1, big.mark = ",", trim = TRUE)
  result <- mask_counts_2(counts)
  expect_equal(result, expected)
})
