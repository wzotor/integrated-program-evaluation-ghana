###############################################################################
# 00_setup
# Packages, folder paths, analysis settings and shared functions.
#
# Project: Effects of an Integrated Community-Based Program on Child
#          Development and Caregiver Well-Being: Quasi-Experimental Evidence
#          from Rural Ghana
# Author:  Wisdom Zotor
#
# Required packages: readxl, dplyr, tidyr, writexl, clubSandwich
# Input data (data/): children_data.rds, caregivers_data.rds
#   De-identified analytical datasets, Wave 0 (2022) and Wave 2 (2024).
# Scripts are stored in scripts/ and run from the project root folder,
# in order 00 to 09.
###############################################################################

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(writexl)
  library(clubSandwich)
})

# ---- Paths ------------------------------------------------------------------
data_dir <- "data"
out_dir  <- "output"
if (!dir.exists(out_dir)) dir.create(out_dir)

# ---- Analysis settings ------------------------------------------------------
child_outcomes <- c("Sch_Enroll", "Sch_Attend_Rate", "Lit_Score", "Num_Score",
                    "Hygiene_Score", "Nutrition_Score", "SocioEmo_Score",
                    "Height_cm", "Weight_kg")
cg_outcomes    <- c("Income_GHS", "Savings_GHS", "Savings_Group_Membership",
                    "Food_Security_Score", "Empowerment_Score")

ch_cov <- c("Age", "Female")
cg_cov <- c("Age", "Caregiver_Education", "Household_Size")

binary_outcomes <- c("Sch_Enroll", "Savings_Group_Membership")

model_levels <- c("DiD_complete_case", "DiD_adjusted_complete_case",
                  "ANCOVA_complete_case", "DiD_MI", "ANCOVA_MI")

mi_seed <- 2026
mi_m    <- 100


###############################################################################
# Shared functions
###############################################################################

# Minimum, maximum and missing count of each outcome at both waves.
range_table <- function(data, outcomes) {
  do.call(rbind, lapply(outcomes, function(v) {
    x0 <- data[[paste0(v, "_0")]]
    x2 <- data[[paste0(v, "_2")]]
    data.frame(outcome      = v,
               min_2022     = min(x0, na.rm = TRUE), max_2022 = max(x0, na.rm = TRUE),
               min_2024     = min(x2, na.rm = TRUE), max_2024 = max(x2, na.rm = TRUE),
               missing_2022 = sum(is.na(x0)),        missing_2024 = sum(is.na(x2)))
  }))
}

# Baseline sample, endline follow-up and attrition.
attrition_table <- function(data, by) {
  data %>%
    group_by(across(all_of(by))) %>%
    summarise(baseline_n       = n(),
              endline_observed = sum(Observed),
              missing          = baseline_n - endline_observed,
              attrition_pct    = round(100 * missing / baseline_n, 1),
              .groups = "drop")
}

# Outcome means by a grouping.
#   baseline_mean_all:   2022 mean, all baseline participants
#   baseline_mean_pairs: 2022 mean, participants observed at both waves
#   endline_mean:        2024 mean, participants observed at both waves
#   mean_change:         mean within-person change
outcome_means <- function(data, outcomes, by) {
  do.call(rbind, lapply(outcomes, function(v) {
    data %>%
      mutate(y0   = .data[[paste0(v, "_0")]],
             y2   = .data[[paste0(v, "_2")]],
             pair = !is.na(y0) & !is.na(y2)) %>%
      group_by(across(all_of(by))) %>%
      summarise(outcome             = v,
                n_baseline          = sum(!is.na(y0)),
                baseline_mean_all   = mean(y0, na.rm = TRUE),
                n_pairs             = sum(pair),
                baseline_mean_pairs = mean(y0[pair]),
                endline_mean        = mean(y2[pair]),
                mean_change         = mean(y2[pair] - y0[pair]),
                .groups = "drop")
  }))
}

# CR2 cluster-robust inference for one coefficient: identity working
# covariance, Satterthwaite degrees of freedom, t-based 95% CI.
cr2_test <- function(model, cluster, term = "Intervention") {
  ct  <- as.data.frame(coef_test(model, vcov = "CR2", cluster = cluster,
                                 test = "Satterthwaite"))
  row <- ct[ct$Coef == term, ]
  est <- row$beta; se <- row$SE; df <- row$df_Satt
  data.frame(coef    = est,
             se      = se,
             df      = df,
             ci_low  = est - qt(0.975, df) * se,
             ci_high = est + qt(0.975, df) * se,
             p_raw   = 2 * pt(abs(est / se), df, lower.tail = FALSE))
}

# Complete-case models, clustered by community.
#   DiD_complete_case:          change ~ Intervention
#   DiD_adjusted_complete_case: change ~ Intervention + baseline covariates
#   ANCOVA_complete_case:       Y_2024 ~ Intervention + Y_2022 + covariates
#                               (Y_2022 omitted when constant)
run_model <- function(data, outcomes, dataset, covars, type) {
  do.call(rbind, lapply(outcomes, function(v) {
    d <- data %>%
      mutate(y0 = .data[[paste0(v, "_0")]], y2 = .data[[paste0(v, "_2")]]) %>%
      filter(!is.na(y0), !is.na(y2)) %>%
      mutate(dY = y2 - y0)
    f <- switch(type,
      DiD_complete_case          = dY ~ Intervention,
      DiD_adjusted_complete_case = reformulate(c("Intervention", covars), response = "dY"),
      ANCOVA_complete_case       = reformulate(c("Intervention", if (sd(d$y0) > 0) "y0", covars),
                                               response = "y2"))
    m <- lm(f, data = d)
    cbind(dataset = dataset, outcome = v, model = type,
          n = nrow(d), cr2_test(m, d$Community))
  }))
}

# Imputation predictor matrix: intercept, nonconstant baseline outcomes,
# baseline covariates, community indicators and intervention-by-baseline
# outcome interactions. Linearly dependent columns removed by pivoted QR.
build_X <- function(data, outcomes, covars) {
  base_vars <- paste0(outcomes, "_0")
  base_vars <- base_vars[sapply(base_vars, function(b) sd(data[[b]]) > 0)]
  X <- cbind(Intercept = 1,
             as.matrix(data[, c(base_vars, covars)]),
             model.matrix(~ Community - 1, data = data),
             sapply(base_vars, function(b) data$Intervention * data[[b]]))
  colnames(X)[(ncol(X) - length(base_vars) + 1):ncol(X)] <- paste0("Int_x_", base_vars)
  q <- qr(X)
  X[, sort(q$pivot[seq_len(q$rank)]), drop = FALSE]
}

# Bayesian predictive mean matching (type 1) with k donors from the same
# community.
impute_pmm <- function(y, X, community, k = 5) {
  obs <- !is.na(y); mis <- !obs
  Xo <- X[obs, , drop = FALSE]; yo <- y[obs]

  XtX_inv  <- solve(crossprod(Xo))
  beta_hat <- XtX_inv %*% crossprod(Xo, yo)
  rss      <- sum((yo - Xo %*% beta_hat)^2)
  df_res   <- nrow(Xo) - ncol(Xo)

  sigma2_star <- rss / rchisq(1, df_res)
  beta_star   <- beta_hat + t(chol(sigma2_star * XtX_inv)) %*% rnorm(ncol(Xo))

  yhat_obs <- as.vector(Xo %*% beta_hat)
  yhat_mis <- as.vector(X[mis, , drop = FALSE] %*% beta_star)

  y_new   <- y
  idx_obs <- which(obs); idx_mis <- which(mis)
  for (j in seq_along(idx_mis)) {
    same   <- community[idx_obs] == community[idx_mis[j]]
    pool   <- idx_obs[same]
    dist   <- abs(yhat_obs[same] - yhat_mis[j])
    donors <- pool[order(dist)[1:min(k, length(pool))]]
    y_new[idx_mis[j]] <- y[donors[sample.int(length(donors), 1)]]
  }
  y_new
}

# Rubin's rules with Barnard-Rubin small-sample degrees of freedom; the
# complete-data reference is the mean CR2 Satterthwaite df across imputations.
pool_rubin <- function(est, se, df_com) {
  m      <- length(est)
  qbar   <- mean(est)
  ubar   <- mean(se^2)
  b      <- var(est)
  t_var  <- ubar + (1 + 1/m) * b
  lambda <- (1 + 1/m) * b / t_var
  nu_com <- mean(df_com)
  nu_obs <- (nu_com + 1) / (nu_com + 3) * nu_com * (1 - lambda)
  nu_old <- if (lambda > 0) (m - 1) / lambda^2 else Inf
  df     <- if (is.finite(nu_old)) nu_old * nu_obs / (nu_old + nu_obs) else nu_obs
  se_t   <- sqrt(t_var)
  data.frame(coef        = qbar,
             se          = se_t,
             df          = df,
             ci_low      = qbar - qt(0.975, df) * se_t,
             ci_high     = qbar + qt(0.975, df) * se_t,
             p_raw       = 2 * pt(abs(qbar / se_t), df, lower.tail = FALSE),
             between_var = b,
             mcse        = sqrt(b / m))
}

# Outcome-specific multiple imputation; DiD and ANCOVA with CR2 inference in
# each completed dataset, pooled by Rubin's rules.
run_mi <- function(data, outcomes, dataset, covars, X, M = mi_m) {
  did_rows <- list(); anc_rows <- list()
  for (v in outcomes) {
    y0 <- data[[paste0(v, "_0")]]
    y2 <- data[[paste0(v, "_2")]]
    did_res <- matrix(NA, M, 3)
    anc_res <- matrix(NA, M, 3)
    for (i in 1:M) {
      y2_imp <- impute_pmm(y2, X, data$Community)
      d <- data %>% mutate(y0 = y0, y2 = y2_imp, dY = y2 - y0)
      m1  <- lm(dY ~ Intervention, data = d)
      m2  <- lm(reformulate(c("Intervention", if (sd(d$y0) > 0) "y0", covars),
                            response = "y2"), data = d)
      r1 <- cr2_test(m1, d$Community)
      r2 <- cr2_test(m2, d$Community)
      did_res[i, ] <- c(r1$coef, r1$se, r1$df)
      anc_res[i, ] <- c(r2$coef, r2$se, r2$df)
    }
    did_rows[[v]] <- cbind(dataset = dataset, outcome = v, model = "DiD_MI",
                           n = nrow(data), pool_rubin(did_res[, 1], did_res[, 2], did_res[, 3]))
    anc_rows[[v]] <- cbind(dataset = dataset, outcome = v, model = "ANCOVA_MI",
                           n = nrow(data), pool_rubin(anc_res[, 1], anc_res[, 2], anc_res[, 3]))
    message("Imputation complete: ", v)
  }
  list(did = do.call(rbind, did_rows), ancova = do.call(rbind, anc_rows))
}

# Baseline means of participants retained and missing at endline.
attrition_outcome <- function(data, outcomes, dataset) {
  do.call(rbind, lapply(outcomes, function(v) {
    y0   <- data[[paste0(v, "_0")]]
    y2   <- data[[paste0(v, "_2")]]
    kept <- !is.na(y2)
    data.frame(dataset            = dataset,
               outcome            = v,
               n_missing_endline  = sum(!kept),
               baseline_mean_kept = mean(y0[kept]),
               baseline_mean_lost = mean(y0[!kept]),
               difference         = mean(y0[!kept]) - mean(y0[kept]))
  }))
}

# Unadjusted complete-case DiD estimate, omitting one community at a time.
loo_did <- function(data, outcomes, dataset) {
  comms <- sort(unique(data$Community))
  do.call(rbind, lapply(outcomes, function(v) {
    est <- sapply(comms, function(cm) {
      d <- data %>%
        filter(Community != cm) %>%
        mutate(dY = .data[[paste0(v, "_2")]] - .data[[paste0(v, "_0")]]) %>%
        filter(!is.na(dY))
      unname(coef(lm(dY ~ Intervention, data = d))["Intervention"])
    })
    names(est) <- paste0("drop_", comms)
    data.frame(dataset = dataset, outcome = v, t(est),
               min = min(est), max = max(est), check.names = FALSE)
  }))
}

# Rounded display of a results table.
show_table <- function(x, digits = 4) {
  as.data.frame(x %>% mutate(across(where(is.numeric), ~ round(.x, digits))))
}
