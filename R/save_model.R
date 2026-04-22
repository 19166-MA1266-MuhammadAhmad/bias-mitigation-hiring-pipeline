suppressPackageStartupMessages({
  library(dplyr)
  library(workflows)
})

if (!file.exists('models/model_results_dataset1.rds') || !file.exists('models/model_results_dataset2.rds')) {
  source('R/03_modeling_reweighting.R')
}

dir.create('models', showWarnings = FALSE, recursive = TRUE)

res1 <- readRDS('models/model_results_dataset1.rds')
res2 <- readRDS('models/model_results_dataset2.rds')

pick_best_mitigated <- function(res) {
  mitigated <- res$metrics %>%
    filter(model %in% c('mitigated_logit', 'mitigated_rf', 'mitigated_xgb')) %>%
    arrange(desc(auc), desc(f1), desc(accuracy))
  best_name <- mitigated$model[[1]]
  res$models[[best_name]]
}

best1 <- pick_best_mitigated(res1)
best2 <- pick_best_mitigated(res2)

saveRDS(best1, 'models/best_model_dataset1.rds')
saveRDS(best2, 'models/best_model_dataset2.rds')

saveRDS(workflows::extract_recipe(best1), 'models/recipe_dataset1.rds')
saveRDS(workflows::extract_recipe(best2), 'models/recipe_dataset2.rds')

message('Saved best mitigated models and recipes for both datasets.')
