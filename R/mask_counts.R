#' Function to perform threshold based cell masking - method 1
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
#' x1 <- c(5, 11, 43, 55, 65, 121, 1213, 0, NA)
#' x2 <- c(1,1,1,55, 65, 121, 1213, 0, NA)
#' x3 <- c(11, 10,10, 55, 65, 121, 1213, 0, NA)
#'
#' mask_counts(x)
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
#'
#'  df %>% group_by(block) %>%
#'     mutate(across(contains('group'), ~mask_counts(.),.names = "{col}_masked"))
mask_counts <- function(x, threshold = 11) {
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
             ))))
  } else {
    x.m <- x
  }

  # Secondary cell making. Case where only one primary cell is present.
  if (sum(grepl("<", x.m)) == 1 &&
      length(.extract_digits(x.m)[!grepl("<", x.m) &
                                  .extract_digits(x.m) != 0]) != 0 ||

      # Secondary cell making. Case where two primacy cells are present but both are 1.
      sum(x == 1 & !is.na(x)) == length(x.m[grepl("<", x.m)]) &&
      length(.extract_digits(x.m)[!grepl("<", x.m) &
                                  .extract_digits(x.m) != 0]) != 0) {
    min_value <-
      min(.extract_digits(x.m)[!grepl("<", x.m) &
                                 .extract_digits(x.m) != 0], na.rm = T)

    x.m[which(min_value == .extract_digits(x.m) &
                !grepl("<", x.m))] <- gsub(" ", "", paste0("<", format(
                  10 * ceiling((.extract_digits(min_value) + 1) / 10),
                  digits = 1, big.mark = ","
                )))

    return(x.m)

  } else if (threshold == 11 & sum(x == 10 & !is.na(x)) == 2 &&
             length(.extract_digits(x.m)[!grepl("<", x.m) &
                                         .extract_digits(x.m) != 0]) != 0) {
    # Secondary cell making. Case where two primacy cells are present but both are 10.
    min_value <-
      min(.extract_digits(x.m)[!grepl("<", x.m) &
                                 .extract_digits(x.m) != 0], na.rm = T)

    x.m[which(min_value == .extract_digits(x.m) &
                !grepl("<", x.m))] <- gsub(" ", "", paste0("<", format(
                  10 * ceiling((.extract_digits(min_value) + 1) / 10),
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
