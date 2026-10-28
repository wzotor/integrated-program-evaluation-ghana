###############################################################################
# 07_holm_correction
# Combines the five specifications and applies Holm correction.
#   Main:          across all 14 outcomes within each specification
#   Supplementary: within child (9) and caregiver (5) outcomes separately
# Input:  output/did_complete_case.rds, output/adjusted_did_ancova.rds,
#         output/mi_results.rds
# Output: output/all_results.rds
###############################################################################

source("scripts/00_setup.R")

all_results <- bind_rows(readRDS(file.path(out_dir, "did_complete_case.rds")),
                         readRDS(file.path(out_dir, "adjusted_did_ancova.rds")),
                         readRDS(file.path(out_dir, "mi_results.rds"))) %>%
  mutate(model = factor(model, levels = model_levels)) %>%
  group_by(model) %>%
  mutate(p_holm_14 = p.adjust(p_raw, method = "holm")) %>%
  group_by(model, dataset) %>%
  mutate(p_holm_within_dataset = p.adjust(p_raw, method = "holm")) %>%
  ungroup()

nrow(all_results)

holm_table <- all_results %>%
  select(outcome, model, p_holm_14) %>%
  pivot_wider(names_from = model, values_from = p_holm_14)
as.data.frame(holm_table %>% mutate(across(where(is.numeric), ~ signif(.x, 3))))

all_results %>%
  group_by(model) %>%
  summarise(sig_raw     = sum(p_raw < 0.05),
            sig_holm_14 = sum(p_holm_14 < 0.05),
            sig_holm_ds = sum(p_holm_within_dataset < 0.05))

saveRDS(all_results, file.path(out_dir, "all_results.rds"))
