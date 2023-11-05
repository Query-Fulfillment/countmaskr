
<!-- README.md is generated from README.Rmd. Please edit that file -->

# countmaskr

## Development Status

**Alpha Version**: Please be aware that this version is under active
development, and some features may be incomplete or subject to change.

<!-- badges: start -->
<!-- badges: end -->

## Overview

The goal of countmaskr is to automate small cell suppression in tabular
reports to reduce privacy risk.

### Definitions of small and secondary cells in one dimensional frequency table

### Original

| Age     | N                                          |
|:--------|:-------------------------------------------|
| 0 - 1   | <span style="color:red"> **4** </span>     |
| 2 - 9   | <span style="color:purple"> **71** </span> |
| 10 - 19 | 925                                        |
| 20 - 29 | 0                                          |
| 30 - 39 | 0                                          |

 

- <span style="color:red"> **small cell** </span> : A cell with a value
  below defined threshold which requires a suppression. Aka, a primary
  cell
- <span style="color:purple"> **secondary cell** </span> : A cell within
  the contingency table that would suppression to prevent reverse
  engineering of small(primary) cell through arithmetic operations

 

### Solution

| Age     | N                                            |
|:--------|:---------------------------------------------|
| 0 - 1   | <span style="color:red"> **\<11** </span>    |
| 2 - 9   | <span style="color:purple"> **\<80** </span> |
| 10 - 19 | 925                                          |
| 20 - 29 | 0                                            |
| 30 - 39 | 0                                            |

 

## Installation

You can install the **alpha** version of countmaskr from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("PEDSnet/countmaskr")
```

 

## Getting started

Data: mtcars

``` r
require(countmaskr)
require(tidyverse)
require(knitr)
```

 

## One dimensional frequency table

``` r
data(mtcars)

mtcars %>% count(gear) %>%
  kable()
```

| gear |   n |
|-----:|----:|
|    3 |  15 |
|    4 |  12 |
|    5 |   5 |

``` r
mtcars %>% count(gear) %>%
  mutate(n = mask_counts(n)) %>%
  kable()
```

| gear | n    |
|-----:|:-----|
|    3 | 15   |
|    4 | \<20 |
|    5 | \<11 |

## Two-by-two frequency table

### Example 1

``` r
data(melanoma,package = "boot")

melanoma_fctr <- melanoma %>%
  mutate(
    status = factor(status, levels = c(2, 1, 3), labels = c("Alive", "Melanoma death", "Non-melanoma death")),
    sex = factor(sex, levels = c(1, 0), labels = c("Male", "Female")),
    ulcer = factor(ulcer, levels = c(0, 1), labels = c("Absent", "Present"))
  ) 
```

#### Original

``` r
melanoma_fctr %>% count(status,ulcer) %>%
  pivot_wider(id_cols = 'status',
              names_from = 'ulcer',
              values_from = n) %>%
  kable()
```

| status             | Absent | Present |
|:-------------------|-------:|--------:|
| Alive              |     92 |      42 |
| Melanoma death     |     16 |      41 |
| Non-melanoma death |      7 |       7 |

#### Masked

``` r
melanoma_fctr %>% count(status,ulcer) %>%
  pivot_wider(id_cols = 'status',
              names_from = 'ulcer',
              values_from = n) %>%
  mask_table(col_groups = c("Absent","Present")) %>%
  kable()
```

| status             | Absent | Present |
|:-------------------|:-------|:--------|
| Alive              | 92     | 42      |
| Melanoma death     | \<20   | \<50    |
| Non-melanoma death | \<11   | \<11    |

### Example 2

``` r
 df <- tibble::tribble(
   ~block, ~Characteristics, ~group1, ~group2, ~group3, ~group4,
   "sex", "Male", 190, 1407, 8, 2,
   "sex", "Female", 17, 20, 511, 2,
   "sex", "Sex - Other", 15, 7, 6, 4,
   "race", "White", 102, 1385, 75, 1,
   "race", "African American / Black", 75, 30, 325, 0,
   "race", "Asian", 20, 9, 100, 2,
   "race", "Native American / Pacific Islander", 15, 10, 4, 3,
   "race", "Race - Other", 10, 0, 21, 2,
 ) %>%
   mutate(
     aggr_group_all = group1 + group2 + group3 + group4,
     aggr_group_1_2 = group1 + group2,
     aggr_group_3_4 = group3 + group4
   ) 
```

#### Orignial

``` r
df %>% kable()
```

| block | Characteristics                    | group1 | group2 | group3 | group4 | aggr_group_all | aggr_group_1_2 | aggr_group_3_4 |
|:------|:-----------------------------------|-------:|-------:|-------:|-------:|---------------:|---------------:|---------------:|
| sex   | Male                               |    190 |   1407 |      8 |      2 |           1607 |           1597 |             10 |
| sex   | Female                             |     17 |     20 |    511 |      2 |            550 |             37 |            513 |
| sex   | Sex - Other                        |     15 |      7 |      6 |      4 |             32 |             22 |             10 |
| race  | White                              |    102 |   1385 |     75 |      1 |           1563 |           1487 |             76 |
| race  | African American / Black           |     75 |     30 |    325 |      0 |            430 |            105 |            325 |
| race  | Asian                              |     20 |      9 |    100 |      2 |            131 |             29 |            102 |
| race  | Native American / Pacific Islander |     15 |     10 |      4 |      3 |             32 |             25 |              7 |
| race  | Race - Other                       |     10 |      0 |     21 |      2 |             33 |             10 |             23 |

#### Masked with additional new columns and percentage columns

``` r
 mask_table(df,
   group_by = "block",
   col_groups = list(
     c("aggr_group_1_2", "group1", "group2"),
     c("aggr_group_3_4", "group3", "group4")
   ),
   overwrite_columns = F,
   percentages = T
 ) %>%
  kable()
```

| block | Characteristics                    | group1 | group2 | group3 | group4 | aggr_group_all | aggr_group_1_2 | aggr_group_3_4 | aggr_group_1_2_perc_masked | group1_perc_masked | group2_perc_masked | aggr_group_1_2_masked | group1_masked | group2_masked | aggr_group_3_4_perc_masked | group3_perc_masked | group4_perc_masked | aggr_group_3_4_masked | group3_masked | group4_masked |
|:------|:-----------------------------------|-------:|-------:|-------:|-------:|---------------:|---------------:|---------------:|:---------------------------|:-------------------|:-------------------|:----------------------|:--------------|:--------------|:---------------------------|:-------------------|:-------------------|:----------------------|:--------------|:--------------|
| race  | White                              |    102 |   1385 |     75 |      1 |           1563 |           1487 |             76 | 90 %                       | 46 %               | 97 %               | 1,487                 | 102           | 1,385         | 14 %                       | \<15 %             | masked cell        | 76                    | \<80          | \<11          |
| race  | African American / Black           |     75 |     30 |    325 |      0 |            430 |            105 |            325 | 6 %                        | 34 %               | 2 %                | 105                   | 75            | 30            | 61 %                       | 62 %               | 0 %                | 325                   | 325           | 0             |
| race  | Asian                              |     20 |      9 |    100 |      2 |            131 |             29 |            102 | 2 %                        | \<14 %             | masked cell        | 29                    | \<30          | \<11          | 19 %                       | masked cell        | masked cell        | 102                   | \<110         | \<11          |
| race  | Native American / Pacific Islander |     15 |     10 |      4 |      3 |             32 |             25 |              7 | \<2 %                      | \<9 %              | masked cell        | \<30                  | \<20          | \<11          | masked cell                | masked cell        | masked cell        | \<11                  | \<11          | \<11          |
| race  | Race - Other                       |     10 |      0 |     21 |      2 |             33 |             10 |             23 | masked cell                | masked cell        | 0 %                | \<11                  | \<11          | 0             | \<6 %                      | \<6 %              | masked cell        | \<30                  | \<30          | \<11          |
| sex   | Male                               |    190 |   1407 |      8 |      2 |           1607 |           1597 |             10 | 96 %                       | 86 %               | 98 %               | 1,597                 | 190           | 1,407         | masked cell                | masked cell        | masked cell        | \<11                  | \<11          | \<11          |
| sex   | Female                             |     17 |     20 |    511 |      2 |            550 |             37 |            513 | 2 %                        | \<9 %              | \<2 %              | 37                    | \<20          | \<30          | 96 %                       | \<99 %             | masked cell        | 513                   | \<520         | \<11          |
| sex   | Sex - Other                        |     15 |      7 |      6 |      4 |             32 |             22 |             10 | 1 %                        | \<9 %              | masked cell        | 22                    | \<20          | \<11          | masked cell                | masked cell        | masked cell        | \<11                  | \<11          | \<11          |

# {placeholder for grant related information}

This package was developed to support activities of the PCORnet Query
Fulfillment team as well as to support research conducted within
PEDSnet, A Pediatric Clinical Research Network. PCORnet Query
Fulfillment is funded through Patient-Centered Outcomes Research
Institute (PCORI) award RI-CHOP-01-PS2. PEDSnet has been developed with
funding from the PCORI; PEDSnet’s participation in PCORnet is funded
through PCORI award RI-CHOP-01-PS1.

The package and its documentation do not necessarily represent PCORI or
other organizations participating in, collaborating with, or funding
PCORnet.
