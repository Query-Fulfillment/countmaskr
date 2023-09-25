#' Function to mask small. cell in a vector
#'
#' @param x numeric vector of length N
#' @param threshold threshold for small cell aka 'primary cell'
#'
#' @return vector with masked values for primary small cell and secondary non-small cell where required
#'
#' @examples
#' mask_small_cells(x = c(102, 74, 30, 30, 4, NA))
#'
#' df <- tibble::tribble(
#'   ~block, ~Characterstics, ~col1, ~col2,
#'   "sex", "Male", 190, 1407,
#'   "sex", "Female", 17, 20,
#'   "sex", "Sex - Other", 15, 7,
#'   "race", "White", 102, 1385,
#'   "race", "African American / Black", 75, 20,
#'   "race", "Asian", 20, 19,
#'   "race", "Native American / Pacific Islander", 15, 10,
#'   "race", "Race - Other", 10, 0,
#'   "total", "Patient Totals", 222, 1434,
#'   "Presence of Diabetes", "Presence of Diabetes", 215, 6
#' )
#' df %>%
#'   group_by(block) %>%
#'   mutate(across(starts_with("col"), ~ mask_small_cells_2(.)))
#'
mask_small_cells_2 <- function(x, threshold = 11) {
  if (!is.numeric(x)) {
    stop("Non-numeric arguement passed as input. Only numeric arguements are allowed")
  }


  if (threshold == 11) {
    x <-
      ifelse(x != 0 &
        x != threshold - 1 & duplicated(x), x + 0.1, x)


    x <-
      ifelse(
        abs(suppressWarnings(min(x[x > threshold - 1], na.rm = TRUE)) - x) == 0 &
          (sum(x > 0 &
            x < threshold, na.rm = T) == 1),
        gsub(" ", "", paste0(
          "<", format(10 * ceiling((x + 1) / 10), digits = 1, big.mark = ",")
        )),
        ifelse(
          sum(x == threshold - 1, na.rm = T) > 1 &
            sum(x > 0 & x < threshold - 1, na.rm = T) == 0 &
            abs(suppressWarnings(min(x[x > threshold - 1], na.rm = TRUE)) - x) == 0,
          gsub(" ", "", paste0(
            "<", format(10 * ceiling((x + 1) / 10), digits = 1, big.mark = ",")
          )),
          ifelse(
            x > 0 & x < threshold,
            paste0("<", threshold),
            gsub(" ", "", paste0(format(
              round(x, digits = 0),
              big.mark = ","
            )))
          )
        )
      )
  } else {
    x <-
      ifelse(
        abs(suppressWarnings(min(x[x > threshold - 1], na.rm = TRUE) - x)) == 0 &
          sum(x > 0 &
            x < threshold, na.rm = T) == 1,
        gsub(" ", "", paste0(
          "<", format(10 * ceiling((x + 1) / 10), digits = 1, big.mark = ",")
        )),
        ifelse(
          x > 0 & x < threshold,
          paste0("<", threshold),
          gsub(" ", "", paste0(format(
            round(x, digits = 0),
            big.mark = ","
          )))
        )
      )
  }
  return(x)
}
