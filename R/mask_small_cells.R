#' Small Cell Suppression function
#'

#' @param data Takes in a dataset with a required column named `block`.
#' @param threshold Value below which the cells with be suppressed
#' @param cols col names that require suppression
#'
#' @return dataset with suppressed values for the columns specified in @param cols

#'
#' @examples
#'
# 'df <- tibble::tribble(
# '  ~block,                      ~Characterstics, ~col1, ~col2,
# '  "sex",                               "Male",   190,  1407,
# '  "sex",                             "Female",    17,    20,
# '  "sex",                        "Sex - Other",    15,     7,
# '  "race",                              "White",   102,  1385,
# '  "race",           "African American / Black",    75,    20,
# '  "race",                              "Asian",    20,    19,
# '  "race", "Native American / Pacific Islander",    15,    10,
# '  "race",                       "Race - Other",    10,     0,
# '  "total",                     "Patient Totals",   222,  1434,
# '  "Presence of Diabetes","Presence of Diabetes",   215,     6
# ')
#' df_row_masked <- mask_small_cells(df, cols = c('col1','col2'))
#'
mask_small_cells <- function(data, threshold = 11, cols) {
  cols <- cols

  data <-  data %>%
    group_by(block) %>%
    mutate(block_size = max(row_number())) %>%
    ungroup() %>%
    rename_with(.fn = ~ paste0(., "_count"), .cols = all_of(cols))

  data_block <- data %>%
    filter(block_size > 1)

  data_single_block <- data %>%
    filter(block_size == 1)

  data_block <- data_block %>%
    group_by(block) %>%

    mutate(across(
      ends_with("_count", ignore.case = F),
      \(x) ifelse(x != 0 &
                    duplicated(x) &
                    x != threshold - 1 , x + 0.1, x),
      .names = '{col}_masked'
    ))

  if (threshold == 11) {
    data_block <- data_block %>%
      mutate(across(
        ends_with("_count_masked", ignore.case = F),
        \(x) case_when((
          sum(x > 0 &
                x < threshold, na.rm = T) == 1 |
            sum(x == threshold - 1, na.rm = T) > 1 &
            sum(x > 1 & x < threshold - 1, na.rm = T) == 0
        ) &
          #Warnings are suppressed as calculating min on an empty vector coerces to -Inf with a warning, which in our context is benign. Case
          near(suppressWarnings(min(x[x > threshold - 1], na.rm = T)), x)
        ~ gsub(" ", "", paste0(
          "<", format(10 * ceiling((x + 1) / 10), digits = 1, big.mark = ",")
        )),

        T ~ gsub(" ", "", paste0(format(
          round(x, digits = 0), big.mark = ","
        )))
        )
      ))
  } else {
    data_block <- data_block %>%
      mutate(across(
        ends_with("_count_masked", ignore.case = F),
        \(x) case_when(
          sum(x > 0 &
                x < threshold, na.rm = T) == 1 &
            #Warnings are suppressed as calculating min on an empty vector coerces to -Inf wih a warning, which in our context is benign. Case
            near(suppressWarnings(min(x[x > threshold - 1], na.rm = T)), x)
          ~ gsub(" ", "", paste0(
            "<", format(10 * ceiling((x + 1) / 10), digits = 1, big.mark = ",")
          )),

          T ~ gsub(" ", "", paste0(format(
            round(x, digits = 0), big.mark = ","
          )))
        )
      ))
  }

  data_block <- data_block %>%
    mutate(across(
      ends_with("_count_masked", ignore.case = F),
      \(x) case_when(x %in% as.character(seq(1, threshold - 1, 1))

                     ~ paste0("<", threshold),
                     T ~ x)
    )) %>%

    ungroup() %>%
    select(-block_size)

  if (nrow(data_single_block) != 0) {
    data_single_block <- data_single_block %>%

      mutate(across(
        ends_with("_count", ignore.case = F),
        \(x) case_when(
          x > 0 & x < threshold ~ paste0("<", threshold),

          x >= threshold &
            (x[data_single_block$block == 'total'] - x) > 0 &
            (x[data_single_block$block == 'total'] - x) < threshold &
            (x[data_single_block$block == 'total'] - threshold) >= threshold
          ~ gsub(" ", "", paste0(
            ">", format(x [data_single_block$block == "total"] - threshold , big.mark = ",")
          )),

          x >= threshold &
            (x[data_single_block$block == 'total'] - x) > 0 &
            (x[data_single_block$block == 'total'] - x) < threshold &
            (x[data_single_block$block == 'total'] - threshold) < threshold
          ~ ">11",

          T ~ paste0(gsub(" ", "", format(x, big.mark = ",")))
        ),
        .names = '{col}_masked'
      )) %>%
      select(-block_size)


    data <- rbind(data_block, data_single_block) %>%
      rename_with( ~ str_remove_all(., "_count"))

    return(data)

  }

  else {
    data_block <- data_block %>%
      rename_with( ~ str_remove_all(., "_count"))

    return(data_block)

  }


}
