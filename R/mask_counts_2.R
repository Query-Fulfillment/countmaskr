#' Perform threshold-based cell masking with primary and secondary masking  (Algorithm 2 - A2)
#'
#' @description
#' This function masks values in a numeric vector based on a specified threshold, using primary and secondary masking to ensure data privacy.
#'
#' @details
#' The function operates in two main steps:
#'
#' - **Primary Masking**: Values greater than 0 but less than the threshold are masked by replacing them with \code{<threshold}.
#' - **Secondary Masking**: Applied when additional masking is required to prevent deduction of masked cells from totals. Secondary masking is triggered under the following conditions:
#'   - **Condition A**: A single primary masked cell exists, and there are other values that meet or exceed the threshold.
#'   - **Condition B**: Two or more counts of 1 are masked, with other values meeting or exceeding the threshold.
#'   - **Condition C**: The threshold is set to 11, with two or more counts of 10 masked and other counts meeting or exceeding the threshold.
#'
#' If any of these conditions are met:
#' - When \code{zero_masking = TRUE} and zeros are present, one zero is randomly selected and masked as \code{<threshold}.
#' - When \code{zero_masking = FALSE} (or zeros are absent), the function masks the largest unmasked count (i.e., the maximum non-zero value).
#'
#' **Formula for Mask Value Calculation**:
#' To calculate the \code{mask_value} for the secondary cell, the following formula is used:
#' \deqn{mask\_value = selected\_value - (threshold - totals\_of\_small\_cells)}
#'
#' In words, this formula subtracts the difference between the threshold and the sum of all small cells (those masked in the primary masking step) from the selected maximum unmasked value. This adjusted \code{mask_value} helps ensure privacy while retaining consistent totals.
#'
#' @param x Numeric vector to mask.
#' @param threshold Positive numeric value for the threshold below which cells are masked. Default is 11.
#' @param zero_masking Logical; if \code{TRUE}, zeros may be masked as secondary cells if present. Default is \code{FALSE}.
#'
#' @return A character vector with masked cells, retaining \code{NA} as \code{NA_character_}.
#'
#' @examples
#' x1 <- c(5, 11, 43, 55, 65, 121, 1213, 0, NA)
#'
#' mask_counts_2(x1)
#'
#' if (requireNamespace("dplyr", quietly = TRUE) && requireNamespace("tidyr", quietly = TRUE)) {
#'   data("countmaskr_data")
#'   countmaskr_data %>%
#'     dplyr::select(-c(id, age)) %>%
#'     tidyr::gather(block, Characteristics) %>%
#'     dplyr::group_by(block, Characteristics) %>%
#'     dplyr::summarise(N = dplyr::n()) %>%
#'     dplyr::ungroup() %>%
#'     dplyr::mutate(N_masked = mask_counts_2(N))
#' }
#' @export

mask_counts_2 <- function(x, threshold = 11, zero_masking = FALSE) {
  # Input validation
  if (!is.numeric(threshold) || length(threshold) != 1 || threshold <= 0) {
    stop("Argument 'threshold' must be a positive numeric value.")
  }
  if (!is.logical(zero_masking) || length(zero_masking) != 1) {
    stop("Argument 'zero_masking' must be a logical value (TRUE or FALSE).")
  }

  # Disable scientific notation temporarily
  original_options <- options(scipen = 999)
  on.exit(options(original_options), add = TRUE)

  # Apply primary masking (mask counts > 0 and < threshold)
  x_numeric <- x
  if (!is.numeric(x)) {
    x_numeric <- extract_digits(x)
  }
  x_m <- ifelse(
    x_numeric > 0 & x_numeric < threshold,
    paste0("<", threshold),
    format(x_numeric, digits = 1, big.mark = ",", trim = TRUE)
  )

  # Identify primary masked indices
  primary_masked <- grepl("^<", x_m)

  # Determine if secondary masking should be applied
  counts_numeric <- extract_digits(x_m)
  unmasked_counts <- counts_numeric[!primary_masked & !is.na(counts_numeric)]

  condition_a <- sum(primary_masked, na.rm = TRUE) == 1 && length(unmasked_counts[unmasked_counts >= threshold]) > 0

  condition_b <- sum(x_numeric == 1, na.rm = TRUE) >= 2 &&
    sum(primary_masked, na.rm = TRUE) == sum(x_numeric == 1, na.rm = TRUE) &&
    length(unmasked_counts[unmasked_counts >= threshold]) > 0

  condition_c <- threshold == 11 &&
    sum(x_numeric == 10, na.rm = TRUE) >= 2 &&
    sum(primary_masked, na.rm = TRUE) == sum(x_numeric == 10, na.rm = TRUE) &&
    length(unmasked_counts[unmasked_counts >= threshold]) > 0

  # Check if secondary masking is needed
  if (condition_a || condition_b || condition_c) {
    if (zero_masking && any(x_numeric == 0, na.rm = TRUE)) {
      # Mask one zero as <threshold
      zero_indices <- which(x_numeric == 0)
      x_m[zero_indices[1]] <- paste0("<", threshold)
    } else {
      # Mask a non-zero cell
      small_cells <- x_numeric[x_numeric > 0 & x_numeric < threshold]
      difference <- sum(threshold - small_cells, na.rm = TRUE)

      if (length(unmasked_counts) > 0) {
        selected_value <- max(unmasked_counts, na.rm = TRUE)

        mask_value <- selected_value - difference

        mask_label <- paste0(">", format(mask_value, digits = 1, big.mark = ",", trim = TRUE))

        mask_label <- ifelse(extract_digits(mask_label) < threshold, paste0(">", threshold), mask_label)

        # Apply secondary masking to the first occurrence of the selected value
        index_to_mask <- which(
          !primary_masked & counts_numeric == selected_value
        )[1]
        x_m[index_to_mask] <- mask_label
      }
    }
  }

  # Replace NAs with NA_character_ to maintain consistency
  x_m[is.na(x)] <- NA_character_

  return(x_m)
}
