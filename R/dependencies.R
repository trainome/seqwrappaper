##############################################################################
# Dependencies.
#
# This file exists so that `R CMD check` accepts every package declared in
# `Imports:` of DESCRIPTION. Installing seqwrappaper checks that packages
# needed to re-run the analysis are available.
#
# The function is never called. Each `pkg::symbol` line below is just a
# parser-visible reference into the namespace.

.deps <- function() {
  broom.mixed::tidy
  DESeq2::DESeq
  DHARMa::simulateResiduals
  dplyr::filter
  edgeR::DGEList
  glmmTMB::glmmTMB
  here::here
  jsonlite::fromJSON
  knitr::opts_chunk
  lme4::isSingular
  lmerTest::lmer
  marginaleffects::predictions
  MASS::glm.nb
  purrr::walk
  quarto::quarto_render
  seqwrap::seqwrap
  SummarizedExperiment::assay
  tibble::rownames_to_column
  tidyr::pivot_longer
  tidyselect::all_of
  ggtext::element_markdown
  cowplot::plot_grid
  clusterProfiler::enrichGO
  ComplexUpset::upset
  ggplot2::ggplot
  org.Hs.eg.db::org.Hs.eg.db
  invisible(NULL)
}
