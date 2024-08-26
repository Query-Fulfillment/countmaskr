library(testthat)
library(dplyr)
library(tidyr)

# Test cases for mask_counts function

test_that("mask_counts handles basic cases correctly", {
  x1 <- c(5, 11, 43, 55, 65, 121, 1213, 0, NA)
  expected1a <- c("<11", "<20", "43", "55", "65", "121", "1,213", "0", NA)
  expected1b <- c("<11", "11", "43", "55", "65", "121", "1,213", "<11", NA)

  expect_equal(mask_counts(x1,zero_masking = FALSE), expected1a)
  expect_equal(mask_counts(x1,zero_masking = TRUE), expected1b)
})

test_that("mask_counts handles all values below threshold", {
  x2 <- c(1, 1, 1, 5, 6, 10, 0, NA)
  expected2 <- c("<11", "<11", "<11", "<11", "<11", "<11", "0", NA)

  expect_equal(mask_counts(x2), expected2)
})

test_that("mask_counts handles secondary masking with one primary cell", {
  x3 <- c(5, 12, 43, 55,0)
  expected3a <- c("<11", "<20", "43", "55","0")
  expected3b <- c("<11", "12", "43", "55","<11")

  expect_equal(mask_counts(x3,zero_masking = FALSE), expected3a)
  expect_equal(mask_counts(x3,zero_masking = TRUE), expected3b)
})

test_that("mask_counts handles secondary masking with two primary cells equal to 1", {
  x4 <- c(1, 1, 43, 55)
  expected4 <- c("<11", "<11", "<50", "55")

  expect_equal(mask_counts(x4,zero_masking = FALSE), expected4)
  expect_equal(mask_counts(x4,zero_masking = TRUE), expected4)
})

test_that("mask_counts handles secondary masking with two primary cells equal to 10", {
  x5 <- c(10, 10, 43, 55,0)

  expected5a <- c("<11", "<11", "<50", "55","0")
  expected5b <- c("<11", "<11", "43", "55","<11")

  expect_equal(mask_counts(x5,zero_masking = FALSE), expected5a)
  expect_equal(mask_counts(x5,zero_masking = TRUE), expected5b)
})

test_that("mask_counts handles character input", {
  x6 <- c("5", "11", "43", "55")
  expected6 <- c("<11", "<20", "43", "55")

  expect_equal(mask_counts(x6), expected6)
})

test_that("mask_counts handles mixed numeric and character input", {
  x7 <- c(5, "11", 43, "55")
  expected7 <- c("<11", "<20", "43", "55")

  expect_equal(mask_counts(x7), expected7)
})

test_that("mask_counts handles custom threshold", {
  x8 <- c(5, 11, 43, 55)
  expected8 <- c("<20", "<20", "43", "55")

  expect_equal(mask_counts(x8, threshold = 20), expected8)
})

test_that("mask_counts handles large numbers correctly", {
  x9 <- c(5, 1000000, 2000000)
  expected9 <- c("<11", "<1,000,010", "2,000,000")

  expect_equal(mask_counts(x9), expected9)
})

test_that("mask_counts handles input with existing masked values", {
  x10 <- c("<11", "43", "55","0")
  expected10a <- c("<11", "<50", "55","0")
  expected10b <- c("<11", "43", "55","<11")

  expect_equal(mask_counts(x10,zero_masking = FALSE), expected10a)
  expect_equal(mask_counts(x10,zero_masking = TRUE), expected10b)
})
