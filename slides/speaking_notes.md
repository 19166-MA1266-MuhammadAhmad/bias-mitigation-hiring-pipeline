# Speaking Notes — Dual-Dataset Bias Mitigation in AI Hiring
## Target Duration: 15–20 minutes

---

### Slide 1: Problem Statement (~1.5 min)

Good [morning/afternoon]. Today I'm presenting our work on bias mitigation in AI-driven hiring processes.

The problem is straightforward: organizations worldwide are deploying machine learning models to screen job candidates. These models promise efficiency, but they come with a serious risk — they can encode and amplify historical biases from their training data.

The most well-known example is Amazon's hiring tool, reported by Reuters in 2018, which systematically penalized female applicants because it was trained on a decade of male-dominated hiring decisions.

Our project addresses three research questions:
- First, does a baseline model exhibit measurable gender bias?
- Second, can reweighting-based mitigation reduce that bias while keeping performance acceptable?
- Third — and this is what distinguishes our work — does the pipeline generalize across datasets with different characteristics?

---

### Slide 2: Motivation (~1 min)

Why does this matter in 2026? We're seeing increasing regulatory pressure globally. The EU AI Act classifies hiring AI as high-risk. The UAE AI Strategy 2031 emphasizes ethical deployment.

Organizations don't just need fair models — they need **auditable, explainable** ones. And single-dataset studies, while common in the literature, don't establish enough credibility for real-world adoption. That's why we validate on two datasets with very different profiles.

---

### Slide 3: Literature Foundations (~1 min)

Our work builds on several key foundations. Barocas and Hardt established the mathematical framework for fairness definitions and showed that many are mutually incompatible. Kamiran and Calders pioneered the reweighting technique we use. Chouldechova proved the impossibility of simultaneously satisfying calibration and error rate balance — a result we actually observe in our Dataset 2 results. Bellamy and colleagues at IBM built the AI Fairness 360 toolkit that standardized fairness evaluation practices.

---

### Slide 4: DALC/MLOps Methodology (~1.5 min)

Our pipeline follows six phases mapped to the Data Analytics Life Cycle.

Phase 1 is data preparation — loading, cleaning, encoding, and creating 70/30 stratified splits with a fixed seed of 1266 for reproducibility.

Phase 2 is EDA and bias detection, where we compute selection rates by gender, examine feature distributions, and calculate the disparate impact ratio.

Phase 3 is modeling with reweighting. We train four models per dataset: a baseline logistic regression with no mitigation, plus three reweighted models — logistic regression, random forest with 300 trees, and XGBoost with 300 trees.

Phase 4 evaluates fairness using three metrics: demographic parity difference, equalized odds difference, and disparate impact ratio.

Phase 5 provides explainability through DALEX — feature importance, break-down attribution, partial dependence profiles, and gender-stratified ROC curves.

Phase 6 deploys the best model via a Plumber REST API.

---

### Slide 5: Dataset 1 — Synthetic Hiring Data (~1 min)

Dataset 1 is our synthetic hiring dataset. It has 2,000 applicants with 12 original features, of which we model 7 after dropping identifiers to prevent data leakage.

The gender split is nearly even — 991 female, 1,009 male. The overall selection rate is 57.8%, and the disparate impact ratio is 0.980, which is above the 0.8 four-fifths rule threshold. So on the surface, the data appears balanced. But as we'll see, the model can still produce biased predictions through feature interactions.

---

### Slide 6: Dataset 2 — Kaggle Dataset (~1 min)

Dataset 2 is from the Kaggle AI Hiring Bias Detection challenge. It has 1,500 candidates with 11 features. This is a more selective dataset — only 31% of candidates are hired, compared to 58% in Dataset 1.

The disparate impact ratio is 0.993 — essentially perfect gender parity in base rates. This provides a useful contrast: how does our mitigation pipeline behave when baseline bias is minimal? Does it over-correct?

---

### Slide 7: EDA Findings (~1 min)

Our EDA confirms what the numbers suggest. In Dataset 1, female selection rate is 58.3% versus 57.2% for males — a small gap. In Dataset 2, it's 31.1% versus 30.9% — almost identical.

Both disparate impact ratios are well above 0.8. However, the key insight is that raw hiring rates can mask bias that emerges through model predictions. A model might learn feature interactions that systematically disadvantage one group, even when the aggregate rates appear fair.

---

### Slide 8: Reweighting Strategy (~1 min)

Our mitigation strategy is reweighting, following Kamiran and Calders 2012. The formula is shown here — for each combination of gender group g and outcome y, the weight is N divided by the number of groups times the count in that cell.

This upweights underrepresented group-outcome combinations during training, encouraging the model to treat all subgroups more equally. The advantage of this approach is that it's model-agnostic — we apply the same weights to logistic regression, random forest, and XGBoost through the tidymodels `add_case_weights` workflow interface.

---

### Slide 9: Model Performance — Dataset 1 (~1.5 min)

On Dataset 1, the baseline logistic regression achieves accuracy of 0.577 and F1 of 0.725. These are the highest among the four models, but as we'll see, at the cost of higher bias.

The mitigated models show reduced accuracy — around 0.49 to 0.50 — which is expected. When reweighting forces the model to equalize predictions across groups, it shifts the decision boundary. The mitigated random forest achieves the best AUC among mitigated variants at 0.496.

The low overall AUC values here reflect the inherent difficulty of Dataset 1 — features have very similar distributions across gender groups, making this close to a random classification task. The important question is whether bias is reduced, not whether absolute performance is high.

---

### Slide 10: Model Performance — Dataset 2 (~1.5 min)

Dataset 2 tells a much more encouraging story. The baseline achieves 0.863 accuracy and 0.901 AUC — strong performance reflecting the more separable structure of this dataset.

But here's the key finding: the mitigated random forest achieves **0.889 accuracy and 0.906 AUC**, actually exceeding the baseline. This demonstrates that the fairness-performance trade-off is **not inevitable**. When the underlying signal is strong and the model has sufficient capacity, reweighting can improve both fairness and performance simultaneously.

---

### Slide 11: Fairness Metrics — Before vs. After (~2 min)

This is the core results slide. On Dataset 1, the mitigated logistic model reduces demographic parity difference by 86.1% — from 0.064 to 0.009. Equalized odds difference drops from 0.071 to 0.044. The disparate impact ratio improves from 0.935 to 0.982.

On Dataset 2, the picture is more nuanced — and this is where it gets interesting. The baseline already has very low demographic parity difference at 0.013. After reweighting, DPD actually increases to 0.052. However, equalized odds difference improves from 0.046 to 0.026 — a 43.2% reduction.

This illustrates Chouldechova's impossibility result in practice: optimizing one fairness metric can worsen another. It also shows that practitioners should assess baseline bias levels before applying uniform mitigation strategies. When bias is already minimal, aggressive reweighting may introduce new imbalances.

---

### Slide 12: XAI — Feature Importance (~1 min)

Our DALEX-based feature importance analysis shows that Interview Score is the top predictor in both datasets. In Dataset 1, Skills Score and CGPA follow. In Dataset 2, Skill Score and Experience Years are next.

Importantly, Gender shows minimal direct importance in both datasets. This confirms that bias operates through correlated features and interactions rather than through the protected attribute itself — which is exactly the type of hidden bias that fairness evaluation catches.

---

### Slide 13: XAI — Break-Down and PDP (~1 min)

Break-down attribution decomposes individual predictions, showing exactly which features pushed a specific candidate toward or away from selection. This supports "right to explanation" requirements in emerging AI regulations.

Partial dependence profiles for Interview Score show the expected monotonic increase in hiring probability. In Dataset 1, the curve goes from about 0.45 to 0.60. In Dataset 2, it rises more steeply from 0.15 to 0.55, reflecting the higher selectivity. These profiles confirm that the model has learned intuitive, defensible relationships.

---

### Slide 14: Live Demo — Plumber API (~1 min)

For deployment, we serve the best model through a Plumber REST API with three endpoints. The health endpoint confirms the model and recipe are loaded. The fairness report endpoint returns aggregate fairness metrics. The predict endpoint accepts candidate features as JSON and returns the prediction, probability, and fairness scores.

This architecture enables real-time, bias-aware hiring recommendations that can be integrated into existing HR technology stacks.

---

### Slide 15: UAE and Regional Relevance (~1 min)

This work has particular relevance for the UAE and GCC region. The UAE AI Strategy 2031 explicitly prioritizes ethical AI. In the Gulf, where expatriate workforces are diverse and hiring decisions carry visa and residency implications, fair AI-driven hiring is especially consequential.

Our pipeline provides three things organizations need: measurable fairness metrics for audit compliance, explainable predictions for regulatory transparency, and a deployable API for HR tech integration.

---

### Slide 16: Limitations and Future Work (~1 min)

We should be transparent about limitations. Our synthetic dataset may not capture real-world complexity. We consider only binary gender as the protected attribute — real-world bias is intersectional. We make no causal claims. And the pipeline is static, without drift monitoring.

Future work would extend to multiple protected attributes, implement post-processing calibration, add concept drift monitoring, and incorporate non-binary gender representations.

---

### Slide 17: Conclusion (~1 min)

To summarize: we built an end-to-end bias mitigation pipeline in R, validated it on two datasets with different characteristics, and demonstrated that reweighting can reduce demographic parity difference by 86.1% when bias is present, while maintaining or even improving performance when the underlying data is well-structured.

The dual-dataset approach strengthens credibility beyond what a single-dataset study could achieve. And the full pipeline — from data preparation through API deployment — is reproducible through renv dependency management.

---

### Slide 18: References (~30 sec)

Our references are listed here. I'd highlight the Kamiran and Calders 2012 paper on reweighting, Barocas and Hardt's textbook on fairness and machine learning, and the recent 2025 IEEE works on ethical AI in hiring.

---

### Slide 19: Q&A

I'm happy to take questions. If you'd like to discuss specific metrics, the reweighting implementation, or the deployment architecture, I can go into more detail on any of those topics.

Thank you.
