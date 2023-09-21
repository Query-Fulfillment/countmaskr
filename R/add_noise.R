#' Function to add noise to a vector with small cells
#'
#' @param x numeric vector of length N
#' @param threshold threshold for small cell aka 'primary cell'
#'
#' @return a vector with added weighted noise to the non-primary cells
#' If the non-secondary cell do not have enough room to distribute noise, the function will return with an error
#' suggesting to use Threshold-based suppression.
#'
#' @examples #' add_noise(x = c(102,74,30,30,4,NA))
#'
#' df <- tibble::tribble(
#' ~block,                      ~Characterstics, ~col1, ~col2,
#' "sex",                               "Male",   190,  1407,
#' "sex",                             "Female",    17,    20,
#' "sex",                        "Sex - Other",    15,     7,
#' "race",                              "White",   102,  1385,
#' "race",           "African American / Black",    75,    20,
#' "race",                              "Asian",    20,    19,
#' "race", "Native American / Pacific Islander",    15,    10,
#' "race",                       "Race - Other",    10,     0,
#' "total",                     "Patient Totals",   222,  1434,
#' "Presence of Diabetes","Presence of Diabetes",   215,     6
#' )
#' df %>% group_by(block) %>% mutate(across(starts_with('col'), ~add_noise(.)))

add_noise <- function(x, threshold = 10) {

  small_cells <- which(x <= threshold)

  if (is_empty(small_cells)) {
    return(x)
  } else

    if (length(small_cells) > 1) {
      warning(
        "More than one primary cell detected. Use threshold based suppression to minimize information loss"
      )
    } else


    x.i <- x

    x.i[small_cells] <- threshold

    x_sum <- sum(x)


    total_noise_counts <- x_sum - sum(x.i)

    available_cells <- length(x) - length(small_cells)

    required_vs_available <-
      sum(x[-small_cells]) - threshold * available_cells

    if (required_vs_available - abs(total_noise_counts) < 0) {
      stop(
        "Required counts for adding noise exceeds the available counts. Threshold-based cell suppression suggested"
      )
    } else

      if (available_cells > 0) {
        weights <- x[-small_cells] / sum(x[-small_cells])


        weighted_noise <- total_noise_counts * weights


        x.i[-small_cells] <-
          x.i[-small_cells] + weighted_noise[-small_cells]


        x.i <- round(x.i)


        remaining_noise <- x_sum - sum(x.i)


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
      }
    return(x.i)

}
