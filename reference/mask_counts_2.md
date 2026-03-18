# Perform threshold-based cell masking with primary and secondary masking (Algorithm 2 - A2)

This function masks values in a numeric vector based on a specified
threshold, using primary and secondary masking to ensure data privacy.

## Usage

``` r
mask_counts_2(x, threshold = 11, zero_masking = FALSE)
```

## Arguments

- x:

  Numeric vector to mask.

- threshold:

  Positive numeric value for the threshold below which cells are masked.
  Default is 11.

- zero_masking:

  Logical; if `TRUE`, zeros may be masked as secondary cells if present.
  Default is `FALSE`.

## Value

A character vector with masked cells, retaining `NA` as `NA_character_`.

## Details

The function operates in two main steps:

- **Primary Masking**: Values greater than 0 but less than the threshold
  are masked by replacing them with `<threshold`.

- **Secondary Masking**: Applied when additional masking is required to
  prevent deduction of masked cells from totals. Secondary masking is
  triggered under the following conditions:

  - **Condition A**: A single primary masked cell exists, and there are
    other values that meet or exceed the threshold.

  - **Condition B**: Two or more counts of 1 are masked, with other
    values meeting or exceeding the threshold.

  - **Condition C**: The threshold is set to 11, with two or more counts
    of 10 masked and other counts meeting or exceeding the threshold.

If any of these conditions are met:

- When `zero_masking = TRUE` and zeros are present, one zero is randomly
  selected and masked as `<threshold`.

- When `zero_masking = FALSE` (or zeros are absent), the function masks
  the largest unmasked count (i.e., the maximum non-zero value).

**Formula for Mask Value Calculation**: To calculate the `mask_value`
for the secondary cell, the following formula is used: \$\$mask\\value =
selected\\value - (threshold - totals\\of\\small\\cells)\$\$

In words, this formula subtracts the difference between the threshold
and the sum of all small cells (those masked in the primary masking
step) from the selected maximum unmasked value. This adjusted
`mask_value` helps ensure privacy while retaining consistent totals.

## Examples

``` r
x1 <- c(5, 11, 43, 55, 65, 121, 1213, 0, NA)

mask_counts_2(x1)
#> [1] "<11"    "11"     "43"     "55"     "65"     "121"    ">1,207" "0"     
#> [9] NA      

if (requireNamespace("dplyr", quietly = TRUE) && requireNamespace("tidyr", quietly = TRUE)) {
  data("countmaskr_data")
  countmaskr_data %>%
    dplyr::select(-c(id, age)) %>%
    tidyr::gather(block, Characteristics) %>%
    dplyr::group_by(block, Characteristics) %>%
    dplyr::summarise(N = dplyr::n()) %>%
    dplyr::ungroup() %>%
    dplyr::mutate(N_masked = mask_counts_2(N))
}
#> Warning: attributes are not identical across measure variables; they will be dropped
#> `summarise()` has regrouped the output.
#> ℹ Summaries were computed grouped by block and Characteristics.
#> ℹ Output is grouped by block.
#> ℹ Use `summarise(.groups = "drop_last")` to silence this message.
#> ℹ Use `summarise(.by = c(block, Characteristics))` for per-operation grouping
#>   (`?dplyr::dplyr_by`) instead.
#> # A tibble: 16 × 4
#>    block     Characteristics                       N N_masked
#>    <chr>     <chr>                             <int> <chr>   
#>  1 age_group 18-29                               243 243     
#>  2 age_group 30-39                               198 198     
#>  3 age_group 40-49                               215 215     
#>  4 age_group 50-64                               323 323     
#>  5 age_group 65+                                 521 521     
#>  6 ethnicity Hispanic                            143 143     
#>  7 ethnicity Non-Hispanic                       1346 1,346   
#>  8 ethnicity Other                                11 11      
#>  9 gender    Female                              728 728     
#> 10 gender    Male                                763 763     
#> 11 gender    Other                                 9 <11     
#> 12 race      American Indian/ Pacific Islander    66 66      
#> 13 race      Asian                               215 215     
#> 14 race      Black                               453 453     
#> 15 race      Other                                 6 <11     
#> 16 race      White                               760 760     
```
