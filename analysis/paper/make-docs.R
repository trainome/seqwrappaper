##############################################################################
#
# Make documentation
#
# This file runs the full analysis pipeline (model fitting, figures) and
# renders the manuscript and supplement. If model estimates are not present in
# analysis/data/derived_data/, functions run_modelN will place reproduced
# estimates there. Rerunning all model estimates will take > 2 hours.
# To overwrite previous results, set overwrite_models to TRUE (row 70).
#
# Simulation results are re-run if make_sim is set to TRUE. Running simulation
# results takes > 24 hours (dependent on number of cores). We recommend
# downloading simulation results from Dataverse
# (https://doi.org/10.18710/I7U71O), see the README for instructions.
#
##############################################################################

# Restore the package environment
renv::restore()

# Restore package versions (lmerSeq is locked as a Local source pointing at
# inst/lmerSeq_0.1.7.tar.gz. If installing lmerSeq is problematic it can be
# installed directly from source:
# renv::install("inst/lmerSeq_0.1.7.tar.gz")

# Install the research compendium package
renv::install(".")

# Packages assumed in analysis/R/
library(seqwrappaper)
library(seqwrap)
library(tidyverse)
library(glmmTMB)
library(edgeR)
library(DESeq2)
library(lmerTest)
library(DHARMa)

# Source paper-specific orchestrators (not part of the package API)
source(here::here("analysis/R/model-functions.R"))
source(here::here("analysis/R/simulation-functions.R"))

# Re-run simulations?
make_sim <- FALSE

# Detect cores
cores <- parallel::detectCores()

# Re-run simulations
if (make_sim) {
  # NOTE: sim_wrap1/sim_wrap2 reference `trend_model_observed` and
  # `trend_model_observed_noweights` which are constructed in
  # analysis/figures/figure-2.R. That script must be sourced first
  # (or the trend models otherwise made available) before calling the
  # wrappers.
  source(here::here("analysis/figures/figure-2.R"))
  sim_wrap1(cores = cores)
  sim_wrap2(cores = cores)
} else {
  download_dataverse()
}

# Check if simulation results are present
if (!dir.exists(here::here("analysis/data/raw_data"))) {
  warning(
    "Simulation results are not present in this repository. ",
    "Results can be downloaded from Dataverse ",
    "(https://doi.org/10.18710/I7U71O). The simulation results are needed ",
    "to reproduce results in the manuscript."
  )
}


# Fit models on the real-world (Pillon) data
# This makes the model results available in the environment (and saves to
# disk).

# Set this to TRUE if refit models
overwrite_models <- FALSE

m1_results <- run_model1(CORES = cores, overwrite = overwrite_models)
m2_results <- run_model2(CORES = cores, overwrite = overwrite_models)
m3_results <- run_model3(CORES = cores, overwrite = overwrite_models)
m4_results <- run_model4(CORES = cores, overwrite = overwrite_models)
m5_results <- run_model5(CORES = cores, overwrite = overwrite_models)


# Source figure files (these are needed for the manuscript and supplement)
source(here::here("analysis/figures/figure-2.R"))
source(here::here("analysis/figures/figure-3.R"))
source(here::here("analysis/figures/figure-4.R"))

# Render documentation
quarto::quarto_render(here::here("analysis/paper/paper.qmd"))
quarto::quarto_render(here::here("analysis/paper/supplement.qmd"))
