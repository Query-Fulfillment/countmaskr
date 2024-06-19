#' Function to mask output from gtsummary::tbl_summary() function
#'
#' @param gttbl output from gtsummary::tbl_summary()
#'
#' @return Masked tbl_summary object
#' @export
#'
#' @examples
mask_gt_table <- function(gttbl) {
  gttbl$table_body <- gttbl$table_body %>%
    mutate(sort = row_number())

  cat_cont <- split(gttbl$table_body, gttbl$table_body$var_type)
  raw_table <- split(cat_cont[["categorical"]], cat_cont[["categorical"]]$row_type)

  cols <- raw_table[["level"]] %>%
    select(starts_with("stat_")) %>%
    colnames()

  raw_table[["level"]] <- raw_table[["level"]] %>%
    mutate(across(starts_with("stat_"), ~ as.numeric(sub(" .*", "", .)))) %>%
    countmaskr::mask_table(.,
      col_groups = list(cols),
      group_by = "variable",
      overwrite_columns = T,
      percentages = T
    ) %>%
    as_tibble()

  for (i in cols) {
    ith_perc <- paste0(i, "_perc_masked")
    raw_table[["level"]] <- raw_table[["level"]] %>%
      mutate(!!i := paste0(!!sym(i), " (", !!sym(ith_perc), ")"))
  }

  raw_table[["level"]] <- raw_table[["level"]] %>% select(variable, var_type, var_label, row_type, label, starts_with("stat_"), -ends_with("_masked"), -ends_with("_perc"), sort)

  cat_cont[["categorical"]] <- reduce(raw_table, rbind)

  gttbl$table_body <- reduce(cat_cont, rbind) %>%
    arrange(sort) %>%
    select(-sort)

  gttbl$table_styling$header <- gttbl$table_styling$header %>%
    mutate(
      modify_stat_n = case_when(
        str_detect(column, "stat_") ~ countmaskr::mask_counts(modify_stat_n),
        T ~ as.character(modify_stat_n)
      ),
      label = case_when(
        str_detect(column, "stat_") ~ sub(",.*", "", label),
        T ~ as.character(label)
      ),
      label = case_when(
        str_detect(column, "stat_") ~ paste0(label, ", N = ", modify_stat_n),
        T ~ as.character(label)
      )
    )

  return(gttbl)
}
