library(dplyr)
library(purrr)
library(ggplot2)
library(DALEX)
library(pROC)

source("R/03_modeling_reweighting.R")

build_dalex_explainer <- function(fitted_workflow, train_df, label) {
  train_x <- train_df %>% select(-Final_Decision, -Applicant_ID, -Applicant_Name)
  y <- as.integer(train_df$Final_Decision == "Selected")

  explain(
    model = fitted_workflow,
    data = train_x,
    y = y,
    label = label,
    verbose = FALSE
  )
}

plot_feature_importance <- function(explainer) {
  model_parts(explainer, type = "difference") %>% plot()
}

breakdown_single_prediction <- function(explainer, observation) {
  predict_parts(explainer, new_observation = observation, type = "break_down")
}

partial_dependence_profile <- function(explainer, variable) {
  model_profile(explainer, variables = variable, N = 400, type = "partial")
}

roc_by_gender <- function(pred_df, model_label) {
  pred_df %>%
    group_by(Gender) %>%
    group_map(~{
      roc_obj <- roc(
        response = .x$Final_Decision,
        predictor = .x$.pred_Selected,
        levels = c("Rejected", "Selected"),
        direction = "<"
      )

      tibble(
        specificity = roc_obj$specificities,
        sensitivity = roc_obj$sensitivities,
        Gender = .y$Gender,
        model = model_label
      )
    }) %>%
    bind_rows()
}

plot_roc_by_gender <- function(roc_df) {
  ggplot(roc_df, aes(x = 1 - specificity, y = sensitivity, color = Gender)) +
    geom_path(size = 1) +
    facet_wrap(~model) +
    geom_abline(slope = 1, intercept = 0, linetype = "dashed") +
    labs(title = "ROC Curves by Gender", x = "False Positive Rate", y = "True Positive Rate") +
    theme_minimal()
}
