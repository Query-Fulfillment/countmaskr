# tests/testthat/test-perturb_counts.R

# Assuming that mask_counts() is defined in your package and works as expected.

test_that("perturb_counts returns formatted counts when no small cells", {
  x <- c(15, 20, 30, NA, 0)
  result <- perturb_counts(x)
  expected <- c("15","20","30",NA,"0")
  expect_equal(result, expected)
})

test_that("perturb_counts perturbs counts when there is one small cell", {
  x <- c(5, 20, 30, NA, 0) # 5 is a small cell
  result <- perturb_counts(x, threshold = 10)

  expected <- c("10","18","27",NA,"0")
  expect_equal(result, expected)
})

test_that("perturb_counts coerces to mask counts when multiple small cells", {
  x <- c(5, 7, 30, NA, 0) # Two small cells: 5 and 7

  # Since there are multiple small cells, the function should mask counts
  expected <- c("10","10","22",NA,"0")

  expect_warning(
   result <-  perturb_counts(x, threshold = 10),
    regexp = "Total primary cells: 2. Threshold-based suppression is recommended. See mask_counts() & mask_counts_2()",
    fixed = TRUE
  )
  expect_equal(result,expected)
})

test_that("perturb_counts coerces to mask counts when insufficient counts to distribute noise", {
  x <- c(5, 15, 10, NA, 0) # Non-small cells have minimal counts

  expect_warning(
  result <- perturb_counts(x, threshold = 10),
  regexp = "Required counts for adding noise exceed the available counts in non-small cells. Threshold-based cell suppression coerced.",
  fixed = TRUE
  )
  # The non-small cells do not have enough counts to absorb the noise
  expected <- mask_counts(x)
  expect_equal(result, expected)
})

test_that("perturb_counts coerces to mask counts when proportions change after perturbation", {
  x <- c(1, 15, 15, NA, 0) # One small cell
  # Adjust counts manually to simulate proportions changing
  # For this test, we can assume that proportions will change
  # due to the specific values chosen

  expect_warning(
    result <- perturb_counts(x, threshold = 10),
    regexp = "Perturbing counts changes prior percentages. Threshold-based cell suppression coerced.",
    fixed = TRUE
  )
  # Since proportions change, the function should mask counts
  expected <- mask_counts(x)
  expect_equal(result, expected)
})

test_that("perturb_counts handles non-numeric input by converting to numeric", {
  x <- c("5", "20", "30", NA, "0")
  result <- perturb_counts(x, threshold = 10)

  expected <- c("10","18","27",NA,"0")
  expect_equal(result, expected)
})

test_that("perturb_counts works with zero and negative counts", {
  x <- c(-5, 0, 6, 15, 25)
  result <- perturb_counts(x, threshold = 10)

  expected <- c("-5","0","10","14","22")
    expect_equal(result, expected)
})

test_that("perturb_counts handles all counts below threshold", {
  x <- c(5, 7, 9)

  expect_warning(
    result <- perturb_counts(x, threshold = 10),
    regexp = "All counts are small cells. Threshold-based cell suppression coerced.",
    fixed = TRUE
  )

  # All counts are small cells, so the function should mask counts
  expected <- mask_counts(x)
  expect_equal(result, expected)
})

test_that("perturb_counts returns masked counts when counts are exactly at threshold", {
  x <- c(10, 10, 15)
  result <- perturb_counts(x, threshold = 10)

  # No counts are below threshold, so perturbation is not needed
  expected <- c("10","10","15")
  expect_equal(result, expected)
})

test_that("perturb_counts maintains total count after perturbation", {
  x <- c(5, 20, 30, NA, 0)
  result <- perturb_counts(x, threshold = 10)

  # Sum of original counts
  original_sum <- sum(x, na.rm = TRUE)

  # Sum of perturbed counts
  result_numeric <- extract_digits(result)
  perturbed_sum <- sum(result_numeric, na.rm = TRUE)

  expect_equal(original_sum, perturbed_sum)
})

test_that("perturb_counts handles large counts correctly", {
  x <- c(5, 2000, 3000, NA, 0)
  result <- perturb_counts(x, threshold = 10)

  expected <- c("10","1,998","2,997",NA,"0")
  expect_equal(result, expected)
})
