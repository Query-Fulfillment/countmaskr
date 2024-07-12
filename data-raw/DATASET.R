library(dplyr)
# Set seed for reproducibility
set.seed(123)

# Number of patients
sample_size <- 1500

# Probabilities adjusted to have "Other" less than 11 subjects
prob_other <- 10 / sample_size

# Generate synthetic data
data <- tibble(
  id = seq(1, sample_size), # Sequential patient IDs
  age = sample(18:90, sample_size, replace = TRUE), # Random ages between 18 and 90
  gender = sample(c("Male", "Female", "Other"), sample_size, replace = TRUE, prob = c(0.495, 0.495, prob_other)), # Adjusted probabilities for gender
  race = sample(c("White", "Black", "Asian", "American Indian/ Pacific Islander", "Other"), sample_size, replace = TRUE, prob = c(0.495, 0.3, 0.15, 0.05, prob_other)), # Adjusted probabilities for race
  ethnicity = sample(c("Hispanic", "Non-Hispanic", "Other"), sample_size, replace = TRUE, prob = c(0.1, 0.895, prob_other)) # Adjusted probabilities for ethnicity
) %>%
  mutate(age_group = cut(age, breaks = c(18, 30, 40, 50, 65, 91), right = FALSE, labels = c("18-29", "30-39", "40-49", "50-64", "65+")))


usethis::use_data(countmaskr_data, overwrite = TRUE)
