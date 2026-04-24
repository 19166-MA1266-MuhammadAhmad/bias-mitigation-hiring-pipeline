suppressPackageStartupMessages({
  library(dplyr)
  library(tidymodels)
  library(readr)
  library(workflows)
  library(parsnip)
  library(recipes)
  library(yardstick)
  library(hardhat)
  library(discrim)
})

set.seed(1266)
dir.create('models', showWarnings = FALSE, recursive = TRUE)

if (!file.exists('data/prepared/dataset1_split.rds') ||
    !file.exists('data/prepared/dataset2_split.rds') ||
    !file.exists('data/prepared/dataset3_split.rds')) {
  source('R/01_data_preparation.R')
}

split1 <- readRDS('data/prepared/dataset1_split.rds')
split2 <- readRDS('data/prepared/dataset2_split.rds')
split3 <- readRDS('data/prepared/dataset3_split.rds')

compute_weights <- function(df, group_col, outcome_col) {
  grp <- df %>% count(.data[[group_col]], .data[[outcome_col]], name = 'n')
  total <- nrow(df)
  grp <- grp %>% mutate(weight = total / (n() * n))
  df %>%
    left_join(grp, by = setNames(c(group_col, outcome_col), c(group_col, outcome_col))) %>%
    pull(weight)
}

resample_weighted <- function(df, weights) {
  probs <- weights / sum(weights)
  idx <- sample(seq_len(nrow(df)), size = nrow(df), replace = TRUE, prob = probs)
  df[idx, ]
}

fit_models <- function(train_df, val_df, test_df, outcome_col, group_col, dataset_name) {
  train_df <- train_df %>% mutate(!!outcome_col := factor(.data[[outcome_col]], levels = c(0, 1)))
  val_df   <- val_df   %>% mutate(!!outcome_col := factor(.data[[outcome_col]], levels = c(0, 1)))
  test_df  <- test_df  %>% mutate(!!outcome_col := factor(.data[[outcome_col]], levels = c(0, 1)))

  rec <- recipe(as.formula(paste(outcome_col, '~ .')), data = train_df) %>%
    step_dummy(all_nominal_predictors()) %>%
    step_zv(all_predictors()) %>%
    step_normalize(all_numeric_predictors())

  weights <- compute_weights(
    train_df %>% mutate(!!outcome_col := as.integer(as.character(.data[[outcome_col]]))),
    group_col, outcome_col
  )
  w <- hardhat::importance_weights(weights)

  train_w <- train_df %>% mutate(.case_weights = w)
  train_resampled <- resample_weighted(train_df, weights)

  rec_w <- recipe(as.formula(paste(outcome_col, '~ .')), data = train_w) %>%
    step_dummy(all_nominal_predictors()) %>%
    step_zv(all_predictors()) %>%
    step_normalize(all_numeric_predictors())

  # Model specifications
  spec_rf  <- rand_forest(trees = 300) %>%
    set_engine('ranger', importance = 'impurity') %>% set_mode('classification')
  spec_nb  <- naive_Bayes() %>%
    set_engine('naivebayes') %>% set_mode('classification')
  spec_knn <- nearest_neighbor(neighbors = 5) %>%
    set_engine('kknn') %>% set_mode('classification')

  # Workflows
  wf_rf_base <- workflow() %>% add_recipe(rec)  %>% add_model(spec_rf)
  wf_rf_w    <- workflow() %>% add_recipe(rec_w) %>% add_model(spec_rf) %>% add_case_weights(.case_weights)
  wf_nb      <- workflow() %>% add_recipe(rec)  %>% add_model(spec_nb)
  wf_knn     <- workflow() %>% add_recipe(rec)  %>% add_model(spec_knn)

  fitted <- list(
    baseline_rf   = fit(wf_rf_base, data = train_df),
    mitigated_rf  = fit(wf_rf_w,    data = train_w),
    mitigated_nb  = fit(wf_nb,      data = train_resampled),
    mitigated_knn = fit(wf_knn,     data = train_resampled)
  )

  score_model <- function(model, model_name, eval_df) {
    probs   <- predict(model, eval_df, type = 'prob')
    classes <- predict(model, eval_df, type = 'class')
    preds   <- bind_cols(eval_df, probs, classes)
    tibble(
      dataset  = dataset_name,
      model    = model_name,
      accuracy = yardstick::accuracy_vec(preds[[outcome_col]], preds$.pred_class),
      auc      = yardstick::roc_auc_vec(preds[[outcome_col]], preds$.pred_1, event_level = 'second'),
      f1       = yardstick::f_meas_vec(preds[[outcome_col]], preds$.pred_class, event_level = 'second')
    )
  }

  val_metrics <- bind_rows(
    score_model(fitted$baseline_rf,   'baseline_rf',   val_df),
    score_model(fitted$mitigated_rf,  'mitigated_rf',  val_df),
    score_model(fitted$mitigated_nb,  'mitigated_nb',  val_df),
    score_model(fitted$mitigated_knn, 'mitigated_knn', val_df)
  )

  test_metrics <- bind_rows(
    score_model(fitted$baseline_rf,   'baseline_rf',   test_df),
    score_model(fitted$mitigated_rf,  'mitigated_rf',  test_df),
    score_model(fitted$mitigated_nb,  'mitigated_nb',  test_df),
    score_model(fitted$mitigated_knn, 'mitigated_knn', test_df)
  )

  list(
    models      = fitted,
    metrics     = test_metrics,
    val_metrics = val_metrics,
    recipe      = rec,
    test        = test_df,
    validation  = val_df,
    outcome_col = outcome_col,
    group_col   = group_col
  )
}

result1 <- fit_models(split1$train, split1$validation, split1$test, 'Final_Decision', 'Gender', 'Dataset 1')
result2 <- fit_models(split2$train, split2$validation, split2$test, 'HiringDecision', 'Gender', 'Dataset 2')
result3 <- fit_models(split3$train, split3$validation, split3$test, 'Employed',        'Gender', 'Dataset 3')

write_csv(bind_rows(result1$metrics, result2$metrics, result3$metrics),
          'outputs/model_metrics_dual_dataset.csv')
saveRDS(result1, 'models/model_results_dataset1.rds')
saveRDS(result2, 'models/model_results_dataset2.rds')
saveRDS(result3, 'models/model_results_dataset3.rds')

message('Modeling complete for all three datasets.')
