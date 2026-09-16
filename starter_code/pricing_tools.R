# ============================================================================
# FIN 6155 - Digital Credit Build: PRICING TOOLKIT (student reference, R).
#
# Pricing is NOT the same problem as default prediction. A PD model RANKS risk;
# setting a price to change behaviour (who accepts, who repays) is a
# TREATMENT-EFFECT question -- the causal effect of the offered APR -- which your
# observational data cannot identify without price variation. This file is a menu
# of approaches, in rough order of assumption strength, with runnable skeletons.
# Nothing here is required; pick what you can defend (and tie it to your Stage 3
# fairness audit and Stage 4 Reg B reason codes).
#
# ---- R packages worth knowing (install what you use) ----------------------
# Data/'   tidyverse            (dplyr, tidyr, readr, purrr, lubridate)
# Modeling tidymodels           (recipes, parsnip, rsample, workflows, tune)
#          glmnet               penalized logistic (LASSO/ridge) baseline
#          ranger / randomForest random forest challenger
#          xgboost / lightgbm   gradient boosting challenger
# Scoring  yardstick / pROC     AUC, KS, calibration; PRROC for PR curves
# Scorecard scorecard / smbinning  WOE/IV binning + classic credit scorecards
# Causal   grf                  causal_forest / generalized random forest (uplift)
#          DoubleML / grf       double/debiased ML for treatment effects
#          policytree           optimal treatment (pricing) policy from a causal forest
# Python?  econML (Microsoft)   the same families in Python -- DML, T-/S-/X-learners,
#                               causal forests, CATE tooling; grf's Python counterpart
# Explain  vip, DALEX, iml, fastshap  reason codes / SHAP for ADVERSE-ACTION (Reg B)
# Imbalance themis, ROSE        class-imbalance recipes (labeled defaults ~2-3%)
# install.packages(c("tidyverse","tidymodels","glmnet","ranger","xgboost",
#                    "yardstick","pROC","scorecard","grf","policytree","vip","DALEX"))

suppressMessages({ library(tidyverse) })  # add others as needed

# ---------------------------------------------------------------------------
# 1. RISK-BASED PRICING off your PD model (transparent; the default).
#    price = cost of funds + expected loss + target margin. Fully explainable,
#    so adverse-action reasons fall straight out of the PD model coefficients.
# ---------------------------------------------------------------------------
COST <- 0.04; LGD <- 0.85; TARGET_MARGIN <- 0.05
risk_based_apr <- function(pd) COST + LGD * pd + TARGET_MARGIN      # break-even + margin
# approve if the loan clears hurdle at that price:
approve_riskbased <- function(pd, apr = risk_based_apr(pd)) pd < (apr - COST) / ((apr - COST) + LGD)

# ---------------------------------------------------------------------------
# 2. ACCEPTANCE / ELASTICITY model: a SECOND model for take-up given price.
#    Needs price variation in the data to be credible. With it you can pick the
#    profit-maximising price per segment instead of a flat margin.
#    glm(accepted ~ apr + features, family = binomial)  # demand curve proxy
# ---------------------------------------------------------------------------
# accept_fit <- glm(funded ~ offered_apr + log_inc + dsr + util, binomial, data = apps)
# expected_profit(apr) = P(accept|apr) * [ P(repay) * principal*(apr-COST) - P(default)*LGD*principal ]
# choose apr that maximises expected_profit (grid or optim), subject to fair-lending limits.

# ---------------------------------------------------------------------------
# 3. CAUSAL FOREST (grf) -- heterogeneous treatment effect of PRICE.
#    WHY this and not a default classifier: you want d(default or accept)/d(apr)
#    for THIS borrower, a causal quantity, to set price. A classifier gives you
#    P(default|x), not the effect of moving the price. grf::causal_forest
#    estimates tau(x) = effect of treatment (here: a higher vs lower APR offer)
#    using the randomised price slice the data must contain to be identified.
#
#    REQUIREMENT: identification needs RANDOMISED price variation — and the
#    released data has NONE: every offered_apr is the incumbent's risk-based
#    price, so price and risk move together by construction. Any "effect of
#    price" you estimate from this data is selection, not causation — treat it
#    as descriptive, state the identification problem, and bound your pricing
#    accordingly. (Recognising this IS the graded insight; a confident causal
#    estimate from these observational prices is the trap.)
# ---------------------------------------------------------------------------
fit_pricing_causal_forest <- function(df) {
  # df needs: W = treatment (1 = high-APR offer, 0 = low-APR offer, ideally RANDOMISED
  #           on a slice), Y = outcome (default, or accept), X = borrower features.
  stopifnot(all(c("W", "Y") %in% names(df)))
  if (!requireNamespace("grf", quietly = TRUE)) stop("install.packages('grf')")
  X <- as.matrix(df[setdiff(names(df), c("W", "Y"))])
  cf <- grf::causal_forest(X = X, Y = df$Y, W = df$W)          # tau(x): effect of the higher price
  tau <- predict(cf)$predictions                               # per-borrower price sensitivity
  # OPTIONAL: turn estimated effects into a price/approve POLICY:
  #   pol <- policytree::policy_tree(X, cbind(control_profit, treat_profit), depth = 2)
  list(forest = cf, tau = tau)
}

# ---------------------------------------------------------------------------
# 4. THE REGULATORY PERIMETER (do not skip).
#    - Reg B / ECOA: you must give specific ADVERSE-ACTION reasons for a denial.
#      A causal forest or GBM that prices well but cannot be explained may be
#      UNDEPLOYABLE. Use vip / DALEX / fastshap to produce per-applicant reason
#      codes, and document them.
#    - Disparate impact: a model can proxy a protected attribute through
#      cash-flow features. Audit prices AND approvals across group A/B (Stage 3),
#      not just the PD. The cleverest pricing model is worthless if it fails the
#      four-fifths test or you can't explain a denial.
# ============================================================================

# ---------------------------------------------------------------------------
# Tail padding (mounted-FS truncation guard)
# pad pad pad pad pad pad pad pad pad pad pad pad pad pad pad pad pad pad pad
# END
