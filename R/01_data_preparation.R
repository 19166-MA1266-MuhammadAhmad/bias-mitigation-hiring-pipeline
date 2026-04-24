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

prepare_dataset3 <- function(path = 'data/job fair dataset.csv') {
  df <- readr::read_csv(path, show_col_types = FALSE)

  df <- df %>%
    filter(Gender %in% c('Man', 'Woman')) %>%
    mutate(
      Gender = if_else(Gender == 'Man', 1L, 0L),
      Employed = as.integer(Employed),
      EdLevel = as.factor(EdLevel),
      Age = as.factor(Age),
      MentalHealth = if_else(MentalHealth == 'Yes', 1L, 0L),
      Employment = as.integer(Employment),
      YearsCode = suppressWarnings(as.numeric(YearsCode)),
      YearsCodePro = suppressWarnings(as.numeric(YearsCodePro))
    ) %>%
    select(Age, EdLevel, Employment, Gender, MentalHealth,
           YearsCode, YearsCodePro, PreviousSalary, ComputerSkills, Employed) %>%
    filter(complete.cases(.))

  if (nrow(df) > 2000) {
    df <- df %>% slice_sample(n = 2000)
  }

  df
}

split_dataset <- function(df, outcome_col) {
  # 70/15/15 train-validation-test split
  split1 <- rsample::initial_split(df, prop = 0.7, strata = !!rlang::sym(outcome_col))
  train <- rsample::training(split1)
  remaining <- rsample::testing(split1)

  split2 <- rsample::initial_split(remaining, prop = 0.5, strata = !!rlang::sym(outcome_col))
  validation <- rsample::training(split2)
  test <- rsample::testing(split2)

  list(train = train, validation = validation, test = test)
}

dataset1 <- prepare_dataset1()
dataset2 <- prepare_dataset2()
dataset3 <- prepare_dataset3()

split1 <- split_dataset(dataset1, 'Final_Decision')
split2 <- split_dataset(dataset2, 'HiringDecision')
split3 <- split_dataset(dataset3, 'Employed')

saveRDS(split1, 'data/prepared/dataset1_split.rds')
saveRDS(split2, 'data/prepared/dataset2_split.rds')
saveRDS(split3, 'data/prepared/dataset3_split.rds')
saveRDS(dataset1, 'data/prepared/dataset1_full.rds')
saveRDS(dataset2, 'data/prepared/dataset2_full.rds')
saveRDS(dataset3, 'data/prepared/dataset3_full.rds')

message('Prepared and saved all three datasets with 70/15/15 splits.')
