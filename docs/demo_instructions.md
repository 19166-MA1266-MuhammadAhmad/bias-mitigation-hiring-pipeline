# Demo Instructions

## 1) Prepare environment
1. Install R (>=4.3).
2. Install required packages from `renv.lock` (`renv::restore()`).

## 2) Run pipeline scripts
From repo root, run:
- `source('R/01_data_preparation.R')`
- `source('R/02_eda_bias_detection.R')`
- `source('R/03_modeling_reweighting.R')`
- `source('R/04_fairness_evaluation.R')`
- `source('R/05_xai_explainability.R')`
- `source('R/save_model.R')`

## 3) Render notebook
- Render `notebook/bias_mitigation_pipeline.Rmd`.

## 4) Start API
```r
pr <- plumber::plumb('api/plumber.R')
pr$run(port = 8000)
```

## 5) Test API
- `GET /health`
- `GET /fairness_report`
- `POST /predict` with JSON body:
```json
{
  "dataset": "dataset2",
  "data": {
    "Age": 27,
    "Gender": 0,
    "EducationLevel": 3,
    "ExperienceYears": 4,
    "PreviousCompanies": 2,
    "DistanceFromCompany": 10,
    "InterviewScore": 78,
    "SkillScore": 81,
    "PersonalityScore": 75,
    "RecruitmentStrategy": 2
  }
}
```
