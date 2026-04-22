# plumber API for dual-dataset prediction and fairness reporting
library(plumber)
library(jsonlite)

load_workflow <- function(path) {
  if (!file.exists(path)) return(NULL)
  readRDS(path)
}

`%||%` <- function(x, y) if (is.null(x)) y else x

model1 <- load_workflow('models/best_model_dataset1.rds')
model2 <- load_workflow('models/best_model_dataset2.rds')

#* @get /health
function() {
  list(
    status = 'ok',
    models_loaded = list(dataset1 = !is.null(model1), dataset2 = !is.null(model2))
  )
}

#* @post /predict
#* @serializer unboxedJSON
function(req, res) {
  payload <- jsonlite::fromJSON(req$postBody)
  dataset <- as.character(payload$dataset %||% 'dataset2')

  record <- payload$data
  if (is.null(record)) {
    res$status <- 400
    return(list(error = 'Request body must contain "data" object.'))
  }

  model <- if (tolower(dataset) %in% c('dataset1', '1')) model1 else model2
  if (is.null(model)) {
    res$status <- 503
    return(list(error = sprintf('Model not available for %s', dataset)))
  }

  input <- as.data.frame(record, stringsAsFactors = FALSE)
  prob <- tryCatch(predict(model, new_data = input, type = 'prob')$.pred_1, error = function(e) NA_real_)
  cls <- tryCatch(predict(model, new_data = input, type = 'class')$.pred_class, error = function(e) NA)

  list(dataset = dataset, prediction = as.character(cls), probability = as.numeric(prob))
}

#* @get /fairness_report
#* @serializer unboxedJSON
function() {
  path <- 'outputs/fairness/fairness_metrics.csv'
  if (!file.exists(path)) {
    return(list(error = 'Fairness report not found. Run R/04_fairness_evaluation.R first.'))
  }
  read.csv(path)
}
