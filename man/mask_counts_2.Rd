% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/mask_counts_2.R
\name{mask_counts_2}
\alias{mask_counts_2}
\title{Function to perform threshold based cell masking - Algorithm 2 (A2)}
\usage{
mask_counts_2(x, threshold = 11)
}
\arguments{
\item{x}{vector of length N}

\item{threshold}{threshold below with the values must be suppressed}
}
\value{
a character vector with primary and/or secondary masked cell
}
\description{
This function is an adaptation of mask_count() but performs masking in a modified way. This masking prevents the total counts to exceed the original totals
}
\details{
\ifelse{html}{\href{https://lifecycle.r-lib.org/articles/stages.html#stable}{\figure{lifecycle-stable.svg}{options: alt='[Stable]'}}}{\strong{[Stable]}}
}
\examples{
x1 <- c(5, 11, 43, 55, 65, 121, 1213, 0, NA)
x2 <- c(1, 1, 1, 55, 65, 121, 1213, 0, NA)
x3 <- c(11, 10, 10, 55, 65, 121, 1213, 0, NA)


lapply(list(x1, x2, x3), mask_counts_2)

data("countmaskr_data")

aggregate_table <- countmaskr_data \%>\%
  select(-c(id, age)) \%>\%
  gather(block, Characteristics) \%>\%
  group_by(block, Characteristics) \%>\%
  summarise(N = n()) \%>\%
  ungroup()

aggregate_table \%>\%
  group_by(block) \%>\%
  mutate(N_masked = mask_counts_2(N))

}
