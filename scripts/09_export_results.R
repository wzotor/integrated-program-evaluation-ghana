###############################################################################
# 09_export_results
# Final results table for the five specifications (14 outcomes each) and the
# results workbook. Binary outcomes are reported in percentage points.
# Input:  output/all_results.rds, output/descriptives.rds,
#         output/attrition_by_outcome.rds, output/leave_one_out.rds
# Output: output/analysis_results.xlsx
###############################################################################

source("scripts/00_setup.R")

all_results <- readRDS(file.path(out_dir, "all_results.rds"))
desc        <- readRDS(file.path(out_dir, "descriptives.rds"))
attr_out    <- readRDS(file.path(out_dir, "attrition_by_outcome.rds"))
loo         <- readRDS(file.path(out_dir, "leave_one_out.rds"))

final_results <- all_results %>%
  mutate(scale   = if_else(outcome %in% binary_outcomes, 100, 1),
         unit    = if_else(outcome %in% binary_outcomes, "percentage points", "original units"),
         coef    = coef * scale,
         se      = se * scale,
         ci_low  = ci_low * scale,
         ci_high = ci_high * scale) %>%
  select(dataset, outcome, model, unit, n, coef, se, df, ci_low, ci_high,
         p_raw, p_holm_14, p_holm_within_dataset, between_var, mcse) %>%
  arrange(model, factor(outcome, levels = c(child_outcomes, cg_outcomes)))

dim(final_results)
show_table(final_results %>%
             filter(outcome %in% binary_outcomes) %>%
             select(outcome, model, coef, se, ci_low, ci_high), 2)

write_xlsx(
  list(
    results_70           = final_results,
    attrition_group      = desc$attr_group,
    attrition_community  = desc$attr_comm,
    group_means          = desc$group_means,
    descriptive_DiD      = desc$did_desc,
    community_means      = desc$comm_means,
    community_change     = desc$comm_change,
    attrition_by_outcome = attr_out,
    leave_one_out        = loo
  ),
  file.path(out_dir, "analysis_results.xlsx")
)
