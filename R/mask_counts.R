#' Function to perform threshold based cell masking - Algorithm 1 (A1)
#'
#' `r lifecycle::badge("stable")`
#'
#' @description
#' This function is a workhorse of the mask_table function. It identifies primary and secondary cells, and masks them as necessary
#'
#'
#' @import tibble
#' @import dplyr
#' @import tidyr
#'
#' @param x vector of length N
#' @param threshold threshold below with the values must be suppressed
#' @param relax_masking boolean parameter to set relaxed masking. When set to TRUE, if 0 is present with a small cell, it will be masked as a secondary cell with a value
#'
#' @return a character vector with primary and/or secondary masked cell
#'
#' @export
#'
#' @examples
#' x1 <- c(5, 11, 43, 55, 65, 121, 1213, 0, NA)
#' x2 <- c(1, 1, 1, 55, 65, 121, 1213, 0, NA)
#' x3 <- c(11, 10, 10, 55, 65, 121, 1213, 0, NA)
#'
#' lapply(list(x1, x2, x3), mask_counts_2)
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
#' aggregate_table %>%
#'   group_by(block) %>%
#'   mutate(N_masked = mask_counts(N))
#'
mask_counts <- function(x, threshold = 11, relax_masking = FALSE) {
  .extract_digits <- function(x) {
    x <- as.numeric(gsub("[^0-9.]", "", x))

    return(x)
  }

  if (sum(grepl("<", x)) == 0) {
    if (!is.numeric(x)) {
      x <- .extract_digits(x)
    }
    x.m <-
      ifelse(x > 0 &
        x < threshold,
      paste0("<", threshold),
      gsub(" ", "", paste0(format(
        x,
        digits = 1, big.mark = ","
      )))
      )
  } else {
    x.m <- x
  }

  # Secondary cell making. Case where only one primary cell is present.
  if (sum(grepl("<", x.m)) == 1 &&
    length(.extract_digits(x.m)[!grepl("<", x.m) &
      .extract_digits(x.m) != 0]) != 0 ||

    # Secondary cell masking. Case where two primacy cells are present but both are 1.
    sum(x == 1 & !is.na(x)) && sum(x.m == paste0("<", threshold) & !is.na(x.m)) == length(x.m[grepl("<", x.m)]) &&
      length(.extract_digits(x.m)[!grepl("<", x.m) &
        .extract_digits(x.m) != 0]) != 0) {
    if (isTRUE(relax_masking)) {
      min_value <-
        min(.extract_digits(x.m), na.rm = T)
      x.m[which(min_value == .extract_digits(x.m) &
        !grepl("<", x.m))] <- paste0("<", threshold)
    } else {
      min_value <- min(.extract_digits(x.m)[!grepl("<", x.m) &
        .extract_digits(x.m) != 0], na.rm = T)
      x.m[which(min_value == .extract_digits(x.m) &
        !grepl("<", x.m))] <- gsub(" ", "", paste0("<", format(
        10 * ceiling((.extract_digits(min_value) + 1) / 10),
        digits = 1, big.mark = ","
      )))
    }

    return(x.m)
  } else if (threshold == 11 & sum(x == 10 & !is.na(x)) == 2 &&
    length(.extract_digits(x.m)[!grepl("<", x.m) &
      .extract_digits(x.m) != 0]) != 0) {
    # Secondary cell making. Case where two primacy cells are present but both are 10.
    if (isTRUE(relax_masking)) {
      min_value <-
        min(.extract_digits(x.m), na.rm = T)

      x.m[which(min_value == .extract_digits(x.m) &
        !grepl("<", x.m))] <- paste0("<", threshold)
    } else {
      min_value <- min(.extract_digits(x.m)[!grepl("<", x.m) &
        .extract_digits(x.m) != 0], na.rm = T)

      x.m[which(min_value == .extract_digits(x.m) &
        !grepl("<", x.m))] <- gsub(" ", "", paste0("<", format(
        10 * ceiling((.extract_digits(min_value) + 1) / 10),
        digits = 1, big.mark = ","
      )))
    }

    return(x.m)
  } else {
    return(x.m)
  }
}
