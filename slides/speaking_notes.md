# Speaking Notes — Bias Mitigation in AI Hiring
## 24 Slides | ~15 minutes

---

## Slide 1 — Title (15 sec)

Hey everyone. Our project is about detecting and fixing gender bias in AI hiring models. We built a full pipeline in R and tested it on three datasets. Let me show you what we found.

---

## Slide 2 — The Problem (1 min)

Companies are using ML to screen candidates, and the issue is these models pick up biases from old data. Amazon had this exact problem in 2018 — their tool was downranking women because it learned from years of male-dominated hiring. They had to scrap it.

We had three questions: Is there bias in a baseline model? Can we fix it with reweighting? And does the fix work across multiple datasets?

---

## Slide 3 — Why It Matters (30 sec)

EU AI Act now treats hiring AI as high-risk. UAE has similar rules under their 2031 strategy. So this isn't just academic — companies actually need this. We tested on three datasets instead of one to make results more convincing.

---

## Slide 4 — Literature (30 sec)

Quick background: Kamiran and Calders came up with the reweighting method we use. Chouldechova showed you can't satisfy all fairness metrics at once — we actually see that in our results. DALEX handles the explainability side.

---

## Slide 5 — Methodology (1 min)

Six steps. Prep the data, do EDA to spot bias, train four models per dataset — one baseline Random Forest and three mitigated variants: Random Forest with case weights, Naive Bayes with resampled data, and KNN with resampled data. Then evaluate fairness using four metrics including calibration, run DALEX for explainability, and deploy through a REST API and Shiny dashboard. We use a 70/15/15 train-validation-test split.

---

## Slide 6 — Dataset 1 (30 sec)

2,000 applicants, 7 features after dropping IDs. Gender is roughly 50-50. Selection rate is 57.8%. Disparate impact is 0.980 — looks fair on the surface.

---

## Slide 7 — Dataset 2 (30 sec)

Kaggle dataset, 1,500 candidates, 11 features. More selective — only 31% get hired. DI ratio is 0.993, basically perfect parity.

---

## Slide 8 — Dataset 3 (30 sec)

FairJob dataset, up to 2,000 candidates, 9 features. This one has the most baseline bias — DPD of 0.171. Features include coding experience, computer skills, previous salary. This is where we see the biggest mitigation impact.

---

## Slide 9 — EDA (30 sec)

Hiring rates by gender look similar on the surface in Datasets 1 and 2. Dataset 3 shows more disparity. But aggregate numbers don't tell the full story — bias can hide in feature interactions even when overall rates look balanced.

---

## Slide 10 — Reweighting (1 min)

We use inverse-frequency weights. If female-hired is underrepresented, those examples get higher weight. For Random Forest, weights go through tidymodels case weights. For Naive Bayes and KNN, which don't support case weights, we do weighted resampling — sampling with replacement proportional to the weights.

---

## Slide 11 — Dataset 1 Performance (30 sec)

Baseline RF gets 0.565 accuracy, 0.494 AUC. Mitigated NB gets the best AUC at 0.519. Low AUC across the board because this synthetic data is hard to separate. Baseline bias is already very low here.

---

## Slide 12 — Dataset 2 Performance (45 sec)

Here's the interesting part. Baseline gets 0.889 accuracy and 0.911 AUC. The mitigated RF actually beats it — 0.894 accuracy, 0.916 AUC. So fairness doesn't always cost you performance. With strong signal data and the right model, you can have both.

---

## Slide 13 — Dataset 3 Performance (30 sec)

Baseline RF gets 0.771 accuracy, 0.856 AUC. Mitigated RF improves to 0.784 accuracy. Mitigated NB gets the highest AUC at 0.869. KNN lags behind at 0.668 accuracy.

---

## Slide 14 — Fairness Results (1 min)

The big story is Dataset 3. Baseline DPD is 0.171. Mitigated NB brings it down to 0.045 — that's a 73.5% reduction. DI ratio jumps from 0.701 to 0.930, well above the 0.8 threshold.

Dataset 2: NB reduces DPD from 0.111 to 0.065, a 41% reduction. DI ratio improves from 0.591 to 0.804.

Dataset 1: Baseline bias was already minimal at 0.036, so mitigation didn't improve it further.

---

## Slide 15 — Bias Reduction Summary (30 sec)

Key takeaway: when meaningful bias exists like in Datasets 2 and 3, Naive Bayes with resampled data achieves the best demographic parity improvements. When bias is already low like Dataset 1, be careful — over-correction can happen.

---

## Slide 16 — Calibration (30 sec)

Calibration measures whether predicted probabilities are equally accurate across groups. Baseline RF has excellent calibration: 0.004 to 0.021. Mitigated RF maintains it well. But Mitigated NB on Dataset 3 has calibration of 0.126 — it trades calibration accuracy for better demographic parity. This is why we need multiple metrics.

---

## Slide 17 — Feature Importance (30 sec)

Interview Score is the top predictor for Datasets 1 and 2. Computer Skills leads for Dataset 3. Gender itself has low direct importance in all datasets, which means bias comes through correlated features. That's exactly why you need fairness metrics.

---

## Slide 18 — Attribution & PDP (30 sec)

Break-down plots show each feature's contribution to individual predictions — useful for explaining decisions to candidates. PDP shows sensible monotonic relationships. ROC curves converge across genders after mitigation.

---

## Slide 19 — Deployment (30 sec)

Two deployment channels. Plumber REST API with health, predict, and fairness report endpoints. And a Shiny dashboard with four tabs: model performance, fairness metrics with calibration plots, before-after comparison, and an interactive prediction form that works for all three datasets.

---

## Slide 20 — UAE Relevance (30 sec)

UAE AI Strategy 2031 prioritizes ethical AI. In the GCC, hiring decisions affect visas and residency, so the stakes are higher. Our pipeline gives organizations the audit trail and transparency they need.

---

## Slide 21 — Limitations (30 sec)

Synthetic data has limits. We only looked at binary gender. No causal claims. And the pipeline doesn't monitor for drift over time. Also, optimizing one fairness metric can worsen another — we saw that with NB's calibration on Dataset 3.

---

## Slide 22 — Conclusion (30 sec)

We built a working bias mitigation pipeline, tested it on three datasets, got 73.5% bias reduction on FairJob and better-than-baseline performance on the Kaggle dataset. Four fairness metrics including calibration. Three model types: RF, NB, KNN. Deployable via API and Shiny dashboard.

---

## Slide 23 — References (10 sec)

Key refs are on screen — Kamiran and Calders for reweighting, Barocas and Hardt for theory.

---

## Slide 24 — Q&A

Thanks everyone. Happy to answer questions.
