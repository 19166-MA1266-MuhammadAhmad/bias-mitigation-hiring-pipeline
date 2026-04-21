# Bias Mitigation Pipeline in AI-Driven Hiring Processes

R-based DALC/MLOps term project implementing bias detection, mitigation, fairness evaluation, XAI, and deployment for AI hiring decisions.

## Team Member

- **Muhammad Ahmad**
- **ID:** 19166-MA1266

## Repository Structure

```text
.
├── README.md
├── .gitignore
├── .Rprofile
├── renv.lock
├── data/
│   └── final_bias_hiring_dataset.csv
├── R/
│   ├── 01_data_preparation.R
│   ├── 02_eda_bias_detection.R
│   ├── 03_modeling_reweighting.R
│   ├── 04_fairness_evaluation.R
│   ├── 05_xai_explainability.R
│   └── save_model.R
├── notebook/
│   └── bias_mitigation_pipeline.Rmd
├── api/
│   └── plumber.R
├── models/
│   └── .gitkeep
├── paper/
│   └── bias_mitigation_paper.Rmd
├── slides/
│   ├── presentation.Rmd
│   └── speaking_notes.md
└── docs/
    └── demo_instructions.md
```

## Project Pipeline

1. **Data Preparation**: clean and split the hiring dataset (70/30).
2. **EDA & Bias Detection**: disparity analysis by Gender and DALEX baseline explainability.
3. **Modeling with Mitigation**:
   - Baseline Logistic Regression
   - Mitigated Logistic Regression (reweighting)
   - Mitigated Random Forest (reweighting)
   - Mitigated XGBoost (reweighting)
4. **Fairness Evaluation**: demographic parity difference, equalized odds difference, disparate impact ratio, statistical parity.
5. **XAI**: feature importance, break-down, PDP, and ROC by gender.
6. **Deployment**: Plumber API endpoints for prediction and fairness monitoring.

## Dataset

- File: `data/final_bias_hiring_dataset.csv`
- Protected attribute: `Gender`
- Target: `Final_Decision`

## How to Run

1. Install dependencies:
   ```r
   install.packages("renv")
   renv::restore()
   ```
2. Run notebook:
   ```r
   rmarkdown::render("notebook/bias_mitigation_pipeline.Rmd")
   ```
3. Train and save model artifacts:
   ```r
   source("R/save_model.R")
   ```
4. Start API:
   ```r
   pr <- plumber::plumb("api/plumber.R")
   pr$run(port = 8000)
   ```

## API Endpoints

- `GET /health`
- `GET /fairness_report`
- `POST /predict`

## Dependencies

Managed with `renv.lock`, including:
`tidyverse`, `tidymodels`, `DALEX`, `DALEXtra`, `fairmodels`, `ranger`, `xgboost`, `ggplot2`, `patchwork`, `corrplot`, `plumber`, `renv`, `pROC`, `caret`, `vip`, `iml`, `knitr`, `rmarkdown`, `kableExtra`, `scales`.

## Deliverable Links

- Notebook: `notebook/bias_mitigation_pipeline.Rmd`
- Paper source: `paper/bias_mitigation_paper.Rmd`
- Slides: `slides/presentation.Rmd`
- Speaking notes: `slides/speaking_notes.md`
- Demo instructions: `docs/demo_instructions.md`
