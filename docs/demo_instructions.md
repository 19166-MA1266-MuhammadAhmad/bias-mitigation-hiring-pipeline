# Demo Instructions

## Prerequisites — Install R

### Windows
1. Download R from https://cloud.r-project.org/bin/windows/base/
2. Run the installer (accept defaults)
3. After installation, add R to your system PATH:
   - Find R's install path, typically:
     - `C:\Program Files\R\R-4.x.x\bin\x64` (system-wide install)
     - `C:\Users\<YourUsername>\AppData\Local\Programs\R\R-4.x.x\bin\x64` (user install)
   - Open **Settings → System → About → Advanced system settings → Environment Variables**
   - Under **User variables**, select `Path` → Edit → New → paste the R bin path
   - Click OK and **restart your terminal**
4. Verify: open a new terminal and run:
   ```
   Rscript --version
   ```
   You should see something like `Rscript (R) version 4.5.3`

### macOS
```bash
brew install r
```

### Linux (Ubuntu/Debian)
```bash
sudo apt update && sudo apt install r-base
```

---

## 1) Clone Repository

```bash
git clone -b copilot/implement-bias-mitigation-pipeline https://github.com/19166-MA1266-MuhammadAhmad/bias-mitigation-hiring-pipeline.git
cd bias-mitigation-hiring-pipeline
```

## 2) Install R Dependencies with renv

Run these commands in your terminal (not inside R):

```bash
Rscript -e "install.packages('renv', repos='https://cloud.r-project.org')"
Rscript -e "renv::restore(prompt = FALSE)"
```

> **Troubleshooting**: If `renv::restore()` fails on some packages (common with R 4.5+), install them manually:
> ```bash
> Rscript -e "install.packages(c('knitr','ggplot2','pROC','ranger','xgboost','tidymodels','tidyverse','DALEX','DALEXtra','fairmodels','plumber','caret','corrplot','vip','iml','kableExtra','patchwork','rmarkdown','scales'), repos='https://cloud.r-project.org')"
> ```

## 3) Run the Full Pipeline (Train & Save Models)

```bash
Rscript R/save_model.R
```

This will:
- Load `data/final_bias_hiring_dataset.csv`
- Split data 70/30 (stratified)
- Train 4 models (baseline + 3 reweighted)
- Evaluate fairness metrics
- Save the best model to `models/`

Expected artifacts:
- `models/best_model.rds` — best performing model
- `models/recipe.rds` — preprocessing recipe
- `models/fairness_report.rds` — fairness comparison table

## 4) (Optional) Render the Notebook

```bash
Rscript -e "rmarkdown::render('notebook/bias_mitigation_pipeline.Rmd')"
```

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
