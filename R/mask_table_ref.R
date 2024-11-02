#' Apply Threshold-Based Masking to a Data Frame
#'
#' @description
#' The `mask_table` function applies threshold-based masking to specified columns in a data frame.
#' It uses the `mask_counts` function to mask counts that are below a certain threshold, adhering
#' to data privacy requirements. The function can handle grouped data and calculate percentages if required.
#' It ensures convergence by checking specific criteria after each iteration.
#'
#' @param data A data frame containing the counts to be masked. Must be a data frame.
#' @param threshold A positive numeric value specifying the threshold below which values must be suppressed. Default is 11.
#' @param col_groups A character vector or a list of character vectors, where each character vector specifies columns in `data` to which masking should be applied.
#' @param group_by An optional character string specifying a column name in `data` to group the data by before masking.
#' @param overwrite_columns Logical; if `TRUE`, the original columns are overwritten with masked counts. If `FALSE`, new columns are added with masked counts. Default is `TRUE`.
#' @param percentages Logical; if `TRUE`, percentages are calculated and masked accordingly. Default is `FALSE`.
#' @param zero_masking Logical; if `TRUE`, zeros can be masked as secondary cells when present. Passed to `mask_counts`. Default is `FALSE`.
#' @param secondary_cell Character string specifying the method for selecting secondary cells when necessary. Options are `"min"`, `"max"`, or `"random"`. Passed to `mask_counts`. Default is `"min"`.
#' @param .verbose Logical; if `TRUE`, progress messages are printed during masking. Default is `FALSE`.
#'
#' @return A data frame with masked counts in specified columns. If `percentages = TRUE`, additional columns with percentages are added. The structure of the returned data frame depends on the `overwrite_columns` parameter.
#'
#' @examples
#' data <- data.frame(
#'   group = rep(letters[1:3], each = 5),
#'   count1 = c(5, 10, 15, 20, 25, 2, 4, 6, 8, 10, 1, 3, 5, 7, 9),
#'   count2 = c(3, 6, 9, 12, 15, 1, 2, 3, 4, 5, 11, 13, 15, 17, 19)
#' )
#'
#' masked_data <- mask_table(
#'   data = data,
#'   threshold = 11,
#'   col_groups = c("count1", "count2"),
#'   group_by = "group",
#'   overwrite_columns = TRUE,
#'   percentages = TRUE,
#'   zero_masking = FALSE,
#'   secondary_cell = "min",
#'   .verbose = TRUE
#' )
#'
#' @seealso \code{\link{mask_counts}}
#' @importFrom tibble tibble
#' @importFrom dplyr bind_rows
#' @export
mask_table <- function(data,
                       threshold = 11,
                       col_groups,
                       group_by = NULL,
                       overwrite_columns = TRUE,
                       percentages = FALSE,
                       zero_masking = FALSE,
                       secondary_cell = "min",
                       .verbose = FALSE) {
  # Input validation
  if (!is.data.frame(data)) {
    stop("Argument 'data' must be a data frame.")
  }
  if (!is.numeric(threshold) || length(threshold) != 1 || threshold <= 0) {
    stop("Argument 'threshold' must be a positive numeric value.")
  }
  if (!is.logical(overwrite_columns) || length(overwrite_columns) != 1) {
    stop("Argument 'overwrite_columns' must be a logical value (TRUE or FALSE).")
  }
  if (!is.logical(percentages) || length(percentages) != 1) {
    stop("Argument 'percentages' must be a logical value (TRUE or FALSE).")
  }
  if (!is.logical(zero_masking) || length(zero_masking) != 1) {
    stop("Argument 'zero_masking' must be a logical value (TRUE or FALSE).")
  }
  if (!secondary_cell %in% c("min", "max", "random")) {
    stop("Argument 'secondary_cell' must be 'min', 'max', or 'random'.")
  }
  if (!is.logical(.verbose) || length(.verbose) != 1) {
    stop("Argument '.verbose' must be a logical value (TRUE or FALSE).")
  }

  # Validate 'group_by'
  if (!is.null(group_by)) {
    if (!is.character(group_by) || length(group_by) != 1 || !group_by %in% names(data)) {
      stop("Argument 'group_by' must be a single column name present in 'data'.")
    }
  }

  # Ensure col_groups is a list of vectors of column names
  if (!is.list(col_groups)) {
    if (!is.character(col_groups)) {
      stop("Argument 'col_groups' must be a character vector or a list of character vectors.")
    }
    col_groups <- list(col_groups)
  }

  # Check if all columns in 'col_groups' exist in 'data'
  all_col_groups <- unique(unlist(col_groups))
  if (!all(all_col_groups %in% names(data))) {
    missing_cols <- all_col_groups[!all_col_groups %in% names(data)]
    stop(paste("Some columns in 'col_groups' do not exist in 'data':", paste(missing_cols, collapse = ", ")))
  }

  # Helper function to extract numeric digits from strings
  extract_digits <- function(values) {
    # Identify which values are NA
    is_na <- is.na(values)

    # For non-NA values, apply the pattern matching
    non_na_values <- values[!is_na]

    # Define the allowed pattern: optional '<', optional '-', digits, optional '.', digits
    allowed_pattern <- "^<?-?[0-9]*\\.?[0-9]+$"

    # Check for disallowed characters or invalid formats in non-NA values
    if (any(!grepl(allowed_pattern, non_na_values))) {
      stop("Error: Values contain disallowed characters or invalid format.")
    }

    # Remove the '<' symbol if it's present at the start in non-NA values
    numeric_strings <- rep(NA_character_, length(values))
    numeric_strings[!is_na] <- gsub("^<", "", non_na_values)

    # Convert the cleaned strings to numeric
    numeric_values <- as.numeric(numeric_strings)

    # Check if any non-NA values could not be converted to numeric
    if (any(is.na(numeric_values[!is_na]))) {
      stop("Error: Some values could not be converted to numeric.")
    }

    return(numeric_values)
  }

  # Split data into blocks if group_by is specified
  if (!is.null(group_by)) {
    data_blocks <- split(data, data[[group_by]])
  } else {
    data_blocks <- list(data)
  }

  # Initialize list to store masked data blocks
  masked_blocks <- list()

  # Loop over each block
  for (block_name in seq_along(data_blocks)) {
    block_data <- data_blocks[[block_name]]

    if (isTRUE(.verbose)) {
      message(paste0("Starting masking for block: ", block_name))
    }

    # Loop over each group in col_groups
    for (group in col_groups) {
      if (!all(group %in% names(block_data))) {
        stop(paste("Some columns in 'col_groups' do not exist in the data block:", paste(group, collapse = ", ")))
      }

      if (isTRUE(.verbose)) {
        message(paste0("Masking columns: ", paste(group, collapse = ", ")))
      }

      # Extract the counts for the current group
      original_counts <- block_data[, group, drop = FALSE]

      # Initialize masked_counts
      masked_counts <- original_counts

      # Start the repeat loop for masking
      repeat {
        if (isTRUE(.verbose)) {
          message("Applying mask_counts across columns...")
        }

        # Apply mask_counts across columns
        across_column_mask <- apply(
          masked_counts,
          MARGIN = 2,
          mask_counts,
          threshold = threshold,
          zero_masking = zero_masking,
          secondary_cell = secondary_cell
        )

        # Ensure the result is a data frame
        across_column_mask <- data.frame(across_column_mask, check.names = FALSE)

        if (isTRUE(.verbose)) {
          message("Applying mask_counts across rows...")
        }

        # Apply mask_counts across rows
        across_row_mask <- t(apply(
          across_column_mask,
          MARGIN = 1,
          mask_counts,
          threshold = threshold,
          zero_masking = zero_masking,
          secondary_cell = secondary_cell
        ))

        # Convert to data frame
        across_row_mask <- data.frame(across_row_mask, check.names = FALSE)
        colnames(across_row_mask) <- colnames(masked_counts)

        masked_counts <- across_row_mask

        # Check convergence criteria
        if (nrow(masked_counts) >= 1) {
          # Calculate total masked cells per column
          total_masked_cells <- colSums(apply(masked_counts, 2, function(col) grepl("<", col)))
          # Calculate total available (unmasked) cells per column
          total_available_cells <- colSums(apply(masked_counts, 2, function(col) !grepl("<", col)))
          # Calculate total zeros per column
          total_zeros <- colSums(apply(masked_counts, 2, function(col) col == "0" | is.na(col)))

          # Check if convergence criteria are met
          if ((nrow(masked_counts) == 1) ||
              (any(total_masked_cells == 1) &&
               all(total_available_cells[total_masked_cells == 1] == total_zeros[total_masked_cells == 1])) ||
              (!any(total_masked_cells == 1))) {
            if (isTRUE(.verbose)) {
              message("Convergence criteria met. Exiting loop.")
            }

            # Overwrite or add masked counts to block_data
            if (isTRUE(overwrite_columns)) {
              block_data[, group] <- masked_counts
            } else {
              masked_colnames <- paste0(group, "_masked")
              block_data[, masked_colnames] <- masked_counts
            }
            break # Exit the repeat loop
          } else {
            if (isTRUE(.verbose)) {
              message("Convergence criteria not met. Repeating masking process.")
            }
            # Continue to the next iteration with updated masked_counts
          }
        } else {
          # No data to process, break the loop
          if (isTRUE(.verbose)) {
            message("No data to process. Exiting loop.")
          }
          break
        }
      }

      # Handle percentages if required
      if (isTRUE(percentages)) {
        if (isTRUE(.verbose)) {
          message("Calculating percentages...")
        }

        # Convert counts to numeric
        original_counts_numeric <- data.frame(lapply(original_counts, extract_digits), check.names = FALSE)
        masked_counts_numeric <- data.frame(lapply(masked_counts, extract_digits), check.names = FALSE)

        # Calculate original totals
        original_totals <- colSums(original_counts_numeric, na.rm = TRUE)

        # Avoid division by zero
        original_totals[original_totals == 0] <- NA

        # Calculate original percentages
        original_percentages <- sweep(original_counts_numeric, 2, original_totals, FUN = "/") * 100
        original_percentages <- round(original_percentages, digits = 0)

        # Create original percentages data frame with suffix '_perc'
        original_percentages_char <- matrix(NA_character_, nrow = nrow(original_percentages), ncol = ncol(original_percentages))
        colnames(original_percentages_char) <- paste0(colnames(original_counts), "_perc")

        # Assign original percentages
        original_percentages_char[!is.na(original_percentages)] <- paste0(original_percentages[!is.na(original_percentages)], " %")
        original_percentages_char[is.na(original_percentages)] <- NA_character_

        # Convert to data frame
        original_percentages_df <- data.frame(original_percentages_char, check.names = FALSE)

        # Now handle masked percentages
        # Calculate masked percentages
        masked_percentages <- sweep(masked_counts_numeric, 2, original_totals, FUN = "/") * 100
        masked_percentages <- round(masked_percentages, digits = 0)

        # Initialize masked_percentages_char with appropriate dimensions and names
        masked_percentages_char <- matrix(NA_character_, nrow = nrow(masked_percentages), ncol = ncol(masked_percentages))
        colnames(masked_percentages_char) <- paste0(colnames(masked_counts), "_perc_masked")

        # Create logical matrices for conditions
        is_masked_sec_cell <- as.matrix(apply(masked_counts, 2, function(col) grepl("<", col) & !grepl(paste0("<", threshold), col)))
        is_small_cell <- as.matrix(apply(masked_counts, 2, function(col) grepl(paste0("<", threshold), col)))
        is_na_cell <- is.na(masked_counts_numeric)

        # Assign masked percentages
        masked_percentages_char[is_masked_sec_cell] <- paste0("<", masked_percentages[is_masked_sec_cell], " %")
        masked_percentages_char[is_small_cell] <- "masked cell"

        # Assign unmasked percentages
        masked_percentages_char[!is_masked_sec_cell & !is_na_cell & !is_small_cell] <- paste0(masked_percentages[!is_masked_sec_cell & !is_na_cell & !is_small_cell], " %")
        masked_percentages_char[!is_masked_sec_cell & !is_small_cell & is_na_cell] <- NA_character_

        # Convert to data frame
        masked_percentages_df <- as.data.frame(masked_percentages_char, check.names = FALSE)

        # Add original and masked percentages to block_data
        if (isTRUE(overwrite_columns)) {
          block_data <- cbind(block_data, masked_percentages_df)
        } else {
          block_data <- cbind(block_data, original_percentages_df, masked_percentages_df)
        }
      }

      # Overwrite or add masked counts to block_data (if not already done)
      if (!isTRUE(overwrite_columns)) {
        masked_colnames <- paste0(group, "_masked")
        block_data[, masked_colnames] <- masked_counts
      }
    } # End of col_groups loop

    # Add the processed block to masked_blocks
    masked_blocks[[block_name]] <- block_data
  } # End of data_blocks loop

  # Combine all blocks back into a single data frame
  masked_data <- tibble::tibble(dplyr::bind_rows(masked_blocks))
  return(masked_data)
}
