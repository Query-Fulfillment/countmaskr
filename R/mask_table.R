#' Function to apply cell suppression methods on a table
#'
#' @param data input data with a column that has counts which need suppression
#' @param threshold threshold value for suppression for the threshold_suppression() function. defaulted to 11
#' @param col_groups columns that requires suppression. If two way tables. enter columns groups that require row-wise suppression as list()
#' @param group_by variable name to group the masking by.
#'
#' @return a tibble with row and column wise masking. masked columns will return as character vector
#'
#' @examples
#' df <- tibble::tribble(
#'   ~block, ~Characteristics, ~col1, ~col2, ~col3, ~col4,
#'   "total", "Patient Totals", 222, 1434, 525, 8,
#'   "sex", "Male", 190, 1407, 8, 2,
#'   "sex", "Female", 17, 20, 511, 2,
#'   "sex", "Sex - Other", 15, 7, 6, 4,
#'   "race", "White", 102, 1385, 75, 1,
#'   "race", "African American / Black", 75, 30, 325, 0,
#'   "race", "Asian", 20, 9, 100, 2,
#'   "race", "Native American / Pacific Islander", 15, 10, 4, 3,
#'   "race", "Race - Other", 10, 0, 21, 2,
#'   "Presence of Diabetes", "Presence of Diabetes", 215, 6, 215, 0,
#' ) %>%
#'   mutate(
#'     aggr_all_cols = col1 + col2 + col3 + col4,
#'     aggr_col1_col2 = col1 + col2,
#'     aggr_col3_col4 = col3 + col4
#'   )
#' mask_table(df,
#'   group_by = "block",
#'   col_groups = list(
#'     c("aggr_col1_col2", "col1", "col2"),
#'     c("aggr_col3_col4", "col3", "col4")
#'   )
#' )
#'
mask_table <-
  function(data,
           threshold = 11,
           col_groups,
           group_by = NULL,
           overwrite_columns = T,
           percentages = F) {
    .extract_digits <- function(x) {
      if (is.numeric(x)) {
        return(x)
      } else {
        x <- as.numeric(gsub("[^0-9.]", "", x))
      }
      return(x)
    }
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

    for (block in seq_along(list)) {
      repeat {
        for (group in col_groups) {
          across_column_mask <- apply(list[[block]][, group],
                                      MARGIN = 2,
                                      mask_counts,
                                      threshold = threshold
          )

          if (!is.matrix(across_column_mask)) {
            across_column_mask <- t(matrix(across_column_mask))
          }

          across_row_mask <-
            apply(
              across_column_mask,
              MARGIN = 1,
              mask_counts,
              threshold = threshold
            )

          if (!is.matrix(across_row_mask)) {
            across_row_mask <- matrix(t(across_row_mask))
          } else {
            across_row_mask <- t(across_row_mask)
          }

          if (overwrite_columns == T) {
            list[[block]][, group] <- across_row_mask
          } else {
            list[[block]][, paste0(group, "_masked")] <- across_row_mask
          }

          if (percentages == T) {
            original_percentages <-
              as.matrix(round(sweep(
                list[[block]][, group], 2, colSums(list[[block]][, group]),
                FUN = "/"
              ) * 100, digits = 0))

            masked_percentages <-
              round(sweep(
                if (is.vector(
                  apply(across_row_mask, 2, .extract_digits)
                )) {
                  t(as.matrix(apply(
                    across_row_mask, 2, .extract_digits
                  )))
                } else {
                  apply(across_row_mask, 2, .extract_digits)
                },
                2,
                colSums(list[[block]][, group]),
                FUN = "/"
              ) * 100, digits = 0)

            masked_percentages[which(grepl("<", across_row_mask))] <-
              paste0("<", masked_percentages[which(grepl("<", across_row_mask))], " %")

            masked_percentages[which(grepl(paste0("<", threshold), across_row_mask))] <-
              paste0("masked cell")

            masked_percentages[which(.extract_digits(masked_percentages) > 100)] <-
              paste0("<100 %")

            masked_percentages[which(!grepl("<", across_row_mask))] <-
              paste0(original_percentages[which(!grepl("<", across_row_mask))], " %")

            masked_percentages[which(grepl("NaN %", masked_percentages))] <- "0 %"

            list[[block]][, paste0(group, "_perc_masked")] <-
              masked_percentages
          }
        }

        if (nrow(across_row_mask) == 1) {
          break
        } else if (nrow(across_row_mask) > 1 &
                   sum(apply(across_row_mask, 2, function(col) {
                     grepl("<", col)
                   })) == 0 |
                   sum(apply(across_row_mask, 2, function(col) {
                     grepl("<", col)
                   })) > 1) {
          break
        }
      }
    }

    data <- data.frame(do.call(rbind, Map(cbind, list)))
    rownames(data) <- NULL
    return(data)
  }
