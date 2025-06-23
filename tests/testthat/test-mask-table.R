library(testthat)
library(tibble)
library(dplyr)

test_that("mask_table basic functionality without grouping", {
  data <- tibble(
    A = c(5, 10, 15, 20),
    B = c(3, 6, 9, 12)
  )

  result <- mask_table(data, threshold = 11, col_groups = c("A", "B"), overwrite_columns = TRUE)

  expect_true(all(result$A == c("<11", "<11", "<20", 20)))
  expect_true(all(result$B == c("<11", "<11", "<11", 12)))
})

test_that("mask_table basic functionality with grouping", {
  data <- tibble(
    group = c("X", "X", "Y", "Y"),
    A = c(5, 10, 15, 20),
    B = c(3, 6, 9, 12)
  )

  result <- mask_table(data, threshold = 11, col_groups = c("A", "B"), group_by = "group", overwrite_columns = FALSE)

  expect_true(all(result$A_masked == c("<11", "<11", "<20", "<30")))
  expect_true(all(result$B_masked == c("<11", "<11", "<11", "<20")))
})

test_that("mask_table handles edge case with all values masked", {
  data <- tibble(
    A = c(1, 2, 3, 4),
    B = c(1, 2, 3, 4)
  )

  result <- mask_table(data, threshold = 5, col_groups = c("A", "B"), overwrite_columns = FALSE)

  expect_true(all(result$A_masked == c("<5", "<5", "<5", "<5")))
  expect_true(all(result$B_masked == c("<5", "<5", "<5", "<5")))
})

test_that("mask_table correctly calculates percentages", {
  data <- tibble(
    A = c(5, 10, 15, 20),
    B = c(3, 6, 9, 12)
  )

  result <- mask_table(data, threshold = 10, col_groups = c("A", "B"), percentages = TRUE)

  expect_true(all(result$A_perc == c(5 / 50 * 100, 10 / 50 * 100, 15 / 50 * 100, 20 / 50 * 100)))
  expect_true(all(result$B_perc == c(3 / 30 * 100, 6 / 30 * 100, 9 / 30 * 100, 12 / 30 * 100)))
})

test_that("mask_table respects overwrite_columns parameter", {
  data <- tibble(
    A = c(5, 10, 15, 20),
    B = c(3, 6, 9, 12)
  )

  result <- mask_table(data, threshold = 11, col_groups = c("A", "B"), overwrite_columns = FALSE)

  expect_true(all(result$A_masked == c("<11", "<11", "<20", 20)))
  expect_true(all(result$B_masked == c("<11", "<11", "<11", 12)))
  expect_true(all(result$A == c(5, 10, 15, 20)))
  expect_true(all(result$B == c(3, 6, 9, 12)))
})
