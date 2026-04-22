suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(yardstick)
  library(purrr)
  library(DALEX)
})

dir.create('outputs/xai', recursive = TRUE, showWarnings = FALSE)

if (!file.exists('models/model_results_dataset1.rds') || !file.exists('models/model_results_dataset2.rds')) {
  source('R/03_modeling_reweighting.R')
}

res1 <- readRDS('models/model_results_dataset1.rds')
res2 <- readRDS('models/model_results_dataset2.rds')

get_explainer <- function(model, test_df, outcome) {
  x <- test_df %>% select(-all_of(outcome))
  y <- as.integer(as.character(test_df[[outcome]]))
  DALEX::explain(
    model,
    data = x,
    y = y,
    predict_function = function(m, newdata) predict(m, new_data = newdata, type = 'prob')$.pred_1,
    verbose = FALSE
  )
}

run_xai <- function(res, dataset_name, key_feature) {
  test_df <- res$test
  outcome <- res$outcome_col

  im <- map2_dfr(res$models, names(res$models), function(m, nm) {
    ex <- get_explainer(m, test_df, outcome)
    mp <- model_parts(ex)
    mp$model <- nm
    mp$dataset <- dataset_name
    mp
  })

  write.csv(im, file.path('outputs/xai', paste0('feature_importance_', gsub(' ', '_', tolower(dataset_name)), '.csv')), row.names = FALSE)

  best_model <- res$models$mitigated_xgb
  ex_best <- get_explainer(best_model, test_df, outcome)

  bd <- predict_parts(ex_best, new_observation = test_df[1, setdiff(names(test_df), outcome), drop = FALSE], type = 'break_down')
  write.csv(as.data.frame(bd), file.path('outputs/xai', paste0('breakdown_', gsub(' ', '_', tolower(dataset_name)), '.csv')), row.names = FALSE)

  pd <- model_profile(ex_best, variables = key_feature)
  write.csv(as.data.frame(pd$agr_profiles), file.path('outputs/xai', paste0('pdp_', gsub(' ', '_', tolower(dataset_name)), '.csv')), row.names = FALSE)

  roc_all <- map2_dfr(res$models, names(res$models), function(m, nm) {
    probs <- predict(m, test_df, type = 'prob')$.pred_1
    truth <- factor(as.integer(as.character(test_df[[outcome]])), levels = c(0, 1))
    roc_curve_vec <- yardstick::roc_curve_vec(truth = truth, estimate = probs, event_level = 'second')
    bind_cols(tibble(model = nm, dataset = dataset_name), roc_curve_vec)
  })

  write.csv(roc_all, file.path('outputs/xai', paste0('roc_overall_', gsub(' ', '_', tolower(dataset_name)), '.csv')), row.names = FALSE)

  roc_by_gender <- map2_dfr(res$models, names(res$models), function(m, nm) {
    probs <- predict(m, test_df, type = 'prob')$.pred_1
    tmp <- test_df %>% mutate(prob = probs)
    bind_rows(lapply(sort(unique(tmp$Gender)), function(g) {
      sub <- tmp %>% filter(Gender == g)
      truth <- factor(as.integer(as.character(sub[[outcome]])), levels = c(0, 1))
      rc <- yardstick::roc_curve_vec(truth = truth, estimate = sub$prob, event_level = 'second')
      bind_cols(tibble(model = nm, dataset = dataset_name, gender = g), rc)
    }))
  })

  write.csv(roc_by_gender, file.path('outputs/xai', paste0('roc_by_gender_', gsub(' ', '_', tolower(dataset_name)), '.csv')), row.names = FALSE)
}

run_xai(res1, 'Dataset 1', 'Interview_Score')
run_xai(res2, 'Dataset 2', 'InterviewScore')

message('XAI artifacts created for both datasets.')
