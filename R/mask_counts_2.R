#' Function to perform threshold based cell masking - method 2
#'
#' @param x vector of length N
#' @param threshold threshold below with the values must be suppressed
#'
#' @return a character vector with primary and/or secondary masked cell
#' @export
#'
#' @examples
#' x <- c(5, 11, 43, 55, 65, 121, 1213, 0, NA)
#' mask_counts_2(x)
#'
#' #' #' df <- tibble::tribble(
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
#' )
#' system.time(df %>%
#'              group_by(block) %>%
#'              mutate(across(contains('col'), ~mask_counts_2(.),.names = "{col}_masked")))
#'
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
