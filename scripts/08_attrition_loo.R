###############################################################################
# 08_attrition_loo
# Attrition by outcome and leave-one-community-out influence checks.
#   Attrition: number missing at endline and baseline means of retained and
#              missing participants.
#   Leave-one-community-out: unadjusted complete-case DiD point estimate with
#              each community omitted in turn (influence checks, not
#              confirmatory tests).
# Input:  output/ch_wide.rds, output/cg_wide.rds
# Output: output/attrition_by_outcome.rds, output/leave_one_out.rds
###############################################################################

source("scripts/00_setup.R")

ch_wide <- readRDS(file.path(out_dir, "ch_wide.rds"))
cg_wide <- readRDS(file.path(out_dir, "cg_wide.rds"))

attr_out <- rbind(attrition_outcome(ch_wide, child_outcomes, "Children"),
                  attrition_outcome(cg_wide, cg_outcomes,    "Caregivers"))
show_table(attr_out, 2)

loo <- rbind(loo_did(ch_wide, child_outcomes, "Children"),
             loo_did(cg_wide, cg_outcomes,    "Caregivers"))
show_table(loo %>% select(-dataset), 3)

saveRDS(attr_out, file.path(out_dir, "attrition_by_outcome.rds"))
saveRDS(loo,      file.path(out_dir, "leave_one_out.rds"))
