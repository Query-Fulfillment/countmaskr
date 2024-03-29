
<!-- README.md is generated from README.Rmd. Please edit that file -->

# countmaskr

## Development Status

**Alpha Version**: Please be aware that this version is under active
development, and some features may be incomplete or subject to change.

<!-- badges: start -->

[![Lifecycle:
stable](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.r-lib.org/articles/stages.html#stable)
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
devtools::install_github("Query-Fulfillment/countmaskr")
```

 

## Getting started

Data: mtcars

``` r
require(countmaskr)
require(tidyverse)
require(knitr)
```

 

## Code logic plot

![](logic_plot.png)

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
| Alive              | 92     | \<50    |
| Melanoma death     | \<20   | \<50    |
| Non-melanoma death | \<11   | \<11    |

### Example 2

``` r
df <- tibble::tribble(
~Characteristics, ~Overall, ~Male, ~Female,
"White", 1487, 102, 1385,
"African American / Black", 91, 75, 16,
"Asian", 33, 20, 13,
"Native American / Pacific Islander", 45, 15, 30,
"Race - Other", 22, 14, 8) %>%
  mutate(block = ifelse(Characteristics == 'Totals','tot','race'))
```

#### Orignial

``` r
df %>% kable()
```

| Characteristics                    | Overall | Male | Female | block |
|:-----------------------------------|--------:|-----:|-------:|:------|
| White                              |    1487 |  102 |   1385 | race  |
| African American / Black           |      91 |   75 |     16 | race  |
| Asian                              |      33 |   20 |     13 | race  |
| Native American / Pacific Islander |      45 |   15 |     30 | race  |
| Race - Other                       |      22 |   14 |      8 | race  |

#### Masked with additional new columns and percentage columns

``` r
 mask_table(df,
   col_groups = list(
     c("Overall","Male","Female")),
   overwrite_columns = F,
   percentages = T
 ) %>%
  kable()
```

| Characteristics                    | Overall | Male | Female | block | Overall_perc | Male_perc | Female_perc | Overall_perc_masked | Male_perc_masked | Female_perc_masked | Overall_masked | Male_masked | Female_masked |
|:-----------------------------------|--------:|-----:|-------:|:------|-------------:|----------:|------------:|:--------------------|:-----------------|:-------------------|:---------------|:------------|:--------------|
| White                              |    1487 |  102 |   1385 | race  |           89 |        45 |          95 | 89 %                | masked cell      | \<96 %             | 1,487          | \<110       | \<1,390       |
| African American / Black           |      91 |   75 |     16 | race  |            5 |        33 |           1 | 5 %                 | \<35 %           | \<1 %              | 91             | \<80        | \<20          |
| Asian                              |      33 |   20 |     13 | race  |            2 |         9 |           1 | \<2 %               | \<13 %           | \<1 %              | \<40           | \<30        | \<20          |
| Native American / Pacific Islander |      45 |   15 |     30 | race  |            3 |         7 |           2 | 3 %                 | \<9 %            | \<3 %              | 45             | \<20        | \<40          |
| Race - Other                       |      22 |   14 |      8 | race  |            1 |         6 |           1 | \<2 %               | \<9 %            | masked cell        | \<30           | \<20        | \<11          |

# Grants and funding

This package was developed to support activities of the PCORnet® Query
Fulfillment team as well as to support research conducted within
PEDSnet, A Pediatric Clinical Research Network. PCORnet® Query
Fulfillment is funded through Patient-Centered Outcomes Research
Institute (PCORI) award RI-CHOP-01-PS2. PEDSnet has been developed with
funding from the PCORI; PEDSnet’s participation in PCORnet is funded
through PCORI award RI-CHOP-01-PS1.

The package and its documentation do not necessarily represent the
opinions of PCORI or other organizations participating in, collaborating
with, or funding PCORnet®.
