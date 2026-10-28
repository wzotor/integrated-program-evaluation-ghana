###############################################################################
# 01_data_validation
# Validation of the analytical datasets: duplicates, identifiers, community
# and group consistency, year-wave correspondence, child-caregiver links and
# baseline sample composition.
# Input:  data/children_data.rds, data/caregivers_data.rds
###############################################################################

source("scripts/00_setup.R")

children   <- readRDS(file.path(data_dir, "children_data.rds"))
caregivers <- readRDS(file.path(data_dir, "caregivers_data.rds"))

dim(children)
dim(caregivers)

# ---- Participant-wave duplicates --------------------------------------------
sum(duplicated(children[, c("Child_ID", "Wave")]))
sum(duplicated(caregivers[, c("Caregiver_ID", "Wave")]))

# ---- Missing identifiers ----------------------------------------------------
sum(is.na(children$Child_ID))
sum(is.na(caregivers$Caregiver_ID))
sum(is.na(caregivers$Child_ID))

# ---- Community and group consistency across waves ---------------------------
children %>% group_by(Child_ID) %>%
  summarise(n_comm = n_distinct(Community), n_grp = n_distinct(Group)) %>%
  filter(n_comm > 1 | n_grp > 1) %>% nrow()
caregivers %>% group_by(Caregiver_ID) %>%
  summarise(n_comm = n_distinct(Community), n_grp = n_distinct(Group)) %>%
  filter(n_comm > 1 | n_grp > 1) %>% nrow()

# ---- Year-wave correspondence -----------------------------------------------
table(children$Year, children$Wave)
table(caregivers$Year, caregivers$Wave)

# ---- Child-caregiver links --------------------------------------------------
links <- caregivers %>% distinct(Caregiver_ID, Child_ID)
nrow(links)
n_distinct(links$Caregiver_ID)
n_distinct(links$Child_ID)
all(sort(unique(children$Child_ID)) == sort(unique(caregivers$Child_ID)))

link_check <- caregivers %>%
  select(Child_ID, Wave, cg_comm = Community, cg_grp = Group) %>%
  inner_join(children %>% select(Child_ID, Wave, Community, Group),
             by = c("Child_ID", "Wave"))
nrow(link_check)
sum(link_check$cg_comm != link_check$Community |
    link_check$cg_grp  != link_check$Group)

# ---- Baseline sample by community and group ---------------------------------
table(children$Community[children$Wave == 0], children$Group[children$Wave == 0])
table(caregivers$Community[caregivers$Wave == 0])

# ---- Endline observation status ---------------------------------------------
table(children$Obs_Status[children$Wave == 2])
table(caregivers$Obs_Status[caregivers$Wave == 2])
