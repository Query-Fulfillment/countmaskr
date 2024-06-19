
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
data('countmaskr_data')

aggregate_table <- countmaskr_data %>%
  select(-c(id, age)) %>%
  gather(block, Characteristics) %>%
  group_by(block, Characteristics) %>%
  summarise(N = n()) %>%
  ungroup()
#> Warning: attributes are not identical across measure variables; they will be
#> dropped
```

### A1

``` r
aggregate_table %>%
  group_by(block) %>%
  mutate(N_masked = mask_counts(N))
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

### A2

``` r
aggregate_table %>%
  group_by(block) %>%
  mutate(N_masked = mask_counts_2(N))
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
#> 10 gender    Male                                763 >761    
#> 11 gender    Other                                 9 <11     
#> 12 race      American Indian/ Pacific Islander    66 66      
#> 13 race      Asian                               215 215     
#> 14 race      Black                               453 453     
#> 15 race      Other                                 6 <11     
#> 16 race      White                               760 >755
```

### A3

``` r
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

### Using `mask_table()`

mask_table() is intended multi-tasking function which allows for
masking, obtaining original and masked percentages on an aggregated
table.

#### Simple one-dimensional masking on the original column.

``` r
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
```

#### Simple one-dimensional masking while preserving original column and creating new masked columns

Naming convention for the masked columns follow {col}\_N_masked pattern.

``` r
mask_table(aggregate_table,
  group_by = "block",
  col_groups = list("N"),
  overwrite_columns = FALSE
)
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
#>  9 gender    Female                              728 <730    
#> 10 gender    Male                                763 763     
#> 11 gender    Other                                 9 <11     
#> 12 race      American Indian/ Pacific Islander    66 <70     
#> 13 race      Asian                               215 215     
#> 14 race      Black                               453 453     
#> 15 race      Other                                 6 <11     
#> 16 race      White                               760 760
```

#### Simple one-dimensional masking with computing original and masked percentages

Naming convention for the original and masked percentages follow
{col}\_perc and {col}\_perc_masked pattern.

``` r
mask_table(aggregate_table,
  group_by = "block",
  col_groups = list("N"),
  overwrite_columns = FALSE
)
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
#>  9 gender    Female                              728 <730    
#> 10 gender    Male                                763 763     
#> 11 gender    Other                                 9 <11     
#> 12 race      American Indian/ Pacific Islander    66 <70     
#> 13 race      Asian                               215 215     
#> 14 race      Black                               453 453     
#> 15 race      Other                                 6 <11     
#> 16 race      White                               760 760
```

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
  )
#> # A tibble: 5 × 5
#>   race                              Overall Female Male  Other
#>   <chr>                             <chr>   <chr>  <chr> <chr>
#> 1 American Indian/ Pacific Islander <70     29     <40   0    
#> 2 Asian                             215     <100   118   <11  
#> 3 Black                             453     <230   228   <11  
#> 4 Other                             <11     0      <11   0    
#> 5 White                             760     379    <380  <11
```

## Wrapper around [gtsummary](https://www.danieldsjoberg.com/gtsummary/)<sup>1</sup> package’s `tbl_summary()` function to obtain presentation-ready masked tables

``` r
aggregated_gtsummary_tbl <- countmaskr_data %>% select(-id) %>% gtsummary::tbl_summary()

mask_tbl_summary(aggregated_gtsummary_tbl)
```

<div id="epvfiuzfqr" style="padding-left:0px;padding-right:0px;padding-top:10px;padding-bottom:10px;overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>#epvfiuzfqr table {
  font-family: system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
&#10;#epvfiuzfqr thead, #epvfiuzfqr tbody, #epvfiuzfqr tfoot, #epvfiuzfqr tr, #epvfiuzfqr td, #epvfiuzfqr th {
  border-style: none;
}
&#10;#epvfiuzfqr p {
  margin: 0;
  padding: 0;
}
&#10;#epvfiuzfqr .gt_table {
  display: table;
  border-collapse: collapse;
  line-height: normal;
  margin-left: auto;
  margin-right: auto;
  color: #333333;
  font-size: 16px;
  font-weight: normal;
  font-style: normal;
  background-color: #FFFFFF;
  width: auto;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #A8A8A8;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #A8A8A8;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
}
&#10;#epvfiuzfqr .gt_caption {
  padding-top: 4px;
  padding-bottom: 4px;
}
&#10;#epvfiuzfqr .gt_title {
  color: #333333;
  font-size: 125%;
  font-weight: initial;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-color: #FFFFFF;
  border-bottom-width: 0;
}
&#10;#epvfiuzfqr .gt_subtitle {
  color: #333333;
  font-size: 85%;
  font-weight: initial;
  padding-top: 3px;
  padding-bottom: 5px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-color: #FFFFFF;
  border-top-width: 0;
}
&#10;#epvfiuzfqr .gt_heading {
  background-color: #FFFFFF;
  text-align: center;
  border-bottom-color: #FFFFFF;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
}
&#10;#epvfiuzfqr .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#epvfiuzfqr .gt_col_headings {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
}
&#10;#epvfiuzfqr .gt_col_heading {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: normal;
  text-transform: inherit;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: bottom;
  padding-top: 5px;
  padding-bottom: 6px;
  padding-left: 5px;
  padding-right: 5px;
  overflow-x: hidden;
}
&#10;#epvfiuzfqr .gt_column_spanner_outer {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: normal;
  text-transform: inherit;
  padding-top: 0;
  padding-bottom: 0;
  padding-left: 4px;
  padding-right: 4px;
}
&#10;#epvfiuzfqr .gt_column_spanner_outer:first-child {
  padding-left: 0;
}
&#10;#epvfiuzfqr .gt_column_spanner_outer:last-child {
  padding-right: 0;
}
&#10;#epvfiuzfqr .gt_column_spanner {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  vertical-align: bottom;
  padding-top: 5px;
  padding-bottom: 5px;
  overflow-x: hidden;
  display: inline-block;
  width: 100%;
}
&#10;#epvfiuzfqr .gt_spanner_row {
  border-bottom-style: hidden;
}
&#10;#epvfiuzfqr .gt_group_heading {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: middle;
  text-align: left;
}
&#10;#epvfiuzfqr .gt_empty_group_heading {
  padding: 0.5px;
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  vertical-align: middle;
}
&#10;#epvfiuzfqr .gt_from_md > :first-child {
  margin-top: 0;
}
&#10;#epvfiuzfqr .gt_from_md > :last-child {
  margin-bottom: 0;
}
&#10;#epvfiuzfqr .gt_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  margin: 10px;
  border-top-style: solid;
  border-top-width: 1px;
  border-top-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: middle;
  overflow-x: hidden;
}
&#10;#epvfiuzfqr .gt_stub {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-right-style: solid;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#epvfiuzfqr .gt_stub_row_group {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-right-style: solid;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  padding-left: 5px;
  padding-right: 5px;
  vertical-align: top;
}
&#10;#epvfiuzfqr .gt_row_group_first td {
  border-top-width: 2px;
}
&#10;#epvfiuzfqr .gt_row_group_first th {
  border-top-width: 2px;
}
&#10;#epvfiuzfqr .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#epvfiuzfqr .gt_first_summary_row {
  border-top-style: solid;
  border-top-color: #D3D3D3;
}
&#10;#epvfiuzfqr .gt_first_summary_row.thick {
  border-top-width: 2px;
}
&#10;#epvfiuzfqr .gt_last_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#epvfiuzfqr .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#epvfiuzfqr .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}
&#10;#epvfiuzfqr .gt_last_grand_summary_row_top {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: double;
  border-bottom-width: 6px;
  border-bottom-color: #D3D3D3;
}
&#10;#epvfiuzfqr .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}
&#10;#epvfiuzfqr .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#epvfiuzfqr .gt_footnotes {
  color: #333333;
  background-color: #FFFFFF;
  border-bottom-style: none;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
}
&#10;#epvfiuzfqr .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#epvfiuzfqr .gt_sourcenotes {
  color: #333333;
  background-color: #FFFFFF;
  border-bottom-style: none;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
}
&#10;#epvfiuzfqr .gt_sourcenote {
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#epvfiuzfqr .gt_left {
  text-align: left;
}
&#10;#epvfiuzfqr .gt_center {
  text-align: center;
}
&#10;#epvfiuzfqr .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}
&#10;#epvfiuzfqr .gt_font_normal {
  font-weight: normal;
}
&#10;#epvfiuzfqr .gt_font_bold {
  font-weight: bold;
}
&#10;#epvfiuzfqr .gt_font_italic {
  font-style: italic;
}
&#10;#epvfiuzfqr .gt_super {
  font-size: 65%;
}
&#10;#epvfiuzfqr .gt_footnote_marks {
  font-size: 75%;
  vertical-align: 0.4em;
  position: initial;
}
&#10;#epvfiuzfqr .gt_asterisk {
  font-size: 100%;
  vertical-align: 0;
}
&#10;#epvfiuzfqr .gt_indent_1 {
  text-indent: 5px;
}
&#10;#epvfiuzfqr .gt_indent_2 {
  text-indent: 10px;
}
&#10;#epvfiuzfqr .gt_indent_3 {
  text-indent: 15px;
}
&#10;#epvfiuzfqr .gt_indent_4 {
  text-indent: 20px;
}
&#10;#epvfiuzfqr .gt_indent_5 {
  text-indent: 25px;
}
</style>
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
