###############################################################################
# 03_descriptives
# Attrition by group and community, outcome means by group, descriptive
# difference-in-differences and community-level means.
# Input:  output/ch_wide.rds, output/cg_wide.rds
# Output: output/descriptives.rds
###############################################################################

source("scripts/00_setup.R")

ch_wide <- readRDS(file.path(out_dir, "ch_wide.rds"))
cg_wide <- readRDS(file.path(out_dir, "cg_wide.rds"))

# ---- Attrition --------------------------------------------------------------
attr_group <- bind_rows(
  attrition_table(ch_wide, "Group") %>% mutate(dataset = "Children"),
  attrition_table(cg_wide, "Group") %>% mutate(dataset = "Caregivers"))
attr_comm <- bind_rows(
  attrition_table(ch_wide, c("Group", "Community")) %>% mutate(dataset = "Children"),
  attrition_table(cg_wide, c("Group", "Community")) %>% mutate(dataset = "Caregivers"))
attr_group
attr_comm

# ---- Group means ------------------------------------------------------------
group_means <- bind_rows(outcome_means(ch_wide, child_outcomes, "Group"),
                         outcome_means(cg_wide, cg_outcomes,    "Group"))
show_table(group_means, 2)

# ---- Descriptive DiD (paired change, intervention minus comparison) ---------
did_desc <- group_means %>%
  select(outcome, Group, mean_change) %>%
  pivot_wider(names_from = Group, values_from = mean_change) %>%
  mutate(DiD = Intervention - Comparison)
show_table(did_desc, 3)

# ---- Community means --------------------------------------------------------
comm_means <- bind_rows(outcome_means(ch_wide, child_outcomes, c("Group", "Community")),
                        outcome_means(cg_wide, cg_outcomes,    c("Group", "Community")))
show_table(comm_means, 2)

all.equal(comm_means$endline_mean - comm_means$baseline_mean_pairs,
          comm_means$mean_change)

comm_change <- comm_means %>%
  select(outcome, Community, mean_change) %>%
  pivot_wider(names_from = Community, values_from = mean_change)
show_table(comm_change, 2)

saveRDS(list(attr_group  = attr_group,
             attr_comm   = attr_comm,
             group_means = group_means,
             did_desc    = did_desc,
             comm_means  = comm_means,
             comm_change = comm_change),
        file.path(out_dir, "descriptives.rds"))
