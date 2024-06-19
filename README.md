
<!-- README.md is generated from README.Rmd. Please edit that file -->

# countmaskr

## Development Status

**Beta Version**: Please be aware that this version is under active
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

``` r
require(countmaskr)
require(tidyverse)
require(knitr)
```

 

## Code logic plot

![](logic_plot.png)

## One dimensional frequency table

``` r
data('countmaskr_data')

aggregate_table <- countmaskr_data %>%
  select(-c(id, age)) %>%
  gather(block, Characteristics) %>%
  group_by(block, Characteristics) %>%
  summarise(N = n()) %>%
  ungroup()
```

### A1

``` r
aggregate_table %>%
  group_by(block) %>%
  mutate(N_masked = mask_counts(N)) %>%
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

### A2

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

### A3

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

### Using `mask_table()`

mask_table() is intended multi-tasking function which allows for
masking, obtaining original and masked percentages on an aggregated
table.

#### Simple one-dimensional masking on the original column.

``` r
mask_table(aggregate_table,
  group_by = "block",
  col_groups = list("N")
) %>%
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

#### Simple one-dimensional masking while preserving original column and creating new masked columns

Naming convention for the masked columns follow {col}\_N_masked pattern.

``` r
mask_table(aggregate_table,
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

#### Simple one-dimensional masking with computing original and masked percentages

Naming convention for the original and masked percentages follow
{col}\_perc and {col}\_perc_masked pattern.

``` r
mask_table(aggregate_table,
  group_by = "block",
  col_groups = list("N"),
  overwrite_columns = TRUE,
  percentages = TRUE
) %>%
  kable()
```

| block     | Characteristics                   | N     | N_perc | N_perc_masked |
|:----------|:----------------------------------|:------|-------:|:--------------|
| age_group | 18-29                             | 243   |     16 | 16 %          |
| age_group | 30-39                             | 198   |     13 | 13 %          |
| age_group | 40-49                             | 215   |     14 | 14 %          |
| age_group | 50-64                             | 323   |     22 | 22 %          |
| age_group | 65+                               | 521   |     35 | 35 %          |
| ethnicity | Hispanic                          | 143   |     10 | 10 %          |
| ethnicity | Non-Hispanic                      | 1,346 |     90 | 90 %          |
| ethnicity | Other                             | 11    |      1 | 1 %           |
| gender    | Female                            | \<730 |     49 | \<49 %        |
| gender    | Male                              | 763   |     51 | 51 %          |
| gender    | Other                             | \<11  |      1 | masked cell   |
| race      | American Indian/ Pacific Islander | \<70  |      4 | \<5 %         |
| race      | Asian                             | 215   |     14 | 14 %          |
| race      | Black                             | 453   |     30 | 30 %          |
| race      | Other                             | \<11  |      0 | masked cell   |
| race      | White                             | 760   |     51 | 51 %          |

## Two-way frequency table

``` r
two_way_freq_table <- countmaskr_data %>%
  count(race, gender) %>%
  pivot_wider(names_from = gender, values_from = n) %>%
  mutate(across(all_of(c("Female","Male", "Other")), ~ ifelse(is.na(.), 0, .)),
    Overall = Female + Male + Other, .after = 1) 

mask_table(two_way_freq_table,
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
| Black                             | 453     | \<230  | 228   | \<11  |
| Other                             | \<11    | 0      | \<11  | 0     |
| White                             | 760     | 379    | \<380 | \<11  |

## Wrapper around [gtsummary](https://www.danieldsjoberg.com/gtsummary/)<sup>1</sup> package’s `tbl_summary()` function to obtain presentation-ready masked tables

``` r
aggregated_gtsummary_tbl <- countmaskr_data %>% select(-id) %>% gtsummary::tbl_summary()

mask_tbl_summary(aggregated_gtsummary_tbl)
```

<table class="gt_table" data-quarto-disable-processing="false" data-quarto-bootstrap="false">
  <thead>
    <tr class="gt_col_headings">
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" scope="col" id="&lt;strong&gt;Characteristic&lt;/strong&gt;"><strong>Characteristic</strong></th>
      <th class="gt_col_heading gt_columns_bottom_border gt_center" rowspan="1" colspan="1" scope="col" id="&lt;strong&gt;N = 1,500&lt;/strong&gt;&lt;span class=&quot;gt_footnote_marks&quot; style=&quot;white-space:nowrap;font-style:italic;font-weight:normal;&quot;&gt;&lt;sup&gt;1&lt;/sup&gt;&lt;/span&gt;"><strong>N = 1,500</strong><span class="gt_footnote_marks" style="white-space:nowrap;font-style:italic;font-weight:normal;"><sup>1</sup></span></th>
    </tr>
  </thead>
  <tbody class="gt_table_body">
    <tr><td headers="label" class="gt_row gt_left">age</td>
<td headers="stat_0" class="gt_row gt_center">53 (36, 72)</td></tr>
    <tr><td headers="label" class="gt_row gt_left">gender</td>
<td headers="stat_0" class="gt_row gt_center"><br /></td></tr>
    <tr><td headers="label" class="gt_row gt_left">    Female</td>
<td headers="stat_0" class="gt_row gt_center">&lt;730 (&lt;49 %)</td></tr>
    <tr><td headers="label" class="gt_row gt_left">    Male</td>
<td headers="stat_0" class="gt_row gt_center">763 (51 %)</td></tr>
    <tr><td headers="label" class="gt_row gt_left">    Other</td>
<td headers="stat_0" class="gt_row gt_center">&lt;11 (masked cell)</td></tr>
    <tr><td headers="label" class="gt_row gt_left">race</td>
<td headers="stat_0" class="gt_row gt_center"><br /></td></tr>
    <tr><td headers="label" class="gt_row gt_left">    American Indian/ Pacific Islander</td>
<td headers="stat_0" class="gt_row gt_center">&lt;70 (&lt;5 %)</td></tr>
    <tr><td headers="label" class="gt_row gt_left">    Asian</td>
<td headers="stat_0" class="gt_row gt_center">215 (14 %)</td></tr>
    <tr><td headers="label" class="gt_row gt_left">    Black</td>
<td headers="stat_0" class="gt_row gt_center">453 (30 %)</td></tr>
    <tr><td headers="label" class="gt_row gt_left">    Other</td>
<td headers="stat_0" class="gt_row gt_center">&lt;11 (masked cell)</td></tr>
    <tr><td headers="label" class="gt_row gt_left">    White</td>
<td headers="stat_0" class="gt_row gt_center">760 (51 %)</td></tr>
    <tr><td headers="label" class="gt_row gt_left">ethnicity</td>
<td headers="stat_0" class="gt_row gt_center"><br /></td></tr>
    <tr><td headers="label" class="gt_row gt_left">    Hispanic</td>
<td headers="stat_0" class="gt_row gt_center">143 (10 %)</td></tr>
    <tr><td headers="label" class="gt_row gt_left">    Non-Hispanic</td>
<td headers="stat_0" class="gt_row gt_center">1,346 (90 %)</td></tr>
    <tr><td headers="label" class="gt_row gt_left">    Other</td>
<td headers="stat_0" class="gt_row gt_center">11 (1 %)</td></tr>
    <tr><td headers="label" class="gt_row gt_left">age_group</td>
<td headers="stat_0" class="gt_row gt_center"><br /></td></tr>
    <tr><td headers="label" class="gt_row gt_left">    18-29</td>
<td headers="stat_0" class="gt_row gt_center">243 (16 %)</td></tr>
    <tr><td headers="label" class="gt_row gt_left">    30-39</td>
<td headers="stat_0" class="gt_row gt_center">198 (13 %)</td></tr>
    <tr><td headers="label" class="gt_row gt_left">    40-49</td>
<td headers="stat_0" class="gt_row gt_center">215 (14 %)</td></tr>
    <tr><td headers="label" class="gt_row gt_left">    50-64</td>
<td headers="stat_0" class="gt_row gt_center">323 (22 %)</td></tr>
    <tr><td headers="label" class="gt_row gt_left">    65+</td>
<td headers="stat_0" class="gt_row gt_center">521 (35 %)</td></tr>
  </tbody>
  &#10;  <tfoot class="gt_footnotes">
    <tr>
      <td class="gt_footnote" colspan="2"><span class="gt_footnote_marks" style="white-space:nowrap;font-style:italic;font-weight:normal;"><sup>1</sup></span> Median (IQR); n (%)</td>
    </tr>
  </tfoot>
</table>
</div>

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

# References

1.  Sjoberg DD, Whiting K, Curry M, Lavery JA, Larmarange J.
    Reproducible summary tables with the gtsummary package. The R
    Journal 2021;13:570–80. <https://doi.org/10.32614/RJ-2021-053>.
