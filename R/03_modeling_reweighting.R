library(dplyr)
library(tidymodels)
library(workflows)
library(parsnip)
library(recipes)
library(yardstick)
library(hardhat)

source("R/01_data_preparation.R")

build_recipe <- function(train_df) {
  recipe(Final_Decision ~ ., data = train_df) %>%
    update_role(Applicant_ID, Applicant_Name, new_role = "id") %>%
    step_impute_median(all_numeric_predictors()) %>%
    step_impute_mode(all_nominal_predictors()) %>%
    step_other(all_nominal_predictors(), threshold = 0.02) %>%
    step_dummy(all_nominal_predictors()) %>%
    step_zv(all_predictors())
}

compute_reweighting <- function(df) {
  group_outcome <- df %>%
    count(Gender, Final_Decision, name = "n") %>%
    mutate(weight = 1 / n)

  out <- df %>%
    left_join(group_outcome, by = c("Gender", "Final_Decision")) %>%
    mutate(weight = weight / mean(weight, na.rm = TRUE))

  hardhat::importance_weights(out$weight)
}

fit_and_score <- function(wf, train_df, test_df, label, case_weights = NULL) {
  if (!is.null(case_weights)) {
    train_df <- train_df %>% mutate(.case_weights = case_weights)
    wf <- wf %>%
      remove_recipe() %>%
      add_recipe(build_recipe(train_df)) %>%
      add_case_weights(.case_weights)
  }
  fit <- fit(wf, data = train_df)

  preds <- predict(fit, test_df, type = "prob") %>%
    bind_cols(predict(fit, test_df, type = "class")) %>%
    bind_cols(test_df %>% select(Final_Decision, Gender))

  metrics <- metric_set(accuracy, roc_auc, f_meas)(
    preds,
    truth = Final_Decision,
    estimate = .pred_class,
    .pred_Selected
  )

  list(label = label, fit = fit, predictions = preds, metrics = metrics)
}

train_models <- function(train_df, test_df) {
  rec <- build_recipe(train_df)

  logistic_spec <- logistic_reg() %>%
    set_engine("glm") %>%
    set_mode("classification")

  rf_spec <- rand_forest(trees = 500, mtry = tune(), min_n = tune()) %>%
    set_engine("ranger", importance = "impurity") %>%
    set_mode("classification")

  xgb_spec <- boost_tree(
    trees = 300,
    tree_depth = 6,
    learn_rate = 0.05,
    min_n = 5,
    loss_reduction = 0,
    sample_size = 0.8,
    mtry = tune()
  ) %>%
    set_engine("xgboost") %>%
    set_mode("classification")

  base_wf <- workflow() %>% add_recipe(rec)

  baseline <- fit_and_score(
    wf = base_wf %>% add_model(logistic_spec),
    train_df = train_df,
    test_df = test_df,
    label = "baseline_logistic"
  )

  weights <- compute_reweighting(train_df)

  mitigated_logit <- fit_and_score(
    wf = base_wf %>% add_model(logistic_spec),
    train_df = train_df,
    test_df = test_df,
    label = "mitigated_logistic_reweight",
    case_weights = weights
  )

  folds <- vfold_cv(train_df, v = 5, strata = Final_Decision)
  prep_rec <- prep(rec)
  baked_train <- bake(prep_rec, new_data = NULL)
  predictor_count <- ncol(baked_train) - 1
  max_mtry <- max(1L, predictor_count)

  rf_grid <- grid_regular(
    mtry(range = c(1L, max_mtry)),
    min_n(range = c(5L, 20L)),
    levels = 3
  )
  xgb_grid <- grid_regular(mtry(range = c(1L, max_mtry)), levels = 4)

  train_df_w <- train_df %>% mutate(.case_weights = weights)
  rec_w <- build_recipe(train_df_w)
  base_wf_w <- workflow() %>% add_recipe(rec_w) %>% add_case_weights(.case_weights)
  folds_w <- vfold_cv(train_df_w, v = 5, strata = Final_Decision)

  tuned_rf <- tune_grid(
    base_wf_w %>% add_model(rf_spec),
    resamples = folds_w,
    grid = rf_grid,
    metrics = metric_set(roc_auc, f_meas)
  )

  best_rf <- select_best(tuned_rf, metric = "roc_auc")
  final_rf_wf <- finalize_workflow(base_wf %>% add_model(rf_spec), best_rf)

  mitigated_rf <- fit_and_score(
    wf = final_rf_wf,
    train_df = train_df,
    test_df = test_df,
    label = "mitigated_rf_reweight",
    case_weights = weights
  )

  tuned_xgb <- tune_grid(
    base_wf_w %>% add_model(xgb_spec),
    resamples = folds_w,
    grid = xgb_grid,
    metrics = metric_set(roc_auc, f_meas)
  )

  best_xgb <- select_best(tuned_xgb, metric = "roc_auc")
  final_xgb_wf <- finalize_workflow(base_wf %>% add_model(xgb_spec), best_xgb)

  mitigated_xgb <- fit_and_score(
    wf = final_xgb_wf,
    train_df = train_df,
    test_df = test_df,
    label = "mitigated_xgb_reweight",
    case_weights = weights
  )

  list(
    recipe = rec,
    results = list(baseline, mitigated_logit, mitigated_rf, mitigated_xgb)
  )
}
