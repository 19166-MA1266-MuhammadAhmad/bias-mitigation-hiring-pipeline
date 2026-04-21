library(dplyr)
library(tidyr)
library(purrr)
library(DALEX)
library(fairmodels)

source("R/03_modeling_reweighting.R")

compute_group_rates <- function(pred_df) {
  pred_df %>%
    mutate(
      y_true = Final_Decision == "Selected",
      y_pred = .pred_class == "Selected"
    ) %>%
    group_by(Gender) %>%
    summarise(
      selection_rate = mean(y_pred),
      tpr = sum(y_pred & y_true) / sum(y_true),
      fpr = sum(y_pred & !y_true) / sum(!y_true),
      fnr = sum(!y_pred & y_true) / sum(y_true),
      .groups = "drop"
    )
}

fairness_metrics <- function(pred_df) {
  rates <- compute_group_rates(pred_df)
  male <- rates %>% filter(Gender == "Male")
  female <- rates %>% filter(Gender == "Female")

  tibble(
    demographic_parity_difference = abs(female$selection_rate - male$selection_rate),
    disparate_impact_ratio = female$selection_rate / male$selection_rate,
    equalized_odds_difference = max(abs(female$tpr - male$tpr), abs(female$fpr - male$fpr)),
    statistical_parity = female$selection_rate - male$selection_rate
  )
}

build_fairmodels_object <- function(result_obj) {
  map(result_obj$results, function(x) {
    pred <- x$predictions
    fm_obj <- tryCatch(
      fairmodels::fairness_check(
        data = pred,
        outcome = pred$Final_Decision == "Selected",
        y = pred$.pred_Selected,
        protected = pred$Gender,
        verbose = FALSE
      ),
      error = function(e) NULL
    )

    list(
      label = x$label,
      fairness = fairness_metrics(pred),
      fairness_check = fm_obj
    )
  })
}

build_fairness_table <- function(result_obj) {
  map_dfr(result_obj$results, function(x) {
    fairness_metrics(x$predictions) %>% mutate(model = x$label, .before = 1)
  })
}
