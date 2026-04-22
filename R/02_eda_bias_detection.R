suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(readr)
  library(tidyr)
})

dir.create('outputs/eda', recursive = TRUE, showWarnings = FALSE)

if (!file.exists('data/prepared/dataset1_full.rds') || !file.exists('data/prepared/dataset2_full.rds')) {
  source('R/01_data_preparation.R')
}

dataset1 <- readRDS('data/prepared/dataset1_full.rds')
dataset2 <- readRDS('data/prepared/dataset2_full.rds')

calc_di <- function(df, gender_col, outcome_col) {
  rates <- df %>%
    group_by(.data[[gender_col]]) %>%
    summarise(rate = mean(.data[[outcome_col]] == 1), .groups = 'drop') %>%
    arrange(.data[[gender_col]])
  if (nrow(rates) < 2) return(NA_real_)
  min(rates$rate) / max(rates$rate)
}

summary_d1 <- dataset1 %>% group_by(Gender) %>% summarise(across(where(is.numeric), mean), .groups = 'drop')
summary_d2 <- dataset2 %>% group_by(Gender) %>% summarise(across(where(is.numeric), mean), .groups = 'drop')

rates <- bind_rows(
  dataset1 %>% group_by(Gender) %>% summarise(rate = mean(Final_Decision), .groups = 'drop') %>% mutate(dataset = 'Dataset 1'),
  dataset2 %>% group_by(Gender) %>% summarise(rate = mean(HiringDecision), .groups = 'drop') %>% mutate(dataset = 'Dataset 2')
)

p_rates <- ggplot(rates, aes(x = factor(Gender), y = rate, fill = dataset)) +
  geom_col(position = 'dodge') +
  labs(title = 'Hiring/Selection Rate by Gender', x = 'Gender (0=Female, 1=Male)', y = 'Rate') +
  theme_minimal()

ggsave('outputs/eda/hiring_rates_by_gender.png', p_rates, width = 9, height = 5)

score_dist <- bind_rows(
  dataset1 %>% transmute(dataset = 'Dataset 1', Gender, score = Interview_Score),
  dataset2 %>% transmute(dataset = 'Dataset 2', Gender, score = InterviewScore)
)

p_scores <- ggplot(score_dist, aes(x = score, fill = factor(Gender))) +
  geom_density(alpha = 0.5) +
  facet_wrap(~dataset, scales = 'free') +
  labs(title = 'Interview Score Distribution by Gender', fill = 'Gender') +
  theme_minimal()

ggsave('outputs/eda/score_distribution_by_gender.png', p_scores, width = 9, height = 5)

cor_plot <- function(df, name) {
  cor_df <- df %>% select(where(is.numeric))
  cor_mat <- cor(cor_df)
  png(sprintf('outputs/eda/correlation_%s.png', name), width = 900, height = 700)
  heatmap(cor_mat, symm = TRUE)
  dev.off()
}

cor_plot(dataset1, 'dataset1')
cor_plot(dataset2, 'dataset2')

bias_summary <- tibble(
  dataset = c('Dataset 1', 'Dataset 2'),
  disparate_impact = c(calc_di(dataset1, 'Gender', 'Final_Decision'), calc_di(dataset2, 'Gender', 'HiringDecision'))
)

write_csv(summary_d1, 'outputs/eda/summary_by_gender_dataset1.csv')
write_csv(summary_d2, 'outputs/eda/summary_by_gender_dataset2.csv')
write_csv(bias_summary, 'outputs/eda/disparate_impact_summary.csv')

message('EDA and bias detection artifacts created for both datasets.')
