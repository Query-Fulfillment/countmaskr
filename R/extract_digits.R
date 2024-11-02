#' Extract Numeric Values from Formatted Strings
#'
#' This function extracts numeric values from character strings that may contain optional
#' symbols (`<` or `>`), commas, or decimal points. It removes these symbols and formats
#' the strings to ensure proper numeric conversion. The function checks for disallowed
#' formats and throws an error if any values do not meet the specified pattern.
#'
#' @param values A character vector of numeric-like values.
#'   Values may contain optional `<` or `>` symbols at the start, commas as thousand
#'   separators, and decimal points.
#'
#' @return A numeric vector containing the extracted numeric values. If a value is
#'   incorrectly formatted, the function stops with an error message.
#'
#' @examples
#' # Basic usage with symbols, commas, and decimal points
#' extract_digits(c("1,234", "<5,432.1", ">-3,000", "987.65"))
#'
#' # Using values with no symbols or commas
#' extract_digits(c("100", "-50.25", "3000"))
#'
#' # Values with invalid format will trigger an error
#' \dontrun{
#' extract_digits(c("123abc", ">1,234,567.89")) # Error due to invalid format
#' }
#'
#' @details
#' The function first checks for valid formats using a regular expression. Only values
#' matching the following pattern are accepted:
#' - Optional `<` or `>` symbol at the start.
#' - Optional negative sign (`-`) before the number.
#' - Digits in groups of three with commas as thousand separators.
#' - Optional decimal point with digits following.
#'
#' If the format is valid, the function removes the `<` or `>` symbols and commas,
#' and converts the cleaned string to a numeric value.
#'
extract_digits <- function(values) {
  # Identify which values are NA
  is_na <- is.na(values)

  # For non-NA values, apply the pattern matching
  non_na_values <- values[!is_na]

  # Define the allowed pattern: optional '<' or '>', optional '-', digits, optional '.', digits
  allowed_pattern <- "^([<>]?) ?-?[0-9]{1,3}(,[0-9]{3})*(\\.[0-9]+)?$"

  # Check for disallowed characters or invalid formats in non-NA values
  if (any(!grepl(allowed_pattern, non_na_values))) {
    stop("Error: Values contain disallowed characters or invalid format.")
  }

  # Remove the '<' or '>' symbol if present at the start in non-NA values
  numeric_strings <- rep(NA_character_, length(values))
  numeric_strings[!is_na] <- gsub("^[<>] ?", "", non_na_values)

  # Remove commas from the cleaned strings
  numeric_strings <- gsub(",", "", numeric_strings)

  # Convert the cleaned strings to numeric
  numeric_values <- as.numeric(numeric_strings)

  # Check if any non-NA values could not be converted to numeric
  if (any(is.na(numeric_values[!is_na]))) {
    stop("Error: Some values could not be converted to numeric.")
  }

  return(numeric_values)
}
