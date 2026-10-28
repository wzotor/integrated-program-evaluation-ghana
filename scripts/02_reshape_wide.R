###############################################################################
# 02_reshape_wide
# One row per participant with 2022 (_0) and 2024 (_2) values. All baseline
# participants are retained. Also checks complete pairs, score ranges and
# missingness.
# Input:  data/children_data.rds, data/caregivers_data.rds
# Output: output/ch_wide.rds, output/cg_wide.rds
###############################################################################

source("scripts/00_setup.R")

children   <- readRDS(file.path(data_dir, "children_data.rds"))
caregivers <- readRDS(file.path(data_dir, "caregivers_data.rds"))

# ---- Children ---------------------------------------------------------------
ch_base <- children %>% filter(Wave == 0) %>%
  select(Child_ID, Community, Group, Age, Sex, all_of(child_outcomes)) %>%
  rename_with(~ paste0(.x, "_0"), all_of(child_outcomes))
ch_end <- children %>% filter(Wave == 2) %>%
  select(Child_ID, Obs_Status, all_of(child_outcomes)) %>%
  rename_with(~ paste0(.x, "_2"), all_of(child_outcomes))
ch_wide <- ch_base %>%
  left_join(ch_end, by = "Child_ID") %>%
  mutate(Intervention = if_else(Group == "Intervention", 1, 0),
         Female       = if_else(Sex == "Female", 1, 0),
         Observed     = if_else(Obs_Status == "Observed", 1, 0))

# ---- Caregivers -------------------------------------------------------------
cg_base <- caregivers %>% filter(Wave == 0) %>%
  select(Caregiver_ID, Child_ID, Community, Group, Age, Caregiver_Education,
         Household_Size, all_of(cg_outcomes)) %>%
  rename_with(~ paste0(.x, "_0"), all_of(cg_outcomes))
cg_end <- caregivers %>% filter(Wave == 2) %>%
  select(Caregiver_ID, Obs_Status, all_of(cg_outcomes)) %>%
  rename_with(~ paste0(.x, "_2"), all_of(cg_outcomes))
cg_wide <- cg_base %>%
  left_join(cg_end, by = "Caregiver_ID") %>%
  mutate(Intervention = if_else(Group == "Intervention", 1, 0),
         Observed     = if_else(Obs_Status == "Observed", 1, 0))

dim(ch_wide)
dim(cg_wide)

# ---- Complete pairs ---------------------------------------------------------
table(ch_wide$Group, ch_wide$Observed)
table(cg_wide$Group, cg_wide$Observed)

sapply(child_outcomes, function(v)
  sum(!is.na(ch_wide[[paste0(v, "_0")]]) & !is.na(ch_wide[[paste0(v, "_2")]])))
sapply(cg_outcomes, function(v)
  sum(!is.na(cg_wide[[paste0(v, "_0")]]) & !is.na(cg_wide[[paste0(v, "_2")]])))

# ---- Score ranges and missingness -------------------------------------------
range_table(ch_wide, child_outcomes)
range_table(cg_wide, cg_outcomes)

# Baseline savings group membership
table(cg_wide$Savings_Group_Membership_0)

saveRDS(ch_wide, file.path(out_dir, "ch_wide.rds"))
saveRDS(cg_wide, file.path(out_dir, "cg_wide.rds"))
