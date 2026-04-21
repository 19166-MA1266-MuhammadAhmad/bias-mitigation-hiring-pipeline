library(dplyr)
library(readr)

source("R/01_data_preparation.R")
source("R/03_modeling_reweighting.R")
source("R/04_fairness_evaluation.R")

select_best_model <- function(results_obj) {
  model_tbl <- bind_rows(lapply(results_obj$results, function(x) {
    perf <- x$metrics %>%
      select(.metric, .estimate) %>%
      tidyr::pivot_wider(names_from = .metric, values_from = .estimate)

    fair <- fairness_metrics(x$predictions)

    bind_cols(
      tibble(model = x$label),
      perf,
      fair
    )
  }))

  score_tbl <- model_tbl %>%
    mutate(
      fairness_penalty = demographic_parity_difference + abs(1 - disparate_impact_ratio),
      overall_score = roc_auc + f_meas - fairness_penalty
    ) %>%
    arrange(desc(overall_score))

  best_label <- score_tbl$model[1]
  best_fit <- purrr::detect(results_obj$results, ~ .x$label == best_label)

  list(best = best_fit, score_table = score_tbl)
}

if (sys.nframe() == 0) {
  dir.create("models", recursive = TRUE, showWarnings = FALSE)

  df <- load_hiring_data()
  split_obj <- create_train_test_split(df)
  trained <- train_models(split_obj$train, split_obj$test)
  selected <- select_best_model(trained)

  saveRDS(selected$best$fit, "models/best_model.rds")
  saveRDS(trained$recipe, "models/recipe.rds")
  saveRDS(selected$score_table, "models/fairness_report.rds")

  message("Saved models/best_model.rds, models/recipe.rds, and models/fairness_report.rds")
}
