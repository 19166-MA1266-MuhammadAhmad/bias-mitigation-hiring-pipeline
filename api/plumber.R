library(plumber)
library(jsonlite)
library(dplyr)
library(tibble)

model_path <- "models/best_model.rds"
recipe_path <- "models/recipe.rds"
fairness_path <- "models/fairness_report.rds"

safe_read_rds <- function(path) {
  if (!file.exists(path)) stop(sprintf("Missing file: %s", path))
  readRDS(path)
}

`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0 || is.na(x)) y else x
}

model_obj <- tryCatch(safe_read_rds(model_path), error = function(e) NULL)
recipe_obj <- tryCatch(safe_read_rds(recipe_path), error = function(e) NULL)
fairness_report <- tryCatch(safe_read_rds(fairness_path), error = function(e) tibble())

required_fields <- c(
  "Gender", "University", "Education_Level", "CGPA", "Experience_Years",
  "Job_Applied", "Company", "Skills_Score", "Interview_Score"
)

#* Health check endpoint
#* @get /health
function() {
  list(
    status = "ok",
    model_loaded = !is.null(model_obj),
    recipe_loaded = !is.null(recipe_obj),
    fairness_report_loaded = nrow(fairness_report) > 0
  )
}

#* Fairness report endpoint
#* @get /fairness_report
function(res) {
  if (nrow(fairness_report) == 0) {
    res$status <- 404
    return(list(error = "Fairness report not found. Run R/save_model.R first."))
  }

  list(
    generated_from = "models/fairness_report.rds",
    metrics = fairness_report
  )
}

#* Prediction endpoint
#* @post /predict
#* @serializer unboxedJSON
function(req, res) {
  tryCatch({
    if (is.null(model_obj) || is.null(recipe_obj)) {
      res$status <- 500
      return(list(error = "Model artifacts not loaded. Run R/save_model.R first."))
    }

    if (is.null(req$postBody) || !nzchar(req$postBody)) {
      res$status <- 400
      return(list(error = "Request body is required JSON."))
    }

    body <- jsonlite::fromJSON(req$postBody, simplifyDataFrame = TRUE)

    missing_fields <- setdiff(required_fields, names(body))
    if (length(missing_fields) > 0) {
      res$status <- 400
      return(list(error = sprintf("Missing fields: %s", paste(missing_fields, collapse = ", "))))
    }

    applicant <- tibble::tibble(
      Applicant_ID = body$Applicant_ID %||% 0,
      Applicant_Name = body$Applicant_Name %||% "API User",
      Gender = as.character(body$Gender),
      University = as.character(body$University),
      Education_Level = as.character(body$Education_Level),
      CGPA = as.numeric(body$CGPA),
      Experience_Years = as.numeric(body$Experience_Years),
      Job_Applied = as.character(body$Job_Applied),
      Company = as.character(body$Company),
      Skills_Score = as.numeric(body$Skills_Score),
      Interview_Score = as.numeric(body$Interview_Score)
    )

    probs <- predict(model_obj, new_data = applicant, type = "prob")
    cls <- predict(model_obj, new_data = applicant, type = "class")

    fairness_score <- if (nrow(fairness_report) > 0) {
      list(
        demographic_parity_difference = fairness_report$demographic_parity_difference[1],
        disparate_impact_ratio = fairness_report$disparate_impact_ratio[1],
        equalized_odds_difference = fairness_report$equalized_odds_difference[1]
      )
    } else {
      list(message = "Fairness score unavailable until fairness report is generated")
    }

    list(
      prediction = as.character(cls$.pred_class[[1]]),
      probability_selected = as.numeric(probs$.pred_Selected[[1]]),
      fairness_score = fairness_score
    )
  }, error = function(e) {
    res$status <- 500
    list(error = e$message)
  })
}
