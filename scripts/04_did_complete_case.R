###############################################################################
# 04_did_complete_case
# Primary analysis: unadjusted complete-case difference-in-differences.
#   Model: (Y_2024 - Y_2022) = alpha + tau * Intervention + error
#   Inference: CR2 cluster-robust standard errors clustered by community,
#   Satterthwaite degrees of freedom, t-based 95% confidence intervals.
# Input:  output/ch_wide.rds, output/cg_wide.rds, output/descriptives.rds
# Output: output/did_complete_case.rds
###############################################################################

source("scripts/00_setup.R")

ch_wide <- readRDS(file.path(out_dir, "ch_wide.rds"))
cg_wide <- readRDS(file.path(out_dir, "cg_wide.rds"))
desc    <- readRDS(file.path(out_dir, "descriptives.rds"))

did_cc <- rbind(
  run_model(ch_wide, child_outcomes, "Children",   ch_cov, "DiD_complete_case"),
  run_model(cg_wide, cg_outcomes,    "Caregivers", cg_cov, "DiD_complete_case"))

show_table(did_cc %>% select(-dataset, -model))
signif(did_cc$p_raw, 3)

# Regression estimate equals the descriptive DiD
all.equal(did_cc$coef, desc$did_desc$DiD)

saveRDS(did_cc, file.path(out_dir, "did_complete_case.rds"))
