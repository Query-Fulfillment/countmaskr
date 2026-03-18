# Apply Threshold-Based Masking to a Data Frame

The `mask_table` function applies threshold-based masking to specified
columns in a data frame. It uses the `mask_counts` function to mask
counts that are below a certain threshold, adhering to data privacy
requirements. The function can handle grouped data and calculate
percentages if required. It ensures convergence by checking specific
criteria after each iteration.

## Usage

``` r
mask_table(
  data,
  threshold = 11,
  col_groups,
  group_by = NULL,
  overwrite_columns = TRUE,
  percentages = FALSE,
  perc_decimal = 0,
  zero_masking = FALSE,
  secondary_cell = "min",
  .verbose = FALSE
)
```

## Arguments

- data:

  A data frame containing the counts to be masked. Must be a data frame.

- threshold:

  A positive numeric value specifying the threshold below which values
  must be suppressed. Default is 11.

- col_groups:

  A character vector or a list of character vectors, where each
  character vector specifies columns in `data` to which masking should
  be applied.

- group_by:

  An optional character string specifying a column name in `data` to
  group the data by before masking.

- overwrite_columns:

  Logical; if `TRUE`, the original columns are overwritten with masked
  counts. If `FALSE`, new columns are added with masked counts. Default
  is `TRUE`.

- percentages:

  Logical; if `TRUE`, percentages are calculated and masked accordingly.
  Default is `FALSE`.

- perc_decimal:

  = A positive numeric value specifying the decimals for percentages.
  Default is 0.

- zero_masking:

  Logical; if `TRUE`, zeros can be masked as secondary cells when
  present. Passed to `mask_counts`. Default is `FALSE`.

- secondary_cell:

  Character string specifying the method for selecting secondary cells
  when necessary. Options are `"min"`, `"max"`, or `"random"`. Passed to
  `mask_counts`. Default is `"min"`.

- .verbose:

  Logical; if `TRUE`, progress messages are printed during masking.
  Default is `FALSE`.

## Value

A data frame with masked counts in specified columns. If
`percentages = TRUE`, additional columns with percentages are added. The
structure of the returned data frame depends on the `overwrite_columns`
parameter.

## See also

[`mask_counts`](https://query-fulfillment.github.io/countmaskr/reference/mask_counts.md)

## Examples

``` r
data("countmaskr_data")

aggregate_table <- countmaskr_data %>%
  select(-c(id, age)) %>%
  gather(block, Characteristics) %>%
  group_by(block, Characteristics) %>%
  summarise(N = n()) %>%
  ungroup()
#> Warning: attributes are not identical across measure variables; they will be dropped
#> `summarise()` has regrouped the output.
#> ℹ Summaries were computed grouped by block and Characteristics.
#> ℹ Output is grouped by block.
#> ℹ Use `summarise(.groups = "drop_last")` to silence this message.
#> ℹ Use `summarise(.by = c(block, Characteristics))` for per-operation grouping
#>   (`?dplyr::dplyr_by`) instead.

mask_table(aggregate_table,
  group_by = "block",
  col_groups = list("N")
)
#> # A tibble: 16 × 3
#>    block     Characteristics                   N    
#>    <chr>     <chr>                             <chr>
#>  1 age_group 18-29                             243  
#>  2 age_group 30-39                             198  
#>  3 age_group 40-49                             215  
#>  4 age_group 50-64                             323  
#>  5 age_group 65+                               521  
#>  6 ethnicity Hispanic                          143  
#>  7 ethnicity Non-Hispanic                      1,346
#>  8 ethnicity Other                             11   
#>  9 gender    Female                            <730 
#> 10 gender    Male                              763  
#> 11 gender    Other                             <11  
#> 12 race      American Indian/ Pacific Islander <70  
#> 13 race      Asian                             215  
#> 14 race      Black                             453  
#> 15 race      Other                             <11  
#> 16 race      White                             760  

mask_table(aggregate_table,
  group_by = "block",
  col_groups = list("N"),
  overwrite_columns = FALSE,
  percentages = TRUE
)
#> # A tibble: 16 × 6
#>    block     Characteristics                     N N_masked N_perc N_perc_masked
#>    <chr>     <chr>                           <int> <chr>    <chr>  <chr>        
#>  1 age_group 18-29                             243 243      16 %   16 %         
#>  2 age_group 30-39                             198 198      13 %   13 %         
#>  3 age_group 40-49                             215 215      14 %   14 %         
#>  4 age_group 50-64                             323 323      22 %   22 %         
#>  5 age_group 65+                               521 521      35 %   35 %         
#>  6 ethnicity Hispanic                          143 143      10 %   10 %         
#>  7 ethnicity Non-Hispanic                     1346 1,346    90 %   90 %         
#>  8 ethnicity Other                              11 11       1 %    1 %          
#>  9 gender    Female                            728 <730     49 %   <49 %        
#> 10 gender    Male                              763 763      51 %   51 %         
#> 11 gender    Other                               9 <11      1 %    masked cell  
#> 12 race      American Indian/ Pacific Islan…    66 <70      4 %    <5 %         
#> 13 race      Asian                             215 215      14 %   14 %         
#> 14 race      Black                             453 453      30 %   30 %         
#> 15 race      Other                               6 <11      0 %    masked cell  
#> 16 race      White                             760 760      51 %   51 %         

countmaskr_data %>%
  count(race, gender) %>%
  pivot_wider(names_from = gender, values_from = n) %>%
  mutate(across(all_of(c("Male", "Other")), ~ ifelse(is.na(.), 0, .)),
    Overall = Female + Male + Other, .after = 1
  ) %>%
  countmaskr::mask_table(.,
    col_groups = list(c("Overall", "Female", "Male", "Other")),
    overwrite_columns = TRUE,
    percentages = FALSE
  )
#> # A tibble: 5 × 5
#>   race                              Overall Female Male  Other
#>   <chr>                             <chr>   <chr>  <chr> <chr>
#> 1 American Indian/ Pacific Islander 66      <30    <40   0    
#> 2 Asian                             215     <100   118   <11  
#> 3 Black                             453     <225   228   <11  
#> 4 Other                             NA      NA     <11   0    
#> 5 White                             760     379    <375  <11  
```
