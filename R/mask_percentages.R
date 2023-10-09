#' Function to generate masked percentage for given numeric vector
#'
#' @param x vector of length N
#' @param threshold threshold of defined count suppression
#' @param x_masked masked vector of parameter x. Defaulted to NULL
#'
#' @return character vector of masked percentages
#'
#' @examples
#' x <- c(5, 11, 43, 55, 65, 121, 1213, 0, NA)
#' mask_percentages(x)
mask_percentages <-
  function(x,
           x_masked = NULL,
           threshold = 11) {
    .extract_digits <- function(x) {
      if (is.numeric(x)) {
        return(x)
      } else {
        x <- as.numeric(gsub("[^0-9.]", "", x))
      }
      return(x)
    }


    threshold <- threshold

    if (is.null(x_masked)) {
      x_masked <- threshold_suppressor(x, threshold = threshold)
    }
    masked_percentages <-
      paste0(round(.extract_digits(x_masked) / sum(.extract_digits(x)) * 100), " %")

    masked_percentages[which(grepl("<", x_masked))] <-
      paste0("<", masked_percentages[which(grepl("<", x_masked))])

    return(masked_percentages)
  }
