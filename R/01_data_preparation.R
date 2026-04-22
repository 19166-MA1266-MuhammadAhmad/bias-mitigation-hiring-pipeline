suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(rsample)
})

set.seed(1266)

dir.create('data/prepared', recursive = TRUE, showWarnings = FALSE)

prepare_dataset1 <- function(path = 'data/final_bias_hiring_dataset.csv') {
  df <- readr::read_csv(path, show_col_types = FALSE)

  df %>%
    mutate(
      Gender = if_else(Gender == 'Male', 1L, 0L),
      Education_Level = factor(Education_Level, levels = c('Bachelors', 'Masters')),
      Final_Decision = if_else(Final_Decision == 'Selected', 1L, 0L)
    ) %>%
    select(-Applicant_ID, -Applicant_Name, -University, -Company, -Job_Applied)
}

prepare_dataset2 <- function(path = 'data/data.csv') {
  readr::read_csv(path, show_col_types = FALSE) %>%
    mutate(
      Gender = as.integer(Gender),
      HiringDecision = as.integer(HiringDecision),
      EducationLevel = as.factor(EducationLevel),
      RecruitmentStrategy = as.factor(RecruitmentStrategy)
    )
}

split_dataset <- function(df, outcome_col) {
  split <- rsample::initial_split(df, prop = 0.7, strata = !!rlang::sym(outcome_col))
  list(
    split = split,
    train = rsample::training(split),
    test = rsample::testing(split)
  )
}

dataset1 <- prepare_dataset1()
dataset2 <- prepare_dataset2()

split1 <- split_dataset(dataset1, 'Final_Decision')
split2 <- split_dataset(dataset2, 'HiringDecision')

saveRDS(split1, 'data/prepared/dataset1_split.rds')
saveRDS(split2, 'data/prepared/dataset2_split.rds')
saveRDS(dataset1, 'data/prepared/dataset1_full.rds')
saveRDS(dataset2, 'data/prepared/dataset2_full.rds')

message('Prepared and saved both datasets.')
