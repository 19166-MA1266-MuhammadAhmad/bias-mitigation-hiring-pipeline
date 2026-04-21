# Demo Instructions

## 1) Clone Repository

```bash
git clone https://github.com/19166-MA1266-MuhammadAhmad/bias-mitigation-hiring-pipeline.git
cd bias-mitigation-hiring-pipeline
```

## 2) Install R Dependencies with renv

```r
install.packages("renv")
renv::restore()
```

## 3) Run the Notebook

```r
rmarkdown::render("notebook/bias_mitigation_pipeline.Rmd")
```

## 4) Train and Save the Best Model

```r
source("R/save_model.R")
```

Expected artifacts:
- `models/best_model.rds`
- `models/recipe.rds`
- `models/fairness_report.rds`

## 5) Start the Plumber API

```r
pr <- plumber::plumb("api/plumber.R")
pr$run(host = "0.0.0.0", port = 8000)
```

## 6) Test API Endpoints

### Health Check

```bash
curl http://127.0.0.1:8000/health
```

### Fairness Report

```bash
curl http://127.0.0.1:8000/fairness_report
```

### Predict

```bash
curl -X POST http://127.0.0.1:8000/predict \
  -H "Content-Type: application/json" \
  -d '{
    "Applicant_ID": 5001,
    "Applicant_Name": "Demo Applicant",
    "Gender": "Female",
    "University": "University of Adelaide",
    "Education_Level": "Masters",
    "CGPA": 3.55,
    "Experience_Years": 4,
    "Job_Applied": "ML Engineer",
    "Company": "Siemens",
    "Skills_Score": 78,
    "Interview_Score": 81
  }'
```
