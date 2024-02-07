#' Function to perform threshold based cell masking - method 2
#'
#' `r lifecycle::badge("stable")`
#'
#' @description
#' This function is an adaptation of mask_count() but performs masking in a modified way. This masking prevents the total counts to exceed the original totals
#'
#' @import tibble
#' @import dplyr
#'
#' @param x vector of length N
#' @param threshold threshold below with the values must be suppressed
#'
#' @return a character vector with primary and/or secondary masked cell
#'
#' @export
#'
#' @examples
#' x <- c(5, 11, 43, 55, 65, 121, 1213, 0, NA)
#'
#' mask_counts_2(x)
#'
#'  df <- tibble::tribble(
#' ~block, ~Characteristics, ~group1, ~group2, ~group3, ~group4,
#' "sex", "Male", 190, 1407, 8, 2,
#' "sex", "Female", 17, 20, 511, 2,
#' "sex", "Sex - Other", 15, 7, 6, 4,
#' "race", "White", 102, 1385, 75, 1,
#' "race", "African American / Black", 75, 30, 325, 0,
#' "race", "Asian", 20, 9, 100, 2,
#' "race", "Native American / Pacific Islander", 15, 10, 4, 3,
#' "race", "Race - Other", 10, 0, 21, 2,
#' ) %>%
#'   dplyr::mutate(
#'     aggr_group_all = group1 + group2 + group3 + group4,
#'     aggr_group_1_2 = group1 + group2,
#'     aggr_group_3_4 = group3 + group4
#'  )
#' df %>% group_by(block) %>%
#'     mutate(across(contains('group'), ~mask_counts_2(.),.names = "{col}_masked"))
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
  } else{
  x.m <- x
  }


  if (sum(grepl("<", x.m)) == 1 &
    length(.extract_digits(x.m)[!grepl("<", x.m) &
      .extract_digits(x.m) != 0]) != 0) {
    max_value <-
      max(.extract_digits(x.m)[!grepl("<", x.m) &
        .extract_digits(x.m) != 0], na.rm = T)

    x.m[which(max_value == .extract_digits(x.m))] <- gsub(" ", "", paste0(">", format(
      max_value - x,
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
