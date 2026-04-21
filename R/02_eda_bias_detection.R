library(dplyr)
library(ggplot2)
library(tidyr)
library(corrplot)
library(DALEX)

source("R/01_data_preparation.R")

selection_rates_by_gender <- function(df) {
  df %>%
    group_by(Gender) %>%
    summarise(
      applicants = n(),
      selected = sum(Final_Decision == "Selected"),
      selection_rate = mean(Final_Decision == "Selected"),
      .groups = "drop"
    )
}

disparate_impact_ratio <- function(df) {
  rates <- selection_rates_by_gender(df)
  rates$selection_rate[rates$Gender == "Female"] / rates$selection_rate[rates$Gender == "Male"]
}

plot_selection_rates <- function(df) {
  rates <- selection_rates_by_gender(df)
  ggplot(rates, aes(x = Gender, y = selection_rate, fill = Gender)) +
    geom_col(width = 0.6) +
    geom_text(aes(label = scales::percent(selection_rate, accuracy = 0.1)), vjust = -0.3) +
    scale_y_continuous(labels = scales::percent_format()) +
    labs(title = "Selection Rate by Gender", y = "Selection Rate", x = NULL) +
    theme_minimal()
}

plot_distributions_by_gender <- function(df) {
  long_df <- df %>%
    select(Gender, CGPA, Skills_Score, Interview_Score) %>%
    pivot_longer(cols = -Gender, names_to = "Feature", values_to = "Value")

  ggplot(long_df, aes(x = Value, fill = Gender)) +
    geom_density(alpha = 0.4) +
    facet_wrap(~Feature, scales = "free", ncol = 1) +
    theme_minimal() +
    labs(title = "Feature Distributions by Gender")
}

plot_correlation_heatmap <- function(df) {
  num_df <- df %>%
    transmute(
      CGPA,
      Experience_Years,
      Skills_Score,
      Interview_Score,
      Selected = as.integer(Final_Decision == "Selected")
    )

  corr_mat <- cor(num_df, use = "complete.obs")
  corrplot(corr_mat, method = "color", type = "upper", addCoef.col = "black")
}

build_initial_dalex_explainer <- function(train_df) {
  baseline_model <- glm(
    Final_Decision ~ Gender + Education_Level + CGPA + Experience_Years +
      Job_Applied + Company + Skills_Score + Interview_Score,
    data = train_df,
    family = binomial()
  )

  explain(
    model = baseline_model,
    data = train_df %>% select(-Final_Decision, -Applicant_ID, -Applicant_Name),
    y = as.integer(train_df$Final_Decision == "Selected"),
    label = "baseline_glm"
  )
}
