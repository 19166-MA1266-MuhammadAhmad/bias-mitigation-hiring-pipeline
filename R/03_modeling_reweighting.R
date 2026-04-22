suppressPackageStartupMessages({
  library(dplyr)
  library(tidymodels)
  library(readr)
  library(workflows)
  library(parsnip)
  library(recipes)
  library(yardstick)
  library(hardhat)
})

set.seed(1266)
dir.create('models', showWarnings = FALSE, recursive = TRUE)

if (!file.exists('data/prepared/dataset1_split.rds') || !file.exists('data/prepared/dataset2_split.rds')) {
  source('R/01_data_preparation.R')
}

split1 <- readRDS('data/prepared/dataset1_split.rds')
split2 <- readRDS('data/prepared/dataset2_split.rds')

compute_weights <- function(df, group_col, outcome_col) {
  grp <- df %>% count(.data[[group_col]], .data[[outcome_col]], name = 'n')
  total <- nrow(df)
  grp <- grp %>% mutate(weight = total / (n() * n))
  df %>%
    left_join(grp, by = setNames(c(group_col, outcome_col), c(group_col, outcome_col))) %>%
    pull(weight)
}

fit_models <- function(train_df, test_df, outcome_col, group_col, dataset_name) {
  train_df <- train_df %>% mutate(!!outcome_col := factor(.data[[outcome_col]], levels = c(0, 1)))
  test_df <- test_df %>% mutate(!!outcome_col := factor(.data[[outcome_col]], levels = c(0, 1)))

  rec <- recipe(as.formula(paste(outcome_col, '~ .')), data = train_df) %>%
    step_dummy(all_nominal_predictors()) %>%
    step_zv(all_predictors()) %>%
    step_normalize(all_numeric_predictors())

  weights <- compute_weights(train_df %>% mutate(!!outcome_col := as.integer(as.character(.data[[outcome_col]]))), group_col, outcome_col)
  w <- hardhat::importance_weights(weights)

  spec_logit <- logistic_reg() %>% set_engine('glm') %>% set_mode('classification')
  spec_rf <- rand_forest(trees = 300) %>% set_engine('ranger', importance = 'impurity') %>% set_mode('classification')
  spec_xgb <- boost_tree(trees = 300, tree_depth = 6, learn_rate = 0.05) %>% set_engine('xgboost') %>% set_mode('classification')

  wf_logit <- workflow() %>% add_recipe(rec) %>% add_model(spec_logit)
  wf_rf <- workflow() %>% add_recipe(rec) %>% add_model(spec_rf)
  wf_xgb <- workflow() %>% add_recipe(rec) %>% add_model(spec_xgb)

  fitted <- list(
    baseline_logit = fit(wf_logit, data = train_df),
    mitigated_logit = fit(wf_logit, data = train_df, case_weights = w),
    mitigated_rf = fit(wf_rf, data = train_df, case_weights = w),
    mitigated_xgb = fit(wf_xgb, data = train_df, case_weights = w)
  )

  score_model <- function(model, model_name) {
    probs <- predict(model, test_df, type = 'prob')
    classes <- predict(model, test_df, type = 'class')
    preds <- bind_cols(test_df, probs, classes)
    tibble(
      dataset = dataset_name,
      model = model_name,
      accuracy = yardstick::accuracy_vec(preds[[outcome_col]], preds$.pred_class),
      auc = yardstick::roc_auc_vec(preds[[outcome_col]], preds$.pred_1, event_level = 'second'),
      f1 = yardstick::f_meas_vec(preds[[outcome_col]], preds$.pred_class, event_level = 'second')
    )
  }

  metrics <- bind_rows(
    score_model(fitted$baseline_logit, 'baseline_logit'),
    score_model(fitted$mitigated_logit, 'mitigated_logit'),
    score_model(fitted$mitigated_rf, 'mitigated_rf'),
    score_model(fitted$mitigated_xgb, 'mitigated_xgb')
  )

  list(models = fitted, metrics = metrics, recipe = rec, test = test_df, outcome_col = outcome_col, group_col = group_col)
}

result1 <- fit_models(split1$train, split1$test, 'Final_Decision', 'Gender', 'Dataset 1')
result2 <- fit_models(split2$train, split2$test, 'HiringDecision', 'Gender', 'Dataset 2')

write_csv(bind_rows(result1$metrics, result2$metrics), 'outputs/model_metrics_dual_dataset.csv')
saveRDS(result1, 'models/model_results_dataset1.rds')
saveRDS(result2, 'models/model_results_dataset2.rds')

message('Modeling complete for both datasets.')
