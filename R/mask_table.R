#' Function to apply cell suppression methods on a two-by-two tables
#'
#' `r lifecycle::badge("stable")`
#'
#' @description
#' This is a multi-tasking function to convert a simple table 1 with counts and percentages both  -masked and unmasked
#'
#'
#' @import tibble
#' @import dplyr
#' @import tidyr
#'
#' @param data input data with a column that has counts which need suppression
#' @param threshold threshold value for suppression for the threshold_suppression() function. defaulted to 11
#' @param col_groups columns that requires suppression. If two way tables. enter columns groups that require row-wise suppression as list()
#' @param group_by variable name to group the masking by
#' @param overwrite_columns Boolean parameter to overwrite columns
#' @param percentages Boolean parameter for generate masked percentages, naming convention: 'col_perc_masked'
#' @param zero_masking Boolean parameter to mask 0 as secondary cell when present
#' @param .verbose Boolean parameter to log steps of masking in the console
#'
#' @return a tibble with row and column wise masking. masked columns will return as character vector
#'
#' @export
#'
#' @examples
#'
#' data("countmaskr_data")
#'
#' aggregate_table <- countmaskr_data %>%
#'   select(-c(id, age)) %>%
#'   gather(block, Characteristics) %>%
#'   group_by(block, Characteristics) %>%
#'   summarise(N = n()) %>%
#'   ungroup()
#'
#' mask_table(aggregate_table,
#'   group_by = "block",
#'   col_groups = list("N")
#' )
#'
#' mask_table(aggregate_table,
#'   group_by = "block",
#'   col_groups = list("N"),
#'   overwrite_columns = FALSE,
#'   percentages = TRUE
#' )
#'
#' countmaskr_data %>%
#'   count(race, gender) %>%
#'   pivot_wider(names_from = gender, values_from = n) %>%
#'   mutate(across(all_of(c("Male", "Other")), ~ ifelse(is.na(.), 0, .)),
#'     Overall = Female + Male + Other, .after = 1
#'   ) %>%
#'   countmaskr::mask_table(.,
#'     col_groups = list(c("Overall", "Female", "Male", "Other")),
#'     overwrite_columns = TRUE,
#'     percentages = FALSE
#'   )
#'
mask_table <-
  function(data,
           threshold = 11,
           col_groups,
           group_by = NULL,
           overwrite_columns = TRUE,
           percentages = FALSE,
           zero_masking = FALSE,
           .verbose = FALSE) {
    # resolving data structure to perform downstream tasks
    threshold <- threshold
    if (!is.list(col_groups)) {
      col_groups <- list(col_groups)
    } else {

    }
    if (!is.null(group_by)) {
      list <- split(data, data[, group_by])
    } else {
      list <- list(data)
    }

    # Starting to loop by block
    for (block in seq_along(list)) {
      if (isTRUE(.verbose)) {
        message(paste0("Starting masking for ", names(list[block]), "\n\n"))
      }
      # Looping by groups
      for (group in col_groups) {
        original_counts <- list[[block]][, group]
        if (isTRUE(.verbose)) {
          message(paste0("Performing masking:", group, "\n\n"))
        }
        repeat {
          across_column_mask <- apply(original_counts,
            MARGIN = 2,
            mask_counts,
            threshold = threshold,
            zero_masking = zero_masking
          )
          if (!is.matrix(across_column_mask)) {
            across_column_mask <- t(matrix(across_column_mask))
          }
          across_row_mask <- apply(across_column_mask,
            MARGIN = 1,
            mask_counts,
            threshold = threshold,
            zero_masking = zero_masking
          )
          if (!is.matrix(across_row_mask)) {
            across_row_mask <- matrix(t(across_row_mask))
          } else {
            across_row_mask <- t(across_row_mask)
          }
          original_percentages <-
            as.matrix(round(sweep(list[[block]][, group], 2, colSums(list[[block]][, group]), FUN = "/") * 100, digits = 0))
          original_total <- colSums(list[[block]][, group])

          # Percentage computations if requested
          if (isTRUE(percentages)) {
            masked_percentages <-
              round(
                sweep(if (is.vector(
                  apply(across_row_mask, 2, .extract_digits)
                )) {
                  t(as.matrix(apply(
                    across_row_mask, 2, .extract_digits
                  )))
                } else {
                  apply(across_row_mask, 2, .extract_digits)
                }, 2, original_total, FUN = "/") * 100,
                digits = 0
              )
            masked_percentages[which(grepl("<", across_row_mask))] <-
              paste0("<", masked_percentages[which(grepl("<", across_row_mask))], " %")
            masked_percentages[which(grepl(paste0("<", threshold), across_row_mask))] <-
              paste0("masked cell")
            masked_percentages[which(.extract_digits(masked_percentages) >
              100)] <- paste0("<100 %")
            masked_percentages[which(!grepl("<", across_row_mask))] <-
              paste0(original_percentages[which(!grepl("<", across_row_mask))], " %")
            masked_percentages[which(grepl("NaN %", masked_percentages))] <-
              "0 %"

            list[[block]][, paste0(group, "_perc")] <-
              original_percentages

            list[[block]][, paste0(group, "_perc_masked")] <-
              masked_percentages
          }
          masked_counts <- across_row_mask

          # Checking if performing rowwise masking in same row on different column requires an additional cell,
          # if required, the repeat loop will perform a whole iteration until convergence is attained
          if (nrow(masked_counts) >= 1) {
            total_masked_cells <- colSums(matrix(apply(masked_counts, 2, function(col) {
              grepl("<", col)
            })))
            total_available_cells <- colSums(matrix(apply(masked_counts, 2, function(col) {
              !grepl("<", col)
            })))
            total_zeros <- colSums(matrix(apply(masked_counts, 2, function(col) {
              col == "0" | col == "NA" | is.na(col)
            })))
          }
          if ((nrow(masked_counts) == 1) |
            (any(total_masked_cells ==
              1) &
              all(total_available_cells[which(total_masked_cells ==
                1)] == total_zeros[which(total_masked_cells ==
                1)])) |
            (!any(total_masked_cells == 1))) {
            # Overwriting columns if requested
            if (isTRUE(overwrite_columns)) {
              list[[block]][, group] <- masked_counts
            } else {
              list[[block]][, paste0(group, "_masked")] <- masked_counts
            }
            break
          } else {
            original_counts <- masked_counts
          }
        }
      }
    }
    masked_data <- data.frame(do.call(rbind, Map(cbind, list)))
    rownames(masked_data) <- NULL
    return(tibble(masked_data))
  }


# Defining a function to extract digits from character vector
.extract_digits <- function(x) {
  if (is.numeric(x)) {
    return(x)
  } else {
    x <- as.numeric(gsub("[^0-9.]", "", x))
  }
  return(x)
}
