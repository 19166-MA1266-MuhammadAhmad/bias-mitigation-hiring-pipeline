# Bias Mitigation Pipeline in AI-Driven Hiring (Dual Dataset)

This repository implements a complete DALC/MLOps bias mitigation pipeline in R, validated on **two hiring datasets** and compared side-by-side.

## Datasets

1. **Dataset 1 — Synthetic Loan/Hiring Data**: `data/final_bias_hiring_dataset.csv`  
   - Protected attribute: `Gender` (Male/Female text -> encoded 0/1)  
   - Target: `Final_Decision` (Selected/Rejected -> encoded 0/1)

2. **Dataset 2 — AI Hiring Bias Detection (Kaggle)**: `data/data.csv`  
   - Protected attribute: `Gender` (0/1)  
   - Target: `HiringDecision` (0/1)

## Project Structure

- `R/01_data_preparation.R` — preprocessing and 70/30 split for both datasets
- `R/02_eda_bias_detection.R` — EDA, selection rates, disparate impact, visualizations
- `R/03_modeling_reweighting.R` — baseline and reweighted models (Logit/RF/XGB)
- `R/04_fairness_evaluation.R` — fairness metrics and bias reduction reporting
- `R/05_xai_explainability.R` — feature importance, break-down, PDP, ROC artifacts
- `R/save_model.R` — saves best mitigated model and recipe per dataset
- `notebook/bias_mitigation_pipeline.Rmd` — full end-to-end notebook
- `api/plumber.R` — API endpoints `/health`, `/predict`, `/fairness_report`
- `paper/bias_mitigation_paper.Rmd` — IEEE-style paper draft
- `slides/presentation.Rmd` — 15-20 slide presentation
- `slides/speaking_notes.md` — presentation speaker notes
- `docs/demo_instructions.md` — run/demo steps

## Modeling & Fairness

Per dataset, the pipeline trains:
- Baseline Logistic Regression
- Mitigated Logistic Regression (reweighting)
- Mitigated Random Forest (reweighting)
- Mitigated XGBoost (reweighting)

Fairness metrics:
- Demographic Parity
- Equalized Odds
- Disparate Impact Ratio

## Quick Start

1. Restore dependencies:
```r
renv::restore()
```
2. Run scripts in order:
```r
source('R/01_data_preparation.R')
source('R/02_eda_bias_detection.R')
source('R/03_modeling_reweighting.R')
source('R/04_fairness_evaluation.R')
source('R/05_xai_explainability.R')
source('R/save_model.R')
```
3. Run API:
```r
pr <- plumber::plumb('api/plumber.R')
pr$run(port = 8000)
```
