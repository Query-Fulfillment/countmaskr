#' Perturb Counts in a Vector with Small Cells
#'
#' `r lifecycle::badge("experimental")`
#'
#' @description
#' The `perturb_counts` function perturbs counts in a numeric vector containing small cells, specifically when only one primary cell is present and secondary cells need to be masked, following Algorithm 3 (A3). The function adjusts the counts by distributing noise to non-primary cells while preserving the overall distribution as much as possible.
#'
#' @details
#' **Perturbation Process Overview:**
#'
#' The function performs perturbation through the following steps:
#'
#' 1. **Identification of Small Cells**: Cells with counts greater than 0 and less than the specified `threshold` are identified as small cells (primary cells).
#'
#'    \deqn{\text{Small Cells} = \{ i \mid 0 < x_i < \text{threshold} \}}
#'
#' 2. **Adjustment of Small Cells**: The counts of small cells are set to the `threshold` value.
#'
#'    \deqn{x'_i = \left\{
#'      \begin{array}{ll}
#'        \text{threshold} & \text{if } x_i \text{ is a small cell} \\
#'        x_i & \text{otherwise}
#'      \end{array}
#'    \right.}
#'
#' 3. **Calculation of Total Noise**: The total noise to be distributed is calculated as the difference between the original total sum and the adjusted sum.
#'
#'    \deqn{\text{Total Noise} = \sum_{i=1}^{N} x_i - \sum_{i=1}^{N} x'_i}
#'
#' 4. **Distribution of Noise to Non-Small Cells**: The total noise is proportionally distributed to the non-small cells based on their original counts.
#'
#'    - **Weights Calculation**:
#'      \deqn{w_i = \frac{x_i}{\sum_{j \in \text{Non-Small Cells}} x_j}}
#'
#'    - **Noise Allocation**:
#'      \deqn{\text{Noise}_i = w_i \times \text{Total Noise}}
#'
#'    - **Adjusted Counts**:
#'      \deqn{x''_i = x'_i + \text{Noise}_i}
#'
#' 5. **Rounding Adjusted Counts**: The adjusted counts are rounded to the nearest integer.
#'
#'    \deqn{x'''_i = \text{round}(x''_i)}
#'
#' 6. **Adjustment for Rounding Discrepancies**: Any remaining noise due to rounding discrepancies is adjusted by iteratively adding or subtracting 1 from the largest counts until the total counts are balanced, ensuring that no count falls below the `threshold`.
#'
#' 7. **Verification of Proportions**: The function checks if the proportions of the non-small cells remain consistent before and after perturbation. If the proportions differ, the function coerces to mask counts using the [mask_counts()] function.
#'
#' **Coercion to Mask Counts:**
#'
#' The function coerces to mask counts in the following scenarios:
#'
#' - **Multiple Small Cells Detected**: If more than one small cell is identified, perturbation may not be necessary unless intended to use. The function will still proceed with perturbation but recommends using threshold-based suppression.
#'
#' - **Insufficient Available Counts**: If the non-small cells do not have enough counts to absorb the total noise without any count falling below the `threshold`, the operation will lead to information loss.
#'
#' - **Proportions Changed After Perturbation**: If perturbation alters the original proportions of the non-small cells, the operation will lead to information loss.
#'
#' #' - **All Counts Below Threshold**: If all counts in the vector are below the specified `threshold`, there is no meaningful perturbation possible. In this case, the function coerces to `mask_counts()` as a more secure alternative.
#'
#' In these cases, the function calls [mask_counts()] to apply threshold-based cell suppression as a more secure alternative.
#'
#' @param x Numeric vector of length N containing counts.
#' @param threshold Numeric value specifying the threshold for small cells (primary cells). Defaults to 10.
#'
#' @return A character vector with perturbed counts formatted with digit precision and thousands separator. If perturbation is not feasible, the function returns counts masked using [mask_counts()].
#'
#' @examples
#' # Example vectors
#' x1 <- c(5, 11, 43, 55, 65, 121, 1213, 0, NA)
#' x2 <- c(1, 1, 1, 55, 65, 121, 1213, 0, NA)
#' x3 <- c(11, 10, 10, 55, 65, 121, 1213, 0, NA)
#'
#' # Apply the function
#' lapply(list(x1, x2, x3), perturb_counts)
#'
#' # Using the function within a data frame
#' data("countmaskr_data")
#' aggregate_table <- countmaskr_data %>%
#'   select(-c(id, age)) %>%
#'   tidyr::gather(block, Characteristics) %>%
#'   group_by(block, Characteristics) %>%
#'   summarise(N = n()) %>%
#'   ungroup()
#'
#' aggregate_table %>%
#'   group_by(block) %>%
#'   mutate(N_masked = perturb_counts(N))
#'
#' @export
perturb_counts <- function(x, threshold = 10) {
  # Disable scientific notation temporarily
  original_options <- options(scipen = 999)
  on.exit(options(original_options), add = TRUE)

  # Convert x to numeric if necessary
  if (!is.numeric(x)) {
    x_numeric <- as.numeric(gsub("[^0-9.-]", "", x))
  } else {
    x_numeric <- x
  }

  # Identify small cells
  small_cells <- which(x_numeric > 0 & x_numeric < threshold)

  # If no small cells, return formatted x
  if (length(small_cells) == 0) {
    return(format_cells(x_numeric))
  }

  # If all small cells,  issue a warning and mask using mask_counts()
  if (length(small_cells) == length(x_numeric)) {
    warning(paste0("All counts are small cells. Threshold-based cell suppression coerced."))
    return(mask_counts(x_numeric))
  }

  # If more than one small cell, issue a warning
  if (length(small_cells) > 1) {
    warning(paste0("Total primary cells: ", length(small_cells), ". Threshold-based suppression is recommended. See mask_counts() & mask_counts_2()"))
  }

  # Create a copy of x_numeric and set small cells to the threshold
  x_modified <- x_numeric
  x_modified[small_cells] <- threshold

  # Calculate total noise to distribute
  total_noise <- sum(x_numeric, na.rm = TRUE) - sum(x_modified, na.rm = TRUE)

  # Identify non-small cells (cells greater than or equal to the threshold)
  non_small_cells <- which(x_modified >= threshold & !is.na(x_modified))

  # Exclude small cells from non-small cells
  non_small_cells <- setdiff(non_small_cells, small_cells)

  # Calculate available counts before exhausting all cells
  available_counts <- sum(x_modified[non_small_cells], na.rm = TRUE) - threshold * length(non_small_cells)

  # Check if there are enough counts to distribute the noise
  if (available_counts <= abs(total_noise)) {
    warning("Required counts for adding noise exceed the available counts in non-small cells. Threshold-based cell suppression coerced.")
    x_masked <- mask_counts(x_numeric)  # Ensure mask_counts() is defined
    return(x_masked)
  }

  if (length(non_small_cells) > 0) {
    # Compute weights for noise distribution
    weights <- x_numeric[non_small_cells] / sum(x_numeric[non_small_cells], na.rm = TRUE)
    weighted_noise <- total_noise * weights

    # Distribute the weighted noise
    x_modified[non_small_cells] <- x_modified[non_small_cells] + weighted_noise
    x_modified <- round(x_modified)

    # Adjust for any rounding discrepancies
    remaining_noise <- sum(x_numeric, na.rm = TRUE) - sum(x_modified, na.rm = TRUE)
    if (remaining_noise != 0) {
      sorted_indices <- order(-x_modified[non_small_cells])
      for (i in seq_along(sorted_indices)) {
        idx <- non_small_cells[sorted_indices[i]]
        if (remaining_noise == 0) break
        adjustment <- sign(remaining_noise)
        if (x_modified[idx] + adjustment >= threshold) {
          x_modified[idx] <- x_modified[idx] + adjustment
          remaining_noise <- remaining_noise - adjustment
        }
      }
    }

    # Verify if proportions are maintained
    original_props <- round(x_numeric[-small_cells] / sum(x_numeric[-small_cells], na.rm = TRUE), digits = 0)
    modified_props <- round(x_modified[-small_cells] / sum(x_modified[-small_cells], na.rm = TRUE), digits = 0)

    if (all(original_props == modified_props, na.rm = TRUE)) {
      return(format_cells(x_modified))
    } else {
      warning("Perturbing counts changes prior percentages. Threshold-based cell suppression coerced.")
      x_masked <- mask_counts(x_numeric)
      return(x_masked)
    }
  }
}
