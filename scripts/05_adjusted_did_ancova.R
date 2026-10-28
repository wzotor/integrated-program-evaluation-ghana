###############################################################################
# 05_adjusted_did_ancova
# Sensitivity analyses on complete cases.
#   Adjusted DiD: change = alpha + tau * Intervention + baseline covariates
#   ANCOVA:       Y_2024 = alpha + tau * Intervention + gamma * Y_2022
#                          + baseline covariates
#                 (Y_2022 omitted when constant)
#   Covariates:   children   - age, sex (female = 1)
#                 caregivers - age, education (0 none, 1 primary, 2 JHS),
#                              household size
#   Inference as in 04_did_complete_case.R.
# Input:  output/ch_wide.rds, output/cg_wide.rds
# Output: output/adjusted_did_ancova.rds
###############################################################################

source("scripts/00_setup.R")

ch_wide <- readRDS(file.path(out_dir, "ch_wide.rds"))
cg_wide <- readRDS(file.path(out_dir, "cg_wide.rds"))

# ---- Adjusted DiD -----------------------------------------------------------
did_adj <- rbind(
  run_model(ch_wide, child_outcomes, "Children",   ch_cov, "DiD_adjusted_complete_case"),
  run_model(cg_wide, cg_outcomes,    "Caregivers", cg_cov, "DiD_adjusted_complete_case"))
show_table(did_adj %>% select(-dataset, -model))
signif(did_adj$p_raw, 3)

# ---- ANCOVA -----------------------------------------------------------------
ancova_cc <- rbind(
  run_model(ch_wide, child_outcomes, "Children",   ch_cov, "ANCOVA_complete_case"),
  run_model(cg_wide, cg_outcomes,    "Caregivers", cg_cov, "ANCOVA_complete_case"))
show_table(ancova_cc %>% select(-dataset, -model))
signif(ancova_cc$p_raw, 3)

saveRDS(bind_rows(did_adj, ancova_cc), file.path(out_dir, "adjusted_did_ancova.rds"))
