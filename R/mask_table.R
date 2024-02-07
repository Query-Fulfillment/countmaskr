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
#'
#' @param data input data with a column that has counts which need suppression
#' @param threshold threshold value for suppression for the threshold_suppression() function. defaulted to 11
#' @param col_groups columns that requires suppression. If two way tables. enter columns groups that require row-wise suppression as list()
#' @param group_by variable name to group the masking by
#' @param overwrite_columns Boolean parameter to overwrite columns
#' @param percentages Boolean parameter for generate masked percentages. naming convention will be as follows: ('{col}_perc_masked')
#'
#' @return a tibble with row and column wise masking. masked columns will return as character vector
#'
#' @export
#'
#' @examples
#' df <- tibble::tribble(
#'   ~block, ~Characteristics, ~group1, ~group2, ~group3, ~group4,
#'   "sex", "Male", 190, 1407, 8, 2,
#'   "sex", "Female", 17, 20, 511, 2,
#'   "sex", "Sex - Other", 15, 7, 6, 4,
#'   "race", "White", 102, 1385, 75, 1,
#'   "race", "African American / Black", 75, 30, 325, 0,
#'   "race", "Asian", 20, 9, 100, 2,
#'   "race", "Native American / Pacific Islander", 15, 10, 4, 3,
#'   "race", "Race - Other", 10, 0, 21, 2,
#' ) %>%
#'   dplyr::mutate(
#'     aggr_group_all = group1 + group2 + group3 + group4,
#'     aggr_group_1_2 = group1 + group2,
#'     aggr_group_3_4 = group3 + group4
#'   )
#' mask_table(df,
#'            group_by = "block",
#'            col_groups = list(
#'              c("aggr_group_1_2", "group1", "group2"),
#'              c("aggr_group_3_4", "group3", "group4")
#'            ),
#'            overwrite_columns = FALSE,
#'            percentages = TRUE
#')
mask_table <-
  function (data,
            threshold = 11,
            col_groups,
            group_by = NULL,
            overwrite_columns = T,
            percentages = F) {
    # Defining a function to extract digits from character vector
    .extract_digits <- function(x) {
      if (is.numeric(x)) {
        return(x)
      }
      else {
        x <- as.numeric(gsub("[^0-9.]", "", x))
      }
      return(x)
    }

    #resolving data structure to perform downstream tasks
    threshold <- threshold
    if (!is.list(col_groups)) {
      col_groups <- list(col_groups)
    }
    else {

    }
    if (!is.null(group_by)) {
      list <- split(data, data[, group_by])
    }
    else {
      list <- list(data)
    }

    # Starting to loop by block
    for (block in seq_along(list)) {
      message(paste0("Starting masking for ", names(list[block]),
                     "\n\n"))

      # Looping by groups
      for (group in col_groups) {
        original_counts <- list[[block]][, group]
        message(paste0("Performing masking:", group, "\n"))
        repeat {
          across_column_mask <- apply(original_counts,
                                      MARGIN = 2,
                                      mask_counts,
                                      threshold = threshold)
          if (!is.matrix(across_column_mask)) {
            across_column_mask <- t(matrix(across_column_mask))
          }
          across_row_mask <- apply(across_column_mask,
                                   MARGIN = 1,
                                   mask_counts,
                                   threshold = threshold)
          if (!is.matrix(across_row_mask)) {
            across_row_mask <- matrix(t(across_row_mask))
          }
          else {
            across_row_mask <- t(across_row_mask)
          }
          original_percentages <-
            as.matrix(round(sweep(list[[block]][,
                                                group], 2, colSums(list[[block]][, group]),
                                  FUN = "/") * 100, digits = 0))
          original_total <- colSums(list[[block]][, group])

          # Percentage computations if reqested
          if(isTRUE(percentages)) {

            masked_percentages <-
              round(sweep(if (is.vector(
                apply(across_row_mask,
                      2, .extract_digits)
              )) {
                t(as.matrix(apply(
                  across_row_mask, 2, .extract_digits
                )))
              } else {
                apply(across_row_mask, 2, .extract_digits)
              }, 2, original_total, FUN = "/") * 100,
              digits = 0)
            masked_percentages[which(grepl("<", across_row_mask))] <-
              paste0("<",
                     masked_percentages[which(grepl("<", across_row_mask))],
                     " %")
            masked_percentages[which(grepl(paste0("<",
                                                  threshold), across_row_mask))] <-
              paste0("masked cell")
            masked_percentages[which(.extract_digits(masked_percentages) >
                                       100)] <- paste0("<100 %")
            masked_percentages[which(!grepl("<", across_row_mask))] <-
              paste0(original_percentages[which(!grepl("<",
                                                       across_row_mask))], " %")
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
          if (nrow(masked_counts) > 1) {
            total_masked_cells <- colSums(apply(masked_counts,
                                                2, function(col) {
                                                  grepl("<", col)
                                                }))
            total_available_cells <- colSums(apply(masked_counts,
                                                   2, function(col) {
                                                     !grepl("<", col)
                                                   }))
            total_zeros <- colSums(apply(masked_counts,
                                         2, function(col) {
                                           col == "0" | col == "NA" | is.na(col)
                                         }))
          }
          if ((nrow(masked_counts) == 1) | (any(total_masked_cells ==
                                                1) &
                                            all(total_available_cells[which(total_masked_cells ==
                                                                            1)] == total_zeros[which(total_masked_cells ==
                                                                                                     1)])) |
              (!any(total_masked_cells == 1))) {

            #Overwriting columns if requested
            if (isTRUE(overwrite_columns)) {
              list[[block]][, group] <- masked_counts
            }
            else {
              list[[block]][, paste0(group, "_masked")] <- masked_counts
            }
            break
          }
          else {
            original_counts <- masked_counts
          }
        }
      }
    }
    masked_data <- data.frame(do.call(rbind, Map(cbind, list)))
    rownames(masked_data) <- NULL
    return(masked_data)
  }
