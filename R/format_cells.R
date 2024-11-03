#' Format Numeric Values with Thousands Separator
#'
#' Applies comma-based thousands separators to a vector of numeric values, omitting
#' scientific notation and treating `NA` values appropriately. This function is useful
#' for improving readability of large numbers in tables and data frames.
#'
#' @param values A numeric vector of values to be formatted. `NA` values in the vector
#'        are handled and returned as `NA_character_` to maintain compatibility with
#'        formatted output.
#'
#' @return A character vector of formatted values. Each value is represented with commas
#'         as thousands separators (e.g., \code{"1,000"}), and no scientific notation is used.
#'         `NA` values are returned as `NA_character_`.
#'
#' @details This function processes each element in the `values` vector individually.
#'          Non-`NA` values are formatted as strings with comma separators for thousands,
#'          and spaces are removed to prevent unintended whitespace. `NA` values are
#'          preserved and returned as `NA_character_` to ensure compatibility with
#'          tabular data that may require formatted numeric outputs alongside missing data.
#'
format_cells <- function(values) {

  # Apply formatting to each element in the vector
  formatted_values <- sapply(values, function(value) {
    if (is.na(value)) {
      return(NA_character_)  # Return NA_character_ for NA elements
    }

    # Format value with comma as thousands separator, without scientific notation
    formatted_value <- format(value, big.mark = ",", scientific = FALSE, nsmall = 0)

    # Remove any extraneous spaces
    formatted_value <- gsub(" ", "", formatted_value)

    formatted_value
  })

  formatted_values
}
