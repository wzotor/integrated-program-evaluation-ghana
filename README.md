# Effects of an Integrated Community-Based Program on Child Development and Caregiver Well-Being in Rural Ghana

Analysis code for a longitudinal quasi-experimental evaluation of an integrated community-based program in the Sawla-Tuna-Kalba District of Ghana's Savannah Region.

Author: Wisdom Zotor
ORCID: (https://orcid.org/0009-0003-1650-2160)

## Overview

The study compares three intervention communities with three comparison communities between the 2022 baseline and the 2024 endline. The baseline sample comprises 600 children and 600 linked female caregivers, with 100 participants per community in each dataset. Child and caregiver outcomes are analyzed separately.

The code reproduces all results reported in the manuscript, including descriptive statistics, attrition summaries, five model specifications for 14 outcomes, Holm-adjusted p-values and leave-one-community-out checks.

## Repository contents

```
scripts/
   00_setup.R
   01_data_validation.R
   02_reshape_wide.R
   03_descriptives.R
   04_did_complete_case.R
   05_adjusted_did_ancova.R
   06_multiple_imputation.R
   07_holm_correction.R
   08_attrition_loo.R
   09_export_results.R
```

| Script | Purpose |
|---|---|
| `00_setup.R` | Loads packages, defines folder paths, analysis settings and shared functions |
| `01_data_validation.R` | Checks duplicates, identifiers, community and group consistency, year-wave correspondence and child-caregiver links |
| `02_reshape_wide.R` | Creates one row per participant with 2022 and 2024 values, and checks complete pairs, score ranges and missingness |
| `03_descriptives.R` | Attrition by group and community, outcome means by group, descriptive difference-in-differences and community-level means |
| `04_did_complete_case.R` | Primary analysis, the unadjusted complete-case difference-in-differences |
| `05_adjusted_did_ancova.R` | Sensitivity analyses with covariate-adjusted difference-in-differences and ANCOVA |
| `06_multiple_imputation.R` | Sensitivity analysis for missing endline outcomes using 100 multiple imputations |
| `07_holm_correction.R` | Combines the five specifications and applies Holm correction |
| `08_attrition_loo.R` | Attrition by outcome and leave-one-community-out estimates |
| `09_export_results.R` | Final results table and results workbook |

## Data

The data are not included in this repository because they contain information on children and their caregivers. The de-identified analytical datasets are available from the author upon reasonable request.

The scripts expect two files in a `data/` folder.

| File | Contents |
|---|---|
| `children_data.rds` | 1,200 rows (600 children at Wave 0 in 2022 and Wave 2 in 2024), 17 variables |
| `caregivers_data.rds` | 1,200 rows (600 caregivers at Wave 0 in 2022 and Wave 2 in 2024), 18 variables |

## Outcomes

Children (9): school enrollment, attendance rate, literacy, numeracy, hygiene, dietary diversity, socio-emotional development, height and weight.

Caregivers (5): monthly income, monthly savings, savings group membership, food security and empowerment.

## Methods

| Specification | Model | Sample |
|---|---|---|
| `DiD_complete_case` (primary) | Change in outcome regressed on intervention status | Participants observed at both waves |
| `DiD_adjusted_complete_case` | As above, with baseline covariates | Participants observed at both waves |
| `ANCOVA_complete_case` | Endline outcome regressed on intervention status, baseline outcome and covariates | Participants observed at both waves |
| `DiD_MI` | Unadjusted difference-in-differences after multiple imputation | All baseline participants |
| `ANCOVA_MI` | ANCOVA after multiple imputation | All baseline participants |

Baseline covariates are age and sex for children, and age, education and household size for caregivers.

All models use ordinary least squares, with linear probability models for binary outcomes. Inference uses CR2 bias-reduced cluster-robust standard errors clustered by community, with Satterthwaite degrees of freedom and t-based 95% confidence intervals.

Multiple imputation uses outcome-specific Bayesian predictive mean matching with 100 imputations and five donors drawn from the same community. Estimates are pooled with Rubin's rules and Barnard-Rubin degrees of freedom. The random seed is set in `00_setup.R`, so the imputation results are fully reproducible.

Holm correction is applied across all 14 outcomes within each specification, with supplementary corrections within the child and caregiver outcomes.

## Requirements

The analysis was run with R 4.5.2 on Windows 11 and the following packages.

| Package | Version |
|---|---|
| clubSandwich | 0.7.0 |
| dplyr | 1.1.4 |
| tidyr | 1.3.2 |
| writexl | 2.0.1 |

Install the packages with

```r
install.packages(c("clubSandwich", "dplyr", "tidyr", "writexl"))
```

## How to run

1. Create a project folder containing the `scripts/` folder from this repository and a `data/` folder with the two data files.
2. Set the project folder as the working directory in R.
3. Run the scripts in order from `00` to `09`.

```r
setwd("path/to/project")

scripts <- sprintf("scripts/%s", sort(list.files("scripts", pattern = "\\.R$")))
for (s in scripts) source(s, echo = TRUE)
```

Script `06_multiple_imputation.R` takes a few minutes. The other scripts run in seconds.

## Output

The scripts create an `output/` folder containing intermediate `.rds` files and the results workbook `analysis_results.xlsx`, which has nine sheets.

| Sheet | Contents |
|---|---|
| `results_70` | Coefficient, standard error, degrees of freedom, 95% CI, raw and Holm-adjusted p-values and sample size for 14 outcomes under five specifications |
| `attrition_group` | Baseline sample, endline follow-up and attrition by group |
| `attrition_community` | The same by community |
| `group_means` | Baseline, endline and paired change means by group |
| `descriptive_DiD` | Paired change by group and their difference |
| `community_means` | Baseline, endline and paired change means by community |
| `community_change` | Mean paired change by community |
| `attrition_by_outcome` | Number missing and baseline means of retained and missing participants |
| `leave_one_out` | Primary estimate with each community omitted in turn |

Effects for school enrollment and savings group membership are reported in percentage points. Other outcomes retain their original units.
This code is released under the MIT License.
