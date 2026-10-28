###############################################################################
# 06_multiple_imputation
# Sensitivity analysis for missing endline outcomes.
#   100 imputations per outcome by Bayesian predictive mean matching (type 1),
#   five nearest donors within the same community. Each outcome is imputed
#   separately. Unadjusted DiD and ANCOVA are fitted in each completed dataset
#   with CR2 inference and pooled by Rubin's rules with Barnard-Rubin degrees
#   of freedom. A single random-number stream is used (seed set in
#   00_setup.R), processing children before caregivers in the outcome order
#   defined in 00_setup.R.
# Input:  output/ch_wide.rds, output/cg_wide.rds
# Output: output/mi_results.rds
###############################################################################

source("scripts/00_setup.R")

ch_wide <- readRDS(file.path(out_dir, "ch_wide.rds"))
cg_wide <- readRDS(file.path(out_dir, "cg_wide.rds"))

X_ch <- build_X(ch_wide, child_outcomes, ch_cov)
X_cg <- build_X(cg_wide, cg_outcomes,    cg_cov)
colnames(X_ch)
colnames(X_cg)

set.seed(mi_seed)
mi_ch <- run_mi(ch_wide, child_outcomes, "Children",   ch_cov, X_ch)
mi_cg <- run_mi(cg_wide, cg_outcomes,    "Caregivers", cg_cov, X_cg)

did_mi    <- rbind(mi_ch$did,    mi_cg$did);    rownames(did_mi)    <- NULL
ancova_mi <- rbind(mi_ch$ancova, mi_cg$ancova); rownames(ancova_mi) <- NULL

show_table(did_mi    %>% select(-dataset, -model))
show_table(ancova_mi %>% select(-dataset, -model))

saveRDS(bind_rows(did_mi, ancova_mi), file.path(out_dir, "mi_results.rds"))
