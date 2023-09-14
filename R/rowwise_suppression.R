#' Column-wise suppression
#'
#' @param data Output dataset from (suppress_small_cells())
#' @param cols groups of columns that needs a column-wise suppression. This parameter should be passed as a list object. If multiple groups exists,
#' each group can be a seperate list object.
#'
#' @return dataset with column-wise suppressed cells
#'
#' @examples
#'
#' df_row_col_masked <- colwise_suppression(df_row_masked, cols = list(c('col1_masked','col2_masked')))
rowwise_suppression <- function(data, cols) {
  if (!is.list(cols)) {
    cols = list(cols)
  } else {

  }

  for (col in seq_along(cols)) {
    if (length(cols[[col]]) == 1) {
      next

    }



    data_1 <- data


    data_1 <- data_1 %>%

      mutate(row_count = ifelse(rowSums(
        sapply(data_1 %>% select(cols[[col]]), function(x)
          str_count(x, "<|>"))
      ) == 1 , T, F)) %>%

      rowwise() %>%
      #Warnings are supressed as only unmasked values are of interest. converting masked values to numeric will convert them to NA which will then we excluded using incomparables = NA
      mutate(duplicate_second_cell = suppressWarnings(any(
        duplicated(as.numeric(c_across(cols[[col]])), incomparables = NA)
      ))) %>%

      mutate(across(
        contains(cols[[col]], ignore.case = F),
        \(x) case_when(
          row_count == T &
            str_detect(x, "<|>") == F & duplicate_second_cell == F &
            suppressWarnings(near(
              min(as.numeric(gsub(
                ',', '', c_across(cols[[col]])
              ))[as.numeric(gsub(',', '', c_across(cols[[col]]))) > 0], na.rm = T), parse_number(x)
            ))
          ~ paste0("<", 10 * ceiling(suppressWarnings(parse_number(x))/ 10)),

          row_count == T &
            str_detect(x, "<|>") == F & duplicate_second_cell == T &
            suppressWarnings(near(
              max(as.numeric(gsub(
                ',', '', c_across(cols[[col]])
              ))[as.numeric(gsub(',', '', c_across(cols[[col]]))) > 0], na.rm = T), parse_number(x)
            ))
          ~ paste0("<", 10 * ceiling(suppressWarnings(parse_number(x))/ 10)),
          T ~ as.character(x)
        )
      )) %>%

      mutate(across(
        contains(cols[[col]], ignore.case = F),
        \(x) ifelse(x == '<0' | is.na(x) | x == "<10", '<11', x)
      )) %>%

      ungroup() %>%

      group_by(block) %>%

      mutate(across(
        contains(cols[[col]], ignore.case = F),
        \(x) case_when(
          sum(str_detect(x, "<")) == 1 & max(row_number()) > 1 &
            suppressWarnings(near(
              min(as.numeric(gsub(',', '', x))[as.numeric(gsub(',', '', x)) > 0], na.rm = T), parse_number(x)
            )) ~

            gsub(" ", "", paste0(
              "<", format(10 * ceiling((
                suppressWarnings(parse_number(x)) + 1
              ) / 10), big.mark = ",")
            )),

          T ~ x
        )
      )) %>%
      ungroup() %>%
      select(-c(row_count, duplicate_second_cell))

    data <- data_1

  }

  return(data)

}
