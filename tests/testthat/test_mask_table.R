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

  expect_true(all(result$A_masked == c("<11", "<11", "<20", "<25")))
  expect_true(all(result$B_masked == c("<11", "<11", "<11", "<15")))
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

  result <- mask_table(data, threshold = 10, col_groups = c("A", "B"),overwrite_columns = FALSE, percentages = TRUE)

  expect_true(all(result$A_perc == paste0(c(5 / 50 * 100, 10 / 50 * 100, 15 / 50 * 100, 20 / 50 * 100)," %")))
  expect_true(all(result$B_perc == paste0(c(5 / 50 * 100, 10 / 50 * 100, 15 / 50 * 100, 20 / 50 * 100)," %")))
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

# ── Boundary-percentage correction tests ─────────────────────────────────────
# These tests cover the three cases triggered by small/large rounding artefacts,
# and verify the behaviour is consistent across perc_decimal = 0, 1, and 2.

test_that("perc_decimal=0: primary masked cell whose threshold-% rounds to 0 shows <1 %", {
  # count=3, total=3000 -> masked threshold=11 -> 11/3000*100=0.37% -> rounds to 0%
  # Overrides "masked cell" because the underlying count is non-zero
  data <- tibble(A = c(3, 2997))
  result <- mask_table(data, threshold = 11, col_groups = "A",
                       percentages = TRUE, perc_decimal = 0)
  expect_equal(result$A_perc_masked[1], "<1 %")
})

test_that("perc_decimal=0: secondary masked cell whose threshold-% rounds to 100 shows >99 %", {
  # A = c(5, 15), total = 20
  # A[1]=5  -> primary masked <11 -> "masked cell"
  # A[2]=15 -> secondary masked <20 (5*ceil(16/5)=20)
  # masked_percentage[2] = 20/20*100 = 100%; unrounded original = 75% -> triggers <99 %
  data <- tibble(A = c(5, 15))
  result <- mask_table(data, threshold = 11, col_groups = "A",
                       percentages = TRUE, perc_decimal = 0)
  expect_equal(result$A_perc_masked[1], "masked cell")
  expect_equal(result$A_perc_masked[2], ">99 %")
})

test_that("perc_decimal=0: cell that is genuinely 100% stays as 100 %", {
  # A[2]=100/100 -> unrounded original IS 100%, no override should happen
  data <- tibble(A = c(0, 100))
  result <- mask_table(data, threshold = 11, col_groups = "A",
                       percentages = TRUE, perc_decimal = 0)
  expect_equal(result$A_perc_masked[2], "100 %")
})

test_that("perc_decimal=1: threshold-% rounding to 0.0 shows <0.1 %", {
  # count=3, total=30000 -> threshold=11 -> 11/30000*100=0.037% -> rounds to 0.0%
  data <- tibble(A = c(3, 29997))
  result <- mask_table(data, threshold = 11, col_groups = "A",
                       percentages = TRUE, perc_decimal = 1)
  expect_equal(result$A_perc_masked[1], "<0.1 %")
})

test_that("perc_decimal=1: secondary-masked percentage rounding to 100.0 shows >99.9 %", {
  # Same c(5,15) scenario; unrounded original 75% is still not 100%
  data <- tibble(A = c(5, 15))
  result <- mask_table(data, threshold = 11, col_groups = "A",
                       percentages = TRUE, perc_decimal = 1)
  expect_equal(result$A_perc_masked[2], ">99.9 %")
})

test_that("perc_decimal=2: threshold-% rounding to 0.00 shows <0.01 %", {
  # count=3, total=3000000 -> 11/3000000*100=0.00037% -> rounds to 0.00%
  data <- tibble(A = c(3, 2999997))
  result <- mask_table(data, threshold = 11, col_groups = "A",
                       percentages = TRUE, perc_decimal = 2)
  expect_equal(result$A_perc_masked[1], "<0.01 %")
})

test_that("perc_decimal=2: secondary-masked percentage rounding to 100.00 shows >99.99 %", {
  data <- tibble(A = c(5, 15))
  result <- mask_table(data, threshold = 11, col_groups = "A",
                       percentages = TRUE, perc_decimal = 2)
  expect_equal(result$A_perc_masked[2], ">99.99 %")

  result2 <- mask_table(data, threshold = 11, col_groups = "A",
                       percentages = TRUE, perc_decimal = 0)
  expect_equal(result2$A_perc_masked[2], ">99 %")
})

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

  expect_true(all(result$A_masked == c("<11", "<11", "<20", "<25")))
  expect_true(all(result$B_masked == c("<11", "<11", "<11", "<15")))
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

  expect_true(all(result$A_perc == c("10 %","20 %","30 %","40 %")))
  expect_true(all(result$B_perc == c("10 %","20 %","30 %","40 %")))

  expect_true(all(result$A_perc_masked == c("masked cell","<30 %","<40 %","40 %")))
  expect_true(all(result$B_perc_masked == c("masked cell","masked cell","masked cell","40 %")))

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
