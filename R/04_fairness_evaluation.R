suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tibble)
  library(workflows)
  library(DALEX)
  library(fairmodels)
})

dir.create('outputs/fairness', recursive = TRUE, showWarnings = FALSE)

if (!file.exists('models/model_results_dataset1.rds') ||
    !file.exists('models/model_results_dataset2.rds') ||
    !file.exists('models/model_results_dataset3.rds')) {
  source('R/03_modeling_reweighting.R')
}

res1 <- readRDS('models/model_results_dataset1.rds')
res2 <- readRDS('models/model_results_dataset2.rds')
res3 <- readRDS('models/model_results_dataset3.rds')

fair_metrics <- function(actual, predicted, pred_prob, group) {
  g0 <- group == 0
  g1 <- group == 1

  rate0 <- mean(predicted[g0] == 1)
  rate1 <- mean(predicted[g1] == 1)

  tpr <- function(g) {
    idx <- g & actual == 1
    if (sum(idx) == 0) return(NA_real_)
    mean(predicted[idx] == 1)
  }
  fpr <- function(g) {
    idx <- g & actual == 0
    if (sum(idx) == 0) return(NA_real_)
    mean(predicted[idx] == 1)
  }

  # Calibration: difference in calibration error between groups
  cal0 <- abs(mean(pred_prob[g0]) - mean(actual[g0]))
  cal1 <- abs(mean(pred_prob[g1]) - mean(actual[g1]))

  tibble(
    demographic_parity = abs(rate1 - rate0),
    equalized_odds = max(abs(tpr(g1) - tpr(g0)), abs(fpr(g1) - fpr(g0)), na.rm = TRUE),
    disparate_impact_ratio = min(rate0, rate1) / max(rate0, rate1),
    calibration = abs(cal1 - cal0)
  )
}

evaluate_result <- function(res, dataset_name) {
  test_df <- res$test
  outcome <- res$outcome_col
  group   <- res$group_col

  eval_one <- function(model, model_name) {
    pred <- as.integer(as.character(predict(model, test_df, type = 'class')$.pred_class))
    pred_prob <- predict(model, test_df, type = 'prob')$.pred_1
    actual <- as.integer(as.character(test_df[[outcome]]))
    metrics <- fair_metrics(actual, pred, pred_prob, test_df[[group]])

    x <- test_df %>% select(-all_of(outcome))
    y <- actual
    pred_fun <- function(m, newdata) predict(m, new_data = newdata, type = 'prob')$.pred_1
    explainer <- DALEX::explain(model, data = x, y = y,
                                predict_function = pred_fun, verbose = FALSE,
                                label = paste(dataset_name, model_name))

    fairness_obj <- tryCatch(
      fairmodels::fairness_check(explainer, protected = test_df[[group]],
                                  privileged = 1, verbose = FALSE),
      error = function(e) NULL
    )
    if (!is.null(fairness_obj)) {
      saveRDS(fairness_obj, file.path('outputs/fairness',
        sprintf('fairness_object_%s_%s.rds', gsub(' ', '_', tolower(dataset_name)), model_name)))
    }

    bind_cols(tibble(dataset = dataset_name, model = model_name), metrics)
  }

  all_evals <- bind_rows(
    eval_one(res$models$baseline_rf,   'baseline_rf'),
    eval_one(res$models$mitigated_rf,  'mitigated_rf'),
    eval_one(res$models$mitigated_nb,  'mitigated_nb'),
    eval_one(res$models$mitigated_knn, 'mitigated_knn')
  )

  baseline_dpd <- all_evals$demographic_parity[all_evals$model == 'baseline_rf']
  best_mitigated_dpd <- min(all_evals$demographic_parity[all_evals$model != 'baseline_rf'])

  delta <- tibble(
    dataset = dataset_name,
    bias_reduction_pct = (baseline_dpd - best_mitigated_dpd) / baseline_dpd * 100
  )

  list(metrics = all_evals, reduction = delta)
}

m1 <- evaluate_result(res1, 'Dataset 1')
m2 <- evaluate_result(res2, 'Dataset 2')
m3 <- evaluate_result(res3, 'Dataset 3')

all_metrics   <- bind_rows(m1$metrics, m2$metrics, m3$metrics)
all_reduction <- bind_rows(m1$reduction, m2$reduction, m3$reduction)

write_csv(all_metrics,   'outputs/fairness/fairness_metrics.csv')
write_csv(all_reduction, 'outputs/fairness/bias_reduction.csv')

message('Fairness evaluation complete for all three datasets.')
