#' Function to perform threshold based cell masking
#'
#' @param x vector of length N
#' @param threshold threshold below with the values must be suppressed
#'
#' @return a character vector with primary and/or secondary masked cell
#' @export
#'
#' @examples
#' x <- c(5, 11, 43, 55, 65, 121, 1213, 0, NA)
#' threshold_suppressor(x)
get_masked_counts <- function(x, threshold = 11) {
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
    min_value <-
      min(.extract_digits(x.m)[!grepl("<", x.m) &
                                 .extract_digits(x.m) != 0], na.rm = T)

    x.m[which(min_value == .extract_digits(x.m) & !grepl("<", x.m))] <- gsub(" ", "", paste0("<", format(
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
