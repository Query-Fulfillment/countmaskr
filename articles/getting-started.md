# Getting Started

``` r
library(countmaskr)
#> Loading required package: dplyr
#> 
#> Attaching package: 'dplyr'
#> The following objects are masked from 'package:stats':
#> 
#>     filter, lag
#> The following objects are masked from 'package:base':
#> 
#>     intersect, setdiff, setequal, union
#> Loading required package: tibble
#> Loading required package: tidyr
library(knitr)
```

 

## Code logic plot

![](logic_plot.png)

 

## One dimensional frequency table

``` r
data("countmaskr_data")

aggregate_table <- countmaskr_data %>%
  select(-c(id, age)) %>%
  gather(block, Characteristics) %>%
  group_by(block, Characteristics) %>%
  summarise(N = n()) %>%
  ungroup()
```

 

### Algorithm 1

| block     | Characteristics                   |    N | N_masked |
|:----------|:----------------------------------|-----:|:---------|
| age_group | 18-29                             |  243 | 243      |
| age_group | 30-39                             |  198 | 198      |
| age_group | 40-49                             |  215 | 215      |
| age_group | 50-64                             |  323 | 323      |
| age_group | 65+                               |  521 | 521      |
| ethnicity | Hispanic                          |  143 | 143      |
| ethnicity | Non-Hispanic                      | 1346 | 1,346    |
| ethnicity | Other                             |   11 | 11       |
| gender    | Female                            |  728 | \<730    |
| gender    | Male                              |  763 | 763      |
| gender    | Other                             |    9 | \<11     |
| race      | American Indian/ Pacific Islander |   66 | \<70     |
| race      | Asian                             |  215 | 215      |
| race      | Black                             |  453 | 453      |
| race      | Other                             |    6 | \<11     |
| race      | White                             |  760 | 760      |

 

- `aggregate_table`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)` `` `[`group_by`](https://dplyr.tidyverse.org/reference/group_by.html)`(``block``)`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)` `` `[`mutate`](https://dplyr.tidyverse.org/reference/mutate.html)`(``N_masked ``=`` `[`mask_counts`](https://query-fulfillment.github.io/countmaskr/reference/mask_counts.md)`(``N``)``)`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)` `` `[`kable`](https://rdrr.io/pkg/knitr/man/kable.html)`(``)`

### Algorithm 2

``` r
aggregate_table %>%
  group_by(block) %>%
  mutate(N_masked = mask_counts_2(N)) %>%
  kable()
```

| block     | Characteristics                   |    N | N_masked |
|:----------|:----------------------------------|-----:|:---------|
| age_group | 18-29                             |  243 | 243      |
| age_group | 30-39                             |  198 | 198      |
| age_group | 40-49                             |  215 | 215      |
| age_group | 50-64                             |  323 | 323      |
| age_group | 65+                               |  521 | 521      |
| ethnicity | Hispanic                          |  143 | 143      |
| ethnicity | Non-Hispanic                      | 1346 | 1,346    |
| ethnicity | Other                             |   11 | 11       |
| gender    | Female                            |  728 | 728      |
| gender    | Male                              |  763 | \>761    |
| gender    | Other                             |    9 | \<11     |
| race      | American Indian/ Pacific Islander |   66 | 66       |
| race      | Asian                             |  215 | 215      |
| race      | Black                             |  453 | 453      |
| race      | Other                             |    6 | \<11     |
| race      | White                             |  760 | \>755    |

 

### Algorithm 3

``` r
aggregate_table %>%
  group_by(block) %>%
  mutate(N_masked = perturb_counts(N)) %>%
  kable()
```

| block     | Characteristics                   |    N | N_masked |
|:----------|:----------------------------------|-----:|:---------|
| age_group | 18-29                             |  243 | 243      |
| age_group | 30-39                             |  198 | 198      |
| age_group | 40-49                             |  215 | 215      |
| age_group | 50-64                             |  323 | 323      |
| age_group | 65+                               |  521 | 521      |
| ethnicity | Hispanic                          |  143 | 143      |
| ethnicity | Non-Hispanic                      | 1346 | 1,346    |
| ethnicity | Other                             |   11 | 11       |
| gender    | Female                            |  728 | 728      |
| gender    | Male                              |  763 | 762      |
| gender    | Other                             |    9 | 10       |
| race      | American Indian/ Pacific Islander |   66 | 66       |
| race      | Asian                             |  215 | 214      |
| race      | Black                             |  453 | 452      |
| race      | Other                             |    6 | 10       |
| race      | White                             |  760 | 758      |

:::

 

### Using `mask_table()`

mask_table() is a multi-tasking function which allows for masking,
obtaining original and masked percentages on an aggregated table.

#### One-dimensional masking on the original column.

``` r
mask_table(aggregate_table, group_by = "block", col_groups = list("N")) %>%
  kable()
```

| block     | Characteristics                   | N     |
|:----------|:----------------------------------|:------|
| age_group | 18-29                             | 243   |
| age_group | 30-39                             | 198   |
| age_group | 40-49                             | 215   |
| age_group | 50-64                             | 323   |
| age_group | 65+                               | 521   |
| ethnicity | Hispanic                          | 143   |
| ethnicity | Non-Hispanic                      | 1,346 |
| ethnicity | Other                             | 11    |
| gender    | Female                            | \<730 |
| gender    | Male                              | 763   |
| gender    | Other                             | \<11  |
| race      | American Indian/ Pacific Islander | \<70  |
| race      | Asian                             | 215   |
| race      | Black                             | 453   |
| race      | Other                             | \<11  |
| race      | White                             | 760   |

#### One-way masking while preserving original column and creating new masked columns

Naming convention for the masked columns follow {col}\_N_masked pattern.

``` r
mask_table(
  aggregate_table,
  group_by = "block",
  col_groups = list("N"),
  overwrite_columns = FALSE
) %>%
  kable()
```

| block     | Characteristics                   |    N | N_masked |
|:----------|:----------------------------------|-----:|:---------|
| age_group | 18-29                             |  243 | 243      |
| age_group | 30-39                             |  198 | 198      |
| age_group | 40-49                             |  215 | 215      |
| age_group | 50-64                             |  323 | 323      |
| age_group | 65+                               |  521 | 521      |
| ethnicity | Hispanic                          |  143 | 143      |
| ethnicity | Non-Hispanic                      | 1346 | 1,346    |
| ethnicity | Other                             |   11 | 11       |
| gender    | Female                            |  728 | \<730    |
| gender    | Male                              |  763 | 763      |
| gender    | Other                             |    9 | \<11     |
| race      | American Indian/ Pacific Islander |   66 | \<70     |
| race      | Asian                             |  215 | 215      |
| race      | Black                             |  453 | 453      |
| race      | Other                             |    6 | \<11     |
| race      | White                             |  760 | 760      |

#### Owo-way masking with computing original and masked percentages

Naming convention for the original and masked percentages follow
{col}\_perc and {col}\_perc_masked pattern.

``` r
mask_table(
  aggregate_table,
  group_by = "block",
  col_groups = list("N"),
  overwrite_columns = TRUE,
  percentages = TRUE
) %>%
  kable()
```

| block     | Characteristics                   |    N | N_masked | N_perc | N_perc_masked |
|:----------|:----------------------------------|-----:|:---------|:-------|:--------------|
| age_group | 18-29                             |  243 | 243      | 16 %   | 16 %          |
| age_group | 30-39                             |  198 | 198      | 13 %   | 13 %          |
| age_group | 40-49                             |  215 | 215      | 14 %   | 14 %          |
| age_group | 50-64                             |  323 | 323      | 22 %   | 22 %          |
| age_group | 65+                               |  521 | 521      | 35 %   | 35 %          |
| ethnicity | Hispanic                          |  143 | 143      | 10 %   | 10 %          |
| ethnicity | Non-Hispanic                      | 1346 | 1,346    | 90 %   | 90 %          |
| ethnicity | Other                             |   11 | 11       | 1 %    | 1 %           |
| gender    | Female                            |  728 | \<730    | 49 %   | \<49 %        |
| gender    | Male                              |  763 | 763      | 51 %   | 51 %          |
| gender    | Other                             |    9 | \<11     | 1 %    | masked cell   |
| race      | American Indian/ Pacific Islander |   66 | \<70     | 4 %    | \<5 %         |
| race      | Asian                             |  215 | 215      | 14 %   | 14 %          |
| race      | Black                             |  453 | 453      | 30 %   | 30 %          |
| race      | Other                             |    6 | \<11     | 0 %    | masked cell   |
| race      | White                             |  760 | 760      | 51 %   | 51 %          |

## Two-way frequency table

``` r
two_way_freq_table <- countmaskr_data %>%
  count(race, gender) %>%
  pivot_wider(names_from = gender, values_from = n) %>%
  mutate(
    across(all_of(c("Female", "Male", "Other")), ~ ifelse(is.na(.), 0, .)),
    Overall = Female + Male + Other,
    .after = 1
  )

mask_table(
  two_way_freq_table,
  col_groups = list(c("Overall", "Female", "Male", "Other")),
  overwrite_columns = TRUE,
  percentages = FALSE
) %>%
  kable()
```

| race                              | Overall | Female | Male  | Other |
|:----------------------------------|:--------|:-------|:------|:------|
| American Indian/ Pacific Islander | \<70    | 29     | \<40  | 0     |
| Asian                             | 215     | \<100  | 118   | \<11  |
| Black                             | 453     | \<225  | 228   | \<11  |
| Other                             | \<11    | 0      | \<11  | 0     |
| White                             | 760     | 379    | \<375 | \<11  |
