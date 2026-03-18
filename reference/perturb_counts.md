# Perturb Counts in a Vector with Small Cells

The `perturb_counts` function perturbs counts in a numeric vector
containing small cells, specifically when only one primary cell is
present and secondary cells need to be masked, following Algorithm 3
(A3). The function adjusts the counts by distributing noise to
non-primary cells while preserving the overall distribution as much as
possible.

## Usage

``` r
perturb_counts(x, threshold = 10)
```

## Arguments

- x:

  Numeric vector of length N containing counts.

- threshold:

  Numeric value specifying the threshold for small cells (primary
  cells). Defaults to 10.

## Value

A character vector with perturbed counts formatted with digit precision
and thousands separator. If perturbation is not feasible, the function
returns counts masked using
[`mask_counts()`](https://query-fulfillment.github.io/countmaskr/reference/mask_counts.md).

## Details

**Perturbation Process Overview:**

The function performs perturbation through the following steps:

1.  **Identification of Small Cells**: Cells with counts greater than 0
    and less than the specified `threshold` are identified as small
    cells (primary cells).

    \$\$\text{Small Cells} = \\ i \mid 0 \< x_i \< \text{threshold}
    \\\$\$

2.  **Adjustment of Small Cells**: The counts of small cells are set to
    the `threshold` value.

    \$\$x'\_i = \left\\ \begin{array}{ll} \text{threshold} & \text{if }
    x_i \text{ is a small cell} \\ x_i & \text{otherwise} \end{array}
    \right.\$\$

3.  **Calculation of Total Noise**: The total noise to be distributed is
    calculated as the difference between the original total sum and the
    adjusted sum.

    \$\$\text{Total Noise} = \sum\_{i=1}^{N} x_i - \sum\_{i=1}^{N}
    x'\_i\$\$

4.  **Distribution of Noise to Non-Small Cells**: The total noise is
    proportionally distributed to the non-small cells based on their
    original counts.

    - **Weights Calculation**: \$\$w_i = \frac{x_i}{\sum\_{j \in
      \text{Non-Small Cells}} x_j}\$\$

    - **Noise Allocation**: \$\$\text{Noise}\_i = w_i \times \text{Total
      Noise}\$\$

    - **Adjusted Counts**: \$\$x''\_i = x'\_i + \text{Noise}\_i\$\$

5.  **Rounding Adjusted Counts**: The adjusted counts are rounded to the
    nearest integer.

    \$\$x'''\_i = \text{round}(x''\_i)\$\$

6.  **Adjustment for Rounding Discrepancies**: Any remaining noise due
    to rounding discrepancies is adjusted by iteratively adding or
    subtracting 1 from the largest counts until the total counts are
    balanced, ensuring that no count falls below the `threshold`.

7.  **Verification of Proportions**: The function checks if the
    proportions of the non-small cells remain consistent before and
    after perturbation. If the proportions differ, the function coerces
    to mask counts using the
    [`mask_counts()`](https://query-fulfillment.github.io/countmaskr/reference/mask_counts.md)
    function.

**Coercion to Mask Counts:**

The function coerces to mask counts in the following scenarios:

- **Multiple Small Cells Detected**: If more than one small cell is
  identified, perturbation may not be necessary unless intended to use.
  The function will still proceed with perturbation but recommends using
  threshold-based suppression.

- **Insufficient Available Counts**: If the non-small cells do not have
  enough counts to absorb the total noise without any count falling
  below the `threshold`, the operation will lead to information loss.

- **Proportions Changed After Perturbation**: If perturbation alters the
  original proportions of the non-small cells, the operation will lead
  to information loss.

\#' - **All Counts Below Threshold**: If all counts in the vector are
below the specified `threshold`, there is no meaningful perturbation
possible. In this case, the function coerces to
[`mask_counts()`](https://query-fulfillment.github.io/countmaskr/reference/mask_counts.md)
as a more secure alternative.

In these cases, the function calls
[`mask_counts()`](https://query-fulfillment.github.io/countmaskr/reference/mask_counts.md)
to apply threshold-based cell suppression as a more secure alternative.

## Examples

``` r
# Example vectors
x1 <- c(5, 11, 43, 55, 65, 121, 1213, 0, NA)
x2 <- c(1, 1, 1, 55, 65, 121, 1213, 0, NA)
x3 <- c(11, 10, 10, 55, 65, 121, 1213, 0, NA)

# Apply the function
lapply(list(x1, x2, x3), perturb_counts)
#> Warning: Total primary cells: 3. Threshold-based suppression is recommended. See mask_counts() & mask_counts_2()
#> [[1]]
#> [1] "10"    "11"    "43"    "55"    "65"    "121"   "1,208" "0"     NA     
#> 
#> [[2]]
#> [1] "10"    "10"    "10"    "54"    "64"    "119"   "1,190" "0"     NA     
#> 
#> [[3]]
#> [1] "11"    "10"    "10"    "55"    "65"    "121"   "1,213" "0"     NA     
#> 

# Using the function within a data frame
data("countmaskr_data")
aggregate_table <- countmaskr_data %>%
  select(-c(id, age)) %>%
  tidyr::gather(block, Characteristics) %>%
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

aggregate_table %>%
  group_by(block) %>%
  mutate(N_masked = perturb_counts(N))
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
#>  9 gender    Female                              728 728     
#> 10 gender    Male                                763 762     
#> 11 gender    Other                                 9 10      
#> 12 race      American Indian/ Pacific Islander    66 66      
#> 13 race      Asian                               215 214     
#> 14 race      Black                               453 452     
#> 15 race      Other                                 6 10      
#> 16 race      White                               760 758     
```
