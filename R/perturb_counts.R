#' Function to perturb counts in a vector with small cells
#'
#' `r lifecycle::badge("experimental")`
#'
#' @description
#' This is a function to perturb counts in a vector where only one primary cell is present and requires
#' secondary cell to be masked - Algorithm 3 (A3)
#'
#' @import tibble
#' @import dplyr
#' @import tidyr
#'
#' @param x numeric vector of length N
#' @param threshold threshold for small cell aka 'primary cell'
#'
#' @return a vector with added weighted noise to the non-primary cells
#' If the non-secondary cell do not have enough room to distribute noise, the function will return with an error
#' suggesting to use Threshold-based suppression.
#'
#' @export
#'
#' @examples
#' x1 <- c(5, 11, 43, 55, 65, 121, 1213, 0, NA)
#' x2 <- c(1, 1, 1, 55, 65, 121, 1213, 0, NA)
#' x3 <- c(11, 10, 10, 55, 65, 121, 1213, 0, NA)
#'
#' lapply(list(x1, x2, x3), perturb_counts)
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
#'   mutate(N_masked = perturb_counts(N))
#'
perturb_counts <- function(x, threshold = 10) {
  small_cells <- which(x > 0 & x < threshold)

  if (length(small_cells) == 0) {
    return(gsub(" ", "", paste0(format(
      x,
      digits = 1, big.mark = ","
    ))))
  } else if (length(small_cells) > 1) {
    warning(
      "More than one primary cell detected. Use threshold based suppression to minimize information loss"
    )
    x.i <- x
  } else {
    x.i <- x
  }

  x.i[small_cells] <- threshold

  x_sum <- sum(x, na.rm = T)


  total_noise_counts <- x_sum - sum(x.i, na.rm = T)

  available_cells <- length(x[x > threshold & !is.na(x)]) - length(small_cells)

  available_counts_before_all_cells_exhaust <-
    sum(x[-small_cells], na.rm = T) - threshold * available_cells

  if (available_counts_before_all_cells_exhaust - abs(total_noise_counts) < 0) {
    warning(
      "Required counts for adding noise exceeds the available counts. Threshold-based cell suppression coerced"
    )
    x <- mask_counts(x)
    return(x)
  } else if (available_cells > 0) {
    weights <- x / sum(x, na.rm = T)


    weighted_noise <- total_noise_counts * weights


    x.i[-small_cells] <-
      x.i[-small_cells] + weighted_noise[-small_cells]


    x.i <- round(x.i)


    remaining_noise <- x_sum - sum(x.i, na.rm = T)


    if (remaining_noise > 0) {
      sorted_indices <- order(-x)
      for (i in sorted_indices) {
        if (remaining_noise == 0) {
          break
        }
        # Skip values that would fall below 11
        if (x.i[i] >= 11) {
          x.i[i] <- x.i[i] + 1
          remaining_noise <- remaining_noise - 1
        }
      }
    } else if (remaining_noise < 0) {
      sorted_indices <- order(-x)
      for (i in sorted_indices) {
        if (remaining_noise == 0) {
          break
        }
        x.i[i] <- x.i[i] - 1
        remaining_noise <- remaining_noise + 1
      }
    }
    x.prop <- round(x[-small_cells] / sum(x[-small_cells], na.rm = T), digits = 0)
    x.i.prop <- round(x.i[-small_cells] / sum(x.i[-small_cells], na.rm = T), digits = 0)

    if (all(x.prop == x.i.prop, na.rm = T)) {
      return(gsub(" ", "", paste0(format(
        x.i,
        digits = 1, big.mark = ","
      ))))
    } else {
      warning("Perturbing counts changes prior percentages - Threshold-based cell suppression coerced")
      x <- mask_counts(x)
      return(x)
    }
  }
}
