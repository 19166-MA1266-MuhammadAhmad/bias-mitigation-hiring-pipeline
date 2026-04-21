library(readr)
library(dplyr)
library(forcats)
library(rsample)

DATA_PATH <- "data/final_bias_hiring_dataset.csv"

load_hiring_data <- function(path = DATA_PATH) {
  df <- read_csv(path, show_col_types = FALSE)

  required_cols <- c(
    "Applicant_ID", "Applicant_Name", "Gender", "University", "Education_Level",
    "CGPA", "Experience_Years", "Job_Applied", "Company", "Skills_Score",
    "Interview_Score", "Final_Decision"
  )

  missing_cols <- setdiff(required_cols, colnames(df))
  if (length(missing_cols) > 0) {
    stop(sprintf("Missing required columns: %s", paste(missing_cols, collapse = ", ")))
  }

  df %>%
    mutate(
      Gender = factor(Gender, levels = c("Male", "Female")),
      Education_Level = factor(Education_Level),
      University = factor(University),
      Job_Applied = factor(Job_Applied),
      Company = factor(Company),
      Final_Decision = factor(Final_Decision, levels = c("Rejected", "Selected")),
      CGPA = as.numeric(CGPA),
      Experience_Years = as.numeric(Experience_Years),
      Skills_Score = as.numeric(Skills_Score),
      Interview_Score = as.numeric(Interview_Score)
    ) %>%
    mutate(
      across(where(is.character), ~ na_if(trimws(.x), "")),
      across(where(is.factor), ~ fct_na_value_to_level(.x, level = "Unknown"))
    ) %>%
    filter(!is.na(Final_Decision), !is.na(Gender)) %>%
    mutate(
      Final_Decision = factor(Final_Decision, levels = c("Rejected", "Selected")),
      Gender = factor(Gender, levels = c("Male", "Female"))
    )
}

create_train_test_split <- function(df, prop = 0.7, seed = 1266) {
  set.seed(seed)
  split <- initial_split(df, prop = prop, strata = Final_Decision)
  list(
    split = split,
    train = training(split),
    test = testing(split)
  )
}
