# Bias Mitigation Pipeline in AI-Driven Hiring (Three Datasets)

This repository implements a complete DALC/MLOps bias mitigation pipeline in R, validated on **three hiring datasets** and compared side-by-side.

## Datasets

1. **Dataset 1 — Synthetic Hiring Data**: `data/final_bias_hiring_dataset.csv`  
   - Protected attribute: `Gender` (Male/Female text -> encoded 0/1)  
   - Target: `Final_Decision` (Selected/Rejected -> encoded 0/1)

2. **Dataset 2 — AI Hiring Bias Detection (Kaggle)**: `data/data.csv`  
   - Protected attribute: `Gender` (0/1)  
   - Target: `HiringDecision` (0/1)

3. **Dataset 3 — FairJob Dataset**: `data/job fair dataset.csv`  
   - Protected attribute: `Gender` (Man/Woman -> encoded 0/1)  
   - Target: `Employed` (0/1)

## Project Structure

- `R/01_data_preparation.R` — preprocessing and 70/15/15 train-validation-test split for all three datasets
- `R/02_eda_bias_detection.R` — EDA, selection rates, disparate impact, visualizations
- `R/03_modeling_reweighting.R` — baseline and reweighted models (RF / Naive Bayes / KNN)
- `R/04_fairness_evaluation.R` — fairness metrics (demographic parity, equalized odds, calibration, disparate impact ratio) and bias reduction reporting
- `R/05_xai_explainability.R` — feature importance, break-down, PDP, ROC artifacts
- `R/save_model.R` — saves best mitigated model and recipe per dataset
- `app.R` — Shiny dashboard (performance, fairness, before/after comparison, prediction)
- `notebook/bias_mitigation_pipeline.Rmd` — full end-to-end notebook
- `api/plumber.R` — API endpoints `/health`, `/predict`, `/fairness_report`
- `paper/bias_mitigation_paper.Rmd` — IEEE-style paper draft
- `slides/presentation.Rmd` — presentation slides
- `slides/Bias_Mitigation_Presentation.pptx` — PowerPoint presentation
- `slides/speaking_notes.md` — presentation speaker notes
- `docs/demo_instructions.md` — run/demo steps
- `docs/literature_review_matrix.csv` — literature review matrix

## Modeling & Fairness

Per dataset, the pipeline trains:
- Baseline Random Forest (no mitigation)
- Mitigated Random Forest (reweighting via case weights)
- Mitigated Naive Bayes (reweighting via resampling)
- Mitigated K-Nearest Neighbors (reweighting via resampling)

Data split: **70% training / 15% validation / 15% test** (stratified).

Fairness metrics:
- Demographic Parity
- Equalized Odds
- Calibration
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
3. Run Shiny dashboard:
```r
shiny::runApp('app.R')
```
4. Run API:
```r
pr <- plumber::plumb('api/plumber.R')
pr$run(port = 8000)
```
