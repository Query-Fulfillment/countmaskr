#' Perform threshold-based cell masking with primary and secondary masking (Algorithm 1 - A1)
#'
#' @description
#' Identifies primary and secondary cells in a numeric vector and masks them according to the specified threshold.
#'
#' @details
#' The function operates in two main steps: **primary masking** and **secondary masking**.
#'
#' **Primary Masking**:
#' Values greater than 0 and less than the specified \code{threshold} are considered primary cells. These values are masked by replacing them with \code{<threshold}.
#'
#' **Secondary Masking**:
#' Secondary masking is applied to prevent the deduction of masked primary cells from the totals. The logic for identifying the need for secondary masking is based on the following conditions:
#'
#' - **Condition A**: Only one primary masked cell exists, and there are other counts greater than or equal to the threshold.
#' - **Condition B**: Two or more counts of 1 are masked, and there are other counts greater than or equal to the threshold.
#' - **Condition C**: The \code{threshold} is 11, and two or more counts of 10 are masked, and there are other counts greater than or equal to the threshold.
#'
#' If any of these conditions are met, secondary masking is performed as follows:
#'
#' - If \code{zero_masking} is \code{TRUE} and zeros are present in the data, one zero is randomly selected and masked as \code{<threshold}.
#' - If zeros are not to be masked or not present, a non-zero cell is selected for masking based on the \code{secondary_cell} parameter:
#'   - \code{"min"}: The smallest unmasked count greater than zero is selected.
#'   - \code{"max"}: The largest unmasked count is selected.
#'   - \code{"random"}: A random unmasked count is selected.
#'
#' The selected secondary cell is then masked by calculating a new masking threshold using the formula:
#'
#' \deqn{mask\_value = 5 \times \lceil (selected\_value + 1) / 5 \rceil}
#'
#' The formula calculates the masking threshold by first adding 1 to the selected value, then dividing by 5, and rounding up to the nearest whole number. This result is then multiplied by 5 to get the final \code{mask_value}. Essentially, it rounds the selected value up to the next multiple of 5 after incrementing it by 1.
#'
#' The cell is then replaced with \code{<mask_value}.
#'
#' @param x A numeric vector.
#' @param threshold A positive numeric value specifying the threshold below which values must be suppressed. Default is 11.
#' @param zero_masking Logical; if \code{TRUE}, zeros can be masked as secondary cells when present. Default is \code{FALSE}.
#' @param secondary_cell Character string specifying the method for selecting secondary cells when necessary. Options are \code{"min"}, \code{"max"}, or \code{"random"}. Default is \code{"min"}.
#'
#' @return A character vector with primary and/or secondary masked cells.
#'
#' @examples
#' x1 <- c(5, 11, 43, 55, 65, 121, 1213, 0, NA)
#' x2 <- c(1, 1, 1, 55, 65, 121, 1213, 0, NA)
#' x3 <- c(11, 10, 10, 55, 65, 121, 1213, 0, NA)
#'
#' mask_counts(x1)
#' mask_counts(x2)
#' mask_counts(x3)
#'
#' if (requireNamespace("dplyr", quietly = TRUE) && requireNamespace("tidyr", quietly = TRUE)) {
#'   data("countmaskr_data")
#'
#'   aggregate_table <- countmaskr_data %>%
#'     dplyr::select(-c(id, age)) %>%
#'     tidyr::gather(block, Characteristics) %>%
#'     dplyr::group_by(block, Characteristics) %>%
#'     dplyr::summarise(N = dplyr::n()) %>%
#'     dplyr::ungroup()
#'
#'   aggregate_table %>%
#'     dplyr::group_by(block) %>%
#'     dplyr::mutate(N_masked = mask_counts(N))
#' }
#'
#' @export
mask_counts <- function(x, threshold = 11, zero_masking = FALSE, secondary_cell = "min") {
  # Input validation
  if (!is.numeric(threshold) || length(threshold) != 1 || threshold <= 0) {
    stop("Argument 'threshold' must be a positive numeric value.")
  }
  if (!is.logical(zero_masking) || length(zero_masking) != 1) {
    stop("Argument 'zero_masking' must be a logical value (TRUE or FALSE).")
  }
  if (!secondary_cell %in% c("min", "max", "random")) {
    stop("Argument 'secondary_cell' must be 'min', 'max', or 'random'.")
  }

  # Disable scientific notation temporarily
  original_options <- options(scipen = 999)
  on.exit(options(original_options), add = TRUE)

  # Initialize masked counts
  x_m <- x

  # Apply primary masking (mask counts > 0 and < threshold)
  if (sum(grepl("<", x)) == 0) {
    if (!is.numeric(x)) {
      x <- extract_digits(x)
    }
    x_m <-
      ifelse(x > 0 &
               x < threshold,
             paste0("<", threshold),
             gsub(" ", "", paste0(format(
               x,
               digits = 1, big.mark = ","
             )))
      )
  } else {
    x_m <- x
  }

  # Determine if secondary masking should be applied
  # Condition A: Only one primary masked cell exists
  condition_a <- sum(grepl("<", x_m)) == 1 &&
    sum(!grepl("<", x_m) & extract_digits(x_m) >= threshold, na.rm = TRUE) > 0

  # Condition B: Two or more counts of 1 are masked
  condition_b <- sum(x == 1, na.rm = TRUE) >= 2 &&
    sum(grepl("<", x_m), na.rm = TRUE) == sum(x == 1, na.rm = TRUE) &&
    sum(!grepl("<", x_m) & extract_digits(x_m) >= threshold, na.rm = TRUE) > 0

  # Condition C: Threshold is 11 and two or more counts of 10 are masked
  condition_c <- threshold == 11 &&
    sum(x == 10, na.rm = TRUE) >= 2 &&
    sum(grepl("<", x_m), na.rm = TRUE) == sum(x == 10, na.rm = TRUE) &&
    sum(!grepl("<", x_m) & extract_digits(x_m) >= threshold, na.rm = TRUE) > 0

  # Check if secondary masking is needed
  if (condition_a || condition_b || condition_c) {
    if (zero_masking && any(x == 0, na.rm = TRUE)) {
      # Mask one zero as <threshold
      zero_indices <- which(x == 0)
      x_m[zero_indices[1]] <- paste0("<", threshold)
    } else {
      # Mask a non-zero cell based on secondary_cell parameter
      # Exclude zeros and NAs from unmasked counts for secondary selection
      unmasked_counts <- extract_digits(x_m)[
        !grepl("<", x_m) & !is.na(extract_digits(x_m)) & extract_digits(x_m) != 0
      ]
      if (length(unmasked_counts) > 0) {
        # Select the count for secondary masking based on secondary_cell
        if (secondary_cell == "min") {
          selected_value <- min(unmasked_counts[unmasked_counts > 0], na.rm = TRUE)
        } else if (secondary_cell == "max") {
          selected_value <- max(unmasked_counts, na.rm = TRUE)
        } else if (secondary_cell == "random") {
          selected_value <- sample(unmasked_counts, 1)
        }

        # Calculate the masking threshold for the selected value
        mask_value <- 5 * ceiling((selected_value + 1) / 5)
        mask_label <- paste0("<", format(mask_value, big.mark = ",", trim = TRUE))

        # Apply secondary masking to the first occurrence of the selected value
        index_to_mask <- which(
          extract_digits(x_m) == selected_value &
            !grepl("<", x_m)
        )[1]
        x_m[index_to_mask] <- mask_label
      }
    }
  }

  # Replace NAs with NA_character_ to maintain consistency
  x_m[is.na(x)] <- NA_character_

  return(x_m)
}
