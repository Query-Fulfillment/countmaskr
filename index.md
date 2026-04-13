# countmaskr

## Motivation

The dissemination of aggregate health statistics derived from clinical
and administrative data carries an inherent tension between analytic
utility and patient confidentiality. When reported frequencies are
sufficiently small, individuals within a subgroup may be vulnerable to
re-identification — particularly in stratified or cross-tabulated
outputs where demographic, geographic, or clinical covariates intersect.
Such vulnerabilities have prompted formal regulatory responses,
culminating in data use agreement (DUA) obligations codified by federal
agencies and clinical research networks alike.

Federal agencies — including the
[CMS](https://resdac.org/articles/cms-cell-size-suppression-policy), the
[AHRQ](https://hcup-us.ahrq.gov/db/publishing.jsp), the
[NCI](https://healthcaredelivery.cancer.gov/seermedicare/obtain/use.html),
and the
[CDC](https://www.cdc.gov/united-states-cancer-statistics/technical-notes/suppression.html)
— each maintain formal small-cell suppression requirements as a
condition of data access and publication. Clinical research networks
similarly enforce these standards:
[PCORnet®](https://pcornet.org/wp-content/uploads/2022/01/PCORnet-Statement-on-Protecting-Patient-Privacy-2021-10-06-.pdf)
and
[PEDSnet](https://pedsnet.org/wp-content/uploads/2025/07/PEDSnet-Policies-v2025_Final-June-2025_06.09.2025.pdf)
both require a minimum cell-size threshold of 11 and 5 respectively
across all distributed data queries under their respective data sharing
agreements.

For studies spanning multiple reporting dimensions — such as stratified
demographic breakdowns or multi-site analyses — manually identifying and
suppressing all qualifying primary and complementary cells across large
tables is a cumbersome and error-prone process. `countmaskr` automates
this workflow end-to-end, enabling patient privacy as well as asists
end-users to meet their DUA obligations consistently and in a
reproducible manner across institutional data sharing pipelines.

## Definitions of small and secondary cells in one dimensional frequency table

### Original

| Age     | N        |
|:--------|:---------|
| 0 - 1   |  **4**   |
| 2 - 9   |  **71**  |
| 10 - 19 | 925      |
| 20 - 29 | 0        |
| 30 - 39 | 0        |

 

-  **small cell** : A cell with a value below defined threshold which
  requires a suppression. Aka, a primary cell
-  **secondary cell** : A cell within the contingency table that would
  suppression to prevent reverse engineering of small(primary) cell
  through arithmetic operations

 

### Solution

| Age     | N          |
|:--------|:-----------|
| 0 - 1   |  **\<11**  |
| 2 - 9   |  **\<80**  |
| 10 - 19 | 925        |
| 20 - 29 | 0          |
| 30 - 39 | 0          |

 

## Installation

You can install countmaskr from [GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("Query-Fulfillment/countmaskr")
```

or using [pak](https://pak.r-lib.org/)

``` r
# install.packages("pak")
pak::pkg_install("Query-Fulfillment/countmaskr")
```
