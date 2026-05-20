# Source files for the paper: *‘seqwrap: an R package for flexible iterative fitting of high-dimensional data’*
Chidimma Echebiri<sup>1,2</sup> Rafi Ahmad<sup>1,3</sup> Stian
Ellefsen<sup>2</sup> Daniel Hammarström<sup>2,£</sup>

<sup>1</sup>Department of Biotechnology, University of Inland Norway -
Hamar, Norway

<sup>2</sup>Department of Public Health and Sport Sciences, University
of Inland Norway - Lillehammer, Norway

<sup>3</sup>Institute of Clinical Medicine, Faculty of Health Sciences,
UiT - The Arctic University of Norway, Tromsø, Norway

<sup>£</sup>Contact: Daniel Hammarström - daniel.hammarstrom@inn.no

<!-- README.md is generated from README.qmd. Please edit that file -->

<!---
[![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/trainome/seqwrappaper/master?urlpath=rstudio)
--->

## Repository structure

This repository contains all relevant code to reproduce the results
presented in the paper *“seqwrap: an R package for flexible iterative
fitting of high-dimensional data”* (in review). The paper presents the
[seqwrap](https://github.com/trainome/seqwrap) package, designed for the
analysis of omic-type (e.g., RNA-seq, proteomics) data using
user-defined regression models.

### Reproducibility

This repository is organized as a research compendium (Marwick et al.
2018), developed using the statistical programming language R. To work
with the compendium, you will need installed on your computer the [R
software](https://cloud.r-project.org/) itself and optionally [RStudio
Desktop](https://rstudio.com/products/rstudio/download/),
[Positron](https://positron.posit.co/download.html), or similar IDE.

Installing the compendium package will activate installation of
dependencies and make the data set used in the paper available as an R
object (`pillon_counts`).

``` r
pak::pkg_install("trainome/seqwrappaper")
```

The script `analysis/paper/make-docs.R` executes scripts in the required
order to reproduce results presented in the manuscript and supplementary
files. The script starts by restoring the package environment used to
produce the submitted manuscript using
[renv](https://rstudio.github.io/renv/index.html). Activating the
package environment used to produce the manuscript is done using
`renv::restore()` (see `analysis/paper/make-docs.R`) and allows for
exact reproduction of the analyses.

The **analysis** directory contains:

- `/analysis/paper`: Quarto source document for the manuscript
  (`paper.qmd`) and supplementary material (`supplement.qmd`). It also
  has a rendered versions, `paper.pdf` (and `supplement.pdf`), suitable
  for reading.
- `/analysis/data`: Data used in the analysis. All data in this folder
  is created by running scripts in the analysis folder. Note that the
  data used in the case study is part of the `seqwrappaper` package
  (`seqwrappaper::pillon_counts`).
- `/analysis/data/raw_data/`: Data derived from simulation experiments
  are stored here either after running simulations locally, or after
  downloading simulated data sets from Dataverse.no. See below for
  details.
- `/analysis/data/derived_data/`: Intermediate analyses and cache files
  used for reporting.
- `/analysis/figures`: Scripts for producing figures 2-4 and reproduce
  some of the results presented in the main text.

### Downloading simulated data and estimates

The analyses presented in the paper use data generated through
simulations and the analyses of those data. The results can be
reproduced using by running tha `make-docs.R` script with
`make_sim <- TRUE`, however, the runtime for this process is \> 24 h on
a personal computer. The data sets are available for download from
DataverseNO: https://doi.org/10.18710/I7U71O. The function
`download_dataverse()` downloads this data to the
`analysis/data/raw_data` folder.

The downloadable data is identical to that produced by the `make-docs.R`
script. Downloading the data enables direct reproduction of figures and
the manuscript.

`download_dataverse()` places a total of 260 files (+ a README file) in
the `raw_data` folder. Once downloaded, the structure of the `raw_data`
folder should be:

    -- raw_data/
       |-- estimates/
       |   |-- m1_estimates_1.RDS
       |   |-- …
       |   |-- m5_estimates_10.RDS
       |-- estimates2/
       |   |-- m1_estimates_1.RDS
       |   |-- …
       |   |-- m5_estimates_10.RDS
       |-- evaluations/
       |   |-- m1_evaluations_1.RDS
       |   |-- …
       |   |-- m5_evaluations_10.RDS
       |-- evaluations2/
       |   |-- m1_evaluations_1.RDS
       |   |-- …
       |   |-- m5_evaluations_10.RDS
       |-- simdata/
       |   |-- clean/
       |   |   |-- clean_dataset_1.RDS
       |   |   |-- …
       |   |   |-- clean_dataset_10.RDS
       |   |-- popeffect/
       |   |   |-- population_effects_1.RDS
       |   |   |-- …
       |   |   |-- population_effects_10.RDS
       |   |-- raw/ 
       |       |-- dataset_1.RDS
       |       |-- …
       |       |-- dataset_10.RDS
       |-- simdata2/
           |-- clean/
           |   |-- clean_dataset_1.RDS
           |   |-- …
           |   |-- clean_dataset_10.RDS
           |-- popeffect/
           |   |-- population_effects_1.RDS
           |   |-- …
           |   |-- population_effects_10.RDS
           |-- raw/ 
               |-- dataset_1.RDS
               |-- …
               |-- dataset_10.RDS

### Licenses

**Text and figures :**
[CC-BY-4.0](http://creativecommons.org/licenses/by/4.0/)

**Code :** See the [DESCRIPTION](DESCRIPTION) file

**Data :** [CC-0](http://creativecommons.org/publicdomain/zero/1.0/)
attribution requested in reuse

### Contributions

We welcome contributions from everyone. Before you get started, please
see our [contributor guidelines](CONTRIBUTING.md). Please note that this
project is released with a [Contributor Code of Conduct](CONDUCT.md). By
participating in this project you agree to abide by its terms.

## Session info

``` r
sessionInfo()
#> R version 4.6.0 (2026-04-24 ucrt)
#> Platform: x86_64-w64-mingw32/x64
#> Running under: Windows 11 x64 (build 26200)
#> 
#> Matrix products: default
#>   LAPACK version 3.12.1
#> 
#> locale:
#> [1] LC_COLLATE=Norwegian Bokmål_Norway.utf8 
#> [2] LC_CTYPE=Norwegian Bokmål_Norway.utf8   
#> [3] LC_MONETARY=Norwegian Bokmål_Norway.utf8
#> [4] LC_NUMERIC=C                            
#> [5] LC_TIME=Norwegian Bokmål_Norway.utf8    
#> 
#> time zone: Europe/Oslo
#> tzcode source: internal
#> 
#> attached base packages:
#> [1] stats4    parallel  stats     graphics  grDevices utils     datasets 
#> [8] methods   base     
#> 
#> other attached packages:
#>  [1] MASS_7.3-65                 tidyselect_1.2.1           
#>  [3] jsonlite_2.0.0              broom.mixed_0.2.9.7        
#>  [5] lmerSeq_0.1.7               glmmSeq_0.5.7              
#>  [7] gt_1.3.0                    knitr_1.51                 
#>  [9] rmarkdown_2.31              renv_1.2.3                 
#> [11] quarto_1.5.1                lmerTest_3.2-1             
#> [13] glmmTMB_1.1.14              edgeR_4.10.0               
#> [15] limma_3.68.2                DHARMa_0.4.7               
#> [17] DESeq2_1.52.0               SummarizedExperiment_1.42.0
#> [19] MatrixGenerics_1.24.0       matrixStats_1.5.0          
#> [21] GenomicRanges_1.64.0        Seqinfo_1.2.0              
#> [23] org.Hs.eg.db_3.23.1         AnnotationDbi_1.74.0       
#> [25] IRanges_2.46.0              S4Vectors_0.50.1           
#> [27] Biobase_2.72.0              BiocGenerics_0.58.1        
#> [29] generics_0.1.4              marginaleffects_0.32.0     
#> [31] lme4_2.0-1                  Matrix_1.7-5               
#> [33] ComplexUpset_1.3.3          clusterProfiler_4.20.0     
#> [35] lubridate_1.9.5             forcats_1.0.1              
#> [37] stringr_1.6.0               dplyr_1.2.1                
#> [39] purrr_1.2.2                 readr_2.2.0                
#> [41] tidyr_1.3.2                 tibble_3.3.1               
#> [43] ggplot2_4.0.3               tidyverse_2.0.0            
#> [45] seqwrappaper_0.0.0.9000     seqwrap_0.7.0              
#> [47] here_1.0.2                  ggtext_0.1.2               
#> [49] cowplot_1.2.0              
#> 
#> loaded via a namespace (and not attached):
#>   [1] fs_2.1.0                enrichplot_1.32.0       httr_1.4.8             
#>   [4] RColorBrewer_1.1-3      numDeriv_2016.8-1.1     tools_4.6.0            
#>   [7] backports_1.5.1         R6_2.6.1                lazyeval_0.2.3         
#>  [10] mgcv_1.9-4              withr_3.0.2             cli_3.6.6              
#>  [13] scatterpie_0.2.6        sandwich_3.1-1          mvtnorm_1.3-7          
#>  [16] S7_0.2.2                pbapply_1.7-4           systemfonts_1.3.2      
#>  [19] yulab.utils_0.2.4       gson_0.1.0              DOSE_4.6.0             
#>  [22] parallelly_1.47.0       mcprogress_0.1.1        rstudioapi_0.18.0      
#>  [25] RSQLite_3.52.0          gridGraphics_0.5-1      gtools_3.9.5           
#>  [28] car_3.1-5               GO.db_3.23.1            abind_1.4-8            
#>  [31] lifecycle_1.0.5         multcomp_1.4-30         yaml_2.3.12            
#>  [34] carData_3.0-6           qvalue_2.44.0           SparseArray_1.12.2     
#>  [37] grid_4.6.0              blob_1.3.0              crayon_1.5.3           
#>  [40] ggtangle_0.1.2          lattice_0.22-9          KEGGREST_1.52.0        
#>  [43] pillar_1.11.1           boot_1.3-32             estimability_1.5.1     
#>  [46] future.apply_1.20.2     codetools_0.2-20        glue_1.8.1             
#>  [49] ggiraph_0.9.6           ggfun_0.2.0             fontLiberation_0.1.0   
#>  [52] data.table_1.18.4       vctrs_0.7.3             png_0.1-9              
#>  [55] treeio_1.36.1           Rdpack_2.6.6            gtable_0.3.6           
#>  [58] cachem_1.1.0            xfun_0.57               rbibutils_2.4.1        
#>  [61] S4Arrays_1.12.0         coda_0.19-4.1           reformulas_0.4.4       
#>  [64] survival_3.8-6          aisdk_1.1.0             lava_1.9.1             
#>  [67] statmod_1.5.2           TH.data_1.1-5           nlme_3.1-169           
#>  [70] ggtree_4.2.0            bit64_4.8.2             fontquiver_0.2.1       
#>  [73] rprojroot_2.1.1         TMB_1.9.21              otel_0.2.0             
#>  [76] colorspace_2.1-2        DBI_1.3.0               processx_3.9.0         
#>  [79] emmeans_2.0.3           bit_4.6.0               compiler_4.6.0         
#>  [82] httr2_1.2.2             xml2_1.5.2              fontBitstreamVera_0.1.1
#>  [85] DelayedArray_0.38.1     plotly_4.12.0           scales_1.4.0           
#>  [88] callr_3.7.6             rappdirs_0.3.4          digest_0.6.39          
#>  [91] lavaSearch2_2.0.3       minqa_1.2.8             XVector_0.52.0         
#>  [94] htmltools_0.5.9         pkgconfig_2.0.3         fastmap_1.2.0          
#>  [97] rlang_1.2.0             htmlwidgets_1.6.4       farver_2.1.2           
#> [100] zoo_1.8-15              BiocParallel_1.46.0     GOSemSim_2.38.0        
#> [103] magrittr_2.0.5          Formula_1.2-5           ggplotify_0.1.3        
#> [106] patchwork_1.3.2         Rcpp_1.1.1-1.1          ape_5.8-1              
#> [109] ggnewscale_0.5.2        gdtools_0.5.0           furrr_0.4.0            
#> [112] stringi_1.8.7           plyr_1.8.9              listenv_0.10.1         
#> [115] ggrepel_0.9.8           Biostrings_2.80.0       splines_4.6.0          
#> [118] gridtext_0.1.6          hms_1.1.4               locfit_1.5-9.12        
#> [121] igraph_2.3.1            ggpubr_0.6.3            ggsignif_0.6.4         
#> [124] enrichit_0.1.4          reshape2_1.4.5          evaluate_1.0.5         
#> [127] nloptr_2.2.1            tzdb_0.5.0              tweenr_2.0.3           
#> [130] polyclip_1.10-7         future_1.70.0           ggforce_0.5.0          
#> [133] broom_1.0.13            xtable_1.8-8            tidytree_0.4.7         
#> [136] tidydr_0.0.6            rstatix_0.7.3           later_1.4.8            
#> [139] viridisLite_0.4.3       aplot_0.2.9             memoise_2.0.1          
#> [142] cluster_2.1.8.2         timechange_0.4.0        globals_0.19.1
```

# References

<div id="refs" class="references csl-bib-body hanging-indent">

<div id="ref-marwick2018" class="csl-entry">

Marwick, Ben, Carl Boettiger, and Lincoln Mullen. 2018. *Packaging Data
Analytical Work Reproducibly Using R (and Friends)*. PeerJ Preprints.
<https://doi.org/10.7287/peerj.preprints.3192v2>.

</div>

</div>
