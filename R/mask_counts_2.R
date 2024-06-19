#' Function to perform threshold based cell masking - method 2
#'
#' `r lifecycle::badge("stable")`
#'
#' @description
#' This function is an adaptation of mask_count() but performs masking in a modified way. This masking prevents the total counts to exceed the original totals
#'
#' @import tibble
#' @import dplyr
#' @import tidyr
#'
#' @param x vector of length N
#' @param threshold threshold below with the values must be suppressed
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
#'
#' lapply(list(x1, x2, x3), mask_counts_2)
#'
#' data('countmaskr_data')
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
#'   mutate(N_masked = mask_counts_2(N))
#'
mask_counts_2 <- function(x, threshold = 11) {
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


  if (sum(grepl("<", x.m)) == 1 &
    length(.extract_digits(x.m)[!grepl("<", x.m) &
      .extract_digits(x.m) != 0]) != 0) {
    max_value <-
      max(.extract_digits(x.m)[!grepl("<", x.m) &
        .extract_digits(x.m) != 0], na.rm = T)

    small_cell_index <- which(x.m == "<11")

    x.m[which(max_value == .extract_digits(x.m))] <- gsub(" ", "", paste0(">", format(
      max_value - (threshold - x[small_cell_index]),
      digits = 1, big.mark = ","
    )))
    return(x.m)
  } else {
    return(gsub(" ", "", paste0(format(
      x.m,
      digits = 1, big.mark = ","
    ))))
  }
}
