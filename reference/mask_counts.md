# Perform threshold-based cell masking with primary and secondary masking (Algorithm 1 - A1)

Identifies primary and secondary cells in a numeric vector and masks
them according to the specified threshold.

## Usage

``` r
mask_counts(x, threshold = 11, zero_masking = FALSE, secondary_cell = "min")
```

## Arguments

- x:

  A numeric vector.

- threshold:

  A positive numeric value specifying the threshold below which values
  must be suppressed. Default is 11.

- zero_masking:

  Logical; if `TRUE`, zeros can be masked as secondary cells when
  present. Default is `FALSE`.

- secondary_cell:

  Character string specifying the method for selecting secondary cells
  when necessary. Options are `"min"`, `"max"`, or `"random"`. Default
  is `"min"`.

## Value

A character vector with primary and/or secondary masked cells.

## Details

The function operates in two main steps: **primary masking** and
**secondary masking**.

**Primary Masking**: Values greater than 0 and less than the specified
`threshold` are considered primary cells. These values are masked by
replacing them with `<threshold`.

**Secondary Masking**: Secondary masking is applied to prevent the
deduction of masked primary cells from the totals. The logic for
identifying the need for secondary masking is based on the following
conditions:

- **Condition A**: Only one primary masked cell exists, and there are
  other counts greater than or equal to the threshold.

- **Condition B**: Two or more counts of 1 are masked, and there are
  other counts greater than or equal to the threshold.

- **Condition C**: The `threshold` is 11, and two or more counts of 10
  are masked, and there are other counts greater than or equal to the
  threshold.

If any of these conditions are met, secondary masking is performed as
follows:

- If `zero_masking` is `TRUE` and zeros are present in the data, one
  zero is randomly selected and masked as `<threshold`.

- If zeros are not to be masked or not present, a non-zero cell is
  selected for masking based on the `secondary_cell` parameter:

  - `"min"`: The smallest unmasked count greater than zero is selected.

  - `"max"`: The largest unmasked count is selected.

  - `"random"`: A random unmasked count is selected.

The selected secondary cell is then masked by calculating a new masking
threshold using the formula:

\$\$mask\\value = 5 \times \lceil (selected\\value + 1) / 5 \rceil\$\$

The formula calculates the masking threshold by first adding 1 to the
selected value, then dividing by 5, and rounding up to the nearest whole
number. This result is then multiplied by 5 to get the final
`mask_value`. Essentially, it rounds the selected value up to the next
multiple of 5 after incrementing it by 1.

The cell is then replaced with `<mask_value`.

## Examples

``` r
x1 <- c(5, 11, 43, 55, 65, 121, 1213, 0, NA)
x2 <- c(1, 1, 1, 55, 65, 121, 1213, 0, NA)
x3 <- c(11, 10, 10, 55, 65, 121, 1213, 0, NA)

mask_counts(x1)
#> [1] "<11"   "<15"   "43"    "55"    "65"    "121"   "1,213" "0"     NA     
mask_counts(x2)
#> [1] "<11"   "<11"   "<11"   "<60"   "65"    "121"   "1,213" "0"     NA     
mask_counts(x3)
#> [1] "<15"   "<11"   "<11"   "55"    "65"    "121"   "1,213" "0"     NA     

if (requireNamespace("dplyr", quietly = TRUE) && requireNamespace("tidyr", quietly = TRUE)) {
  data("countmaskr_data")

  aggregate_table <- countmaskr_data %>%
    dplyr::select(-c(id, age)) %>%
    tidyr::gather(block, Characteristics) %>%
    dplyr::group_by(block, Characteristics) %>%
    dplyr::summarise(N = dplyr::n()) %>%
    dplyr::ungroup()

  aggregate_table %>%
    dplyr::group_by(block) %>%
    dplyr::mutate(N_masked = mask_counts(N))
}
#> Warning: attributes are not identical across measure variables; they will be dropped
#> `summarise()` has regrouped the output.
#> ℹ Summaries were computed grouped by block and Characteristics.
#> ℹ Output is grouped by block.
#> ℹ Use `summarise(.groups = "drop_last")` to silence this message.
#> ℹ Use `summarise(.by = c(block, Characteristics))` for per-operation grouping
#>   (`?dplyr::dplyr_by`) instead.
#> # A tibble: 16 × 4
#> # Groups:   block [4]
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
#>  9 gender    Female                              728 <730    
#> 10 gender    Male                                763 763     
#> 11 gender    Other                                 9 <11     
#> 12 race      American Indian/ Pacific Islander    66 <70     
#> 13 race      Asian                               215 215     
#> 14 race      Black                               453 453     
#> 15 race      Other                                 6 <11     
#> 16 race      White                               760 760     
```
