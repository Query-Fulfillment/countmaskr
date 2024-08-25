library(testthat)
library(dplyr)
library(tidyr)

# Test cases for mask_counts function

test_that("mask_counts handles basic cases correctly", {
  x1 <- c(5, 11, 43, 55, 65, 121, 1213, 0, NA)
  expected1 <- c("<11", "11", "43", "55", "65", "121", ">1,207", "0", NA)

  expect_equal(mask_counts_2(x1), expected1)
})

test_that("mask_counts handles all values below threshold", {
  x2 <- c(1, 1, 1, 5, 6, 10, 0, NA)
  expected2 <- c("<11", "<11", "<11", "<11", "<11", "<11", "0", "NA")

  expect_equal(mask_counts_2(x2), expected2)
})

test_that("mask_counts handles secondary masking with one primary cell", {
  x3 <- c(5, 12, 43, 55)
  expected3 <- c("<11", "12", "43", ">49")

  expect_equal(mask_counts_2(x3), expected3)
})

test_that("mask_counts handles secondary masking with two primary cells equal to 1", {
  x4 <- c(1, 1, 43, 55)
  expected4 <- c("<11", "<11", "43", "55")

  expect_equal(mask_counts_2(x4), expected4)
})

test_that("mask_counts handles secondary masking with two primary cells equal to 10", {
  x5 <- c(10, 10, 43, 55)
  expected5 <- c("<11", "<11", "43", "55")

  expect_equal(mask_counts_2(x5), expected5)
})

test_that("mask_counts handles character input", {
  x6 <- c("5", "11", "43", "55")
  expected6 <- c("<11", "11", "43", ">49")

  expect_equal(mask_counts_2(x6), expected6)
})

test_that("mask_counts handles mixed numeric and character input", {
  x7 <- c(5, "11", 43, "55")
  expected7 <- c("<11", "11", "43", ">49")

  expect_equal(mask_counts_2(x7), expected7)
})

test_that("mask_counts handles custom threshold", {
  x8 <- c(5, 11, 43, 55)
  expected8 <- c("<20", "<20", "43", "55")

  expect_equal(mask_counts(x8, threshold = 20), expected8)
})

test_that("mask_counts handles large numbers correctly", {
  x9 <- c(5, 1000000, 2000000)
  expected9 <- c("<11", "1,000,000", ">1,999,994")

  expect_equal(mask_counts_2(x9), expected9)
})
