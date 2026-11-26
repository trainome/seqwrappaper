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
fitting of high-dimensional data”* (BMC Biology). The paper presents the
[seqwrap](https://github.com/trainome/seqwrap) package, designed for the
analysis of omic-type (e.g., RNA-seq, proteomics) data using
user-defined regression models.

### Reproducibility

This repository is organized as a research compendium (Marwick et al.
2018), developed using the statistical programming language R. To work
with the compendium, you will need installed on your computer the [R
software (\>4.6)](https://cloud.r-project.org/) itself and optionally
[RStudio Desktop](https://rstudio.com/products/rstudio/download/),
[Positron](https://positron.posit.co/download.html), or similar IDE.

To set up the environment, clone this repository, open the project
(e.g. via `seqwrappaper.Rproj`), and run:

``` r
renv::restore()    # install pinned dependencies from renv.lock
renv::install(".") # install the compendium package itself
```

`renv::restore()` recreates the package environment used to produce the
manuscript from [renv](https://rstudio.github.io/renv/index.html)’s
lockfile, ensuring exact dependency versions. `lmerSeq` is not on CRAN
and is included here as a tarball under `inst/`; the lockfile records it
as a local source, so the restore step installs it from the bundled
tarball. `renv::install(".")` then installs the compendium package from
local source, which makes the data set used in the paper available as an
R object (`pillon_counts`).

The script `analysis/paper/make-docs.R` executes these steps and
analysis scripts in the required order to reproduce results presented in
the manuscript and supplementary files.

The **analysis** directory contains:

- `/analysis/paper`: Quarto source document for the manuscript
  (`paper.qmd`; the originally submitted version is kept in
  `analysis/tracked-archive/paper.qmd`) and supplementary material
  (`supplement.qmd`). It also has a rendered versions, `paper.docx` (and
  `supplement.pdf`), suitable for reading.
- `/analysis/data`: Data used in the analysis. All data in this folder
  is created by running scripts in the analysis folder. Note that the
  data used in the case study is part of the `seqwrappaper` package
  (`seqwrappaper::pillon_counts`).
- `/analysis/data/raw_data/`: Data derived from simulation experiments
  are stored here either after running simulations locally, or after
  downloading simulated data sets from Dataverse.no (or part of the
  froozen repository). See below for details. The raw methylation arrays
  (GEO accession GSE114763) used in the DNA methylation case study are
  downloaded here by `analysis/R/methylation-case-study-dataprep.R`.
- `/analysis/data/derived_data/`: Intermediate analyses and cache files
  used for reporting, including the methylation case-study results
  (`permutation_v4/`, `full_v3/`, `timing_v1/`).
- `/analysis/figures`: Scripts for producing figures 2-5 and reproduce
  some of the results presented in the main text.
- `/analysis/archive`: Superseded scripts and results that are not used
  by the revised manuscript (not tracked by git).

### Downloading simulated data and estimates

The analyses presented in the paper use data generated through
simulations and the analyses of those data. The results can be
reproduced using by running the `make-docs.R` script with
`make_sim <- TRUE`, however, the runtime for this process is \> 24 h on
a personal computer. The data sets are available for download from
DataverseNO: https://doi.org/10.18710/I7U71O. The function
`download_dataverse()` downloads this data to the
`analysis/data/raw_data` folder.

The downloadable data is identical to that produced by the `make-docs.R`
script. Downloading the data enables direct reproduction of figures and
the manuscript. Run the `download_dataverse()` function as part of
`make-docs.R` for accurate reproduction.

`download_dataverse()` places a total of 625 files (+ a README file) in
the `raw_data` and `derived_data` folders. Once downloaded, the
structure of the `raw_data` folder should be:

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

The methylation case-study results (365 files) are placed in the
`derived_data` folder. When the simulations and the methylation case
study are downloaded rather than re-run, the structure of the
`derived_data` folder should be:

    -- derived_data/
       |-- seaborne-gset-quantile.RDS
       |-- seaborne-metadata.RDS
       |-- full_v2/
       |   |-- timing.RDS
       |-- full_v3/
       |   |-- beta_reml.RDS
       |   |-- beta_reml-meta.RDS
       |   |-- m_reml.RDS
       |   |-- m_reml-meta.RDS
       |   |-- timing.RDS
       |-- permutation_v4/
       |   |-- perm_0001.RDS
       |   |-- …
       |   |-- perm_0200.RDS
       |-- timing_v1/
           |-- cell-*.RDS (152 files)
           |-- design.RDS
           |-- draws.RDS
           |-- timing-cells.RDS
           |-- timing-scaling.RDS
           |-- warmup.RDS

Other files in `derived_data` (e.g., `m1_results.RDS`–`m5_results.RDS`,
`gsea_results.RDS`) are not downloaded; they are cache files created
when `make-docs.R` runs the analysis scripts.

### Licenses

**Text and figures :**
[CC-BY-4.0](http://creativecommons.org/licenses/by/4.0/)

**Code :** [MIT](LICENSE.md), see also the [DESCRIPTION](DESCRIPTION)
file.

The exception is `inst/lmerSeq_0.1.7.tar.gz`. It is an unmodified copy
of the lmerSeq package (Vestal et al. 2022), redistributed under its own
license
([GPL-2](https://www.gnu.org/licenses/old-licenses/gpl-2.0.html)), not
under the MIT license of this compendium. We include it only because the
package is not available on CRAN. For license terms and authorship, see
the DESCRIPTION file in the tarball.

**Data :** The simulated data sets, model estimates and methylation
case-study results produced in this project (`analysis/data/raw_data/`
and `analysis/data/derived_data/`, also available from DataverseNO:
https://doi.org/10.18710/I7U71O) are released under
[CC-0](http://creativecommons.org/publicdomain/zero/1.0/). We ask that
you attribute them when you reuse them.

The analyses also use two third-party data sets, which are not covered
by the CC-0 dedication. If you reuse them, please cite the original
publications and data sets:

- **Pillon et al. (2022)**: RNA-seq counts from skeletal muscle, bundled
  with this package as `seqwrappaper::pillon_counts`, from GEO accession
  [GSE202295](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE202295)
  (<span class="nocase">Pillon et al.</span> 2022; Zierath et al. 2022).
- **Seaborne et al. (2018)**: Illumina EPIC methylation arrays used in
  the DNA methylation case study, from GEO accession
  [GSE114763](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE114763)
  (Seaborne et al. 2018; Seaborne and Sharples 2018). The raw IDAT files
  are not redistributed here.
  `analysis/R/methylation-case-study-dataprep.R` downloads them from
  GEO.

## Session info

``` r
sessionInfo()
#> R version 4.6.0 (2026-04-24 ucrt)
#> Platform: x86_64-w64-mingw32/x64
#> Running under: Windows 11 x64 (build 26300)
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
#>  [1] grid      stats4    parallel  stats     graphics  grDevices datasets 
#>  [8] utils     methods   base     
#> 
#> other attached packages:
#>  [1] MASS_7.3-65                                        
#>  [2] IlluminaHumanMethylationEPICmanifest_0.3.0         
#>  [3] IlluminaHumanMethylationEPICanno.ilm10b4.hg19_0.6.0
#>  [4] desc_1.4.3                                         
#>  [5] ashr_2.2-63                                        
#>  [6] usethis_3.2.1                                      
#>  [7] tidyselect_1.2.1                                   
#>  [8] jsonlite_2.0.0                                     
#>  [9] broom.mixed_0.2.9.7                                
#> [10] withr_3.0.2                                        
#> [11] pbapply_1.7-4                                      
#> [12] R.utils_2.13.0                                     
#> [13] R.oo_1.27.1                                        
#> [14] R.methodsS3_1.8.2                                  
#> [15] curl_7.1.0                                         
#> [16] GEOquery_2.80.0                                    
#> [17] lmerSeq_0.1.7                                      
#> [18] glmmSeq_0.5.7                                      
#> [19] fdrtool_1.2.18                                     
#> [20] rmarkdown_2.31                                     
#> [21] knitr_1.51                                         
#> [22] gt_1.3.0                                           
#> [23] renv_1.2.3                                         
#> [24] quarto_1.5.1                                       
#> [25] lmerTest_3.2-1                                     
#> [26] glmmTMB_1.1.14                                     
#> [27] edgeR_4.10.0                                       
#> [28] limma_3.68.4                                       
#> [29] DHARMa_0.4.7                                       
#> [30] DESeq2_1.52.0                                      
#> [31] scales_1.4.0                                       
#> [32] minfi_1.58.0                                       
#> [33] bumphunter_1.54.0                                  
#> [34] locfit_1.5-9.12                                    
#> [35] iterators_1.0.14                                   
#> [36] foreach_1.5.2                                      
#> [37] Biostrings_2.80.0                                  
#> [38] XVector_0.52.0                                     
#> [39] SummarizedExperiment_1.42.0                        
#> [40] MatrixGenerics_1.24.0                              
#> [41] matrixStats_1.5.0                                  
#> [42] GenomicRanges_1.64.0                               
#> [43] Seqinfo_1.2.0                                      
#> [44] maxprobes_0.0.2                                    
#> [45] ggh4x_0.3.1                                        
#> [46] org.Hs.eg.db_3.23.1                                
#> [47] AnnotationDbi_1.74.0                               
#> [48] IRanges_2.46.0                                     
#> [49] S4Vectors_0.50.1                                   
#> [50] Biobase_2.72.0                                     
#> [51] BiocGenerics_0.58.1                                
#> [52] generics_0.1.4                                     
#> [53] marginaleffects_0.32.0                             
#> [54] lme4_2.0-1                                         
#> [55] Matrix_1.7-5                                       
#> [56] ggupset_0.4.1                                      
#> [57] clusterProfiler_4.20.0                             
#> [58] lubridate_1.9.5                                    
#> [59] forcats_1.0.1                                      
#> [60] stringr_1.6.0                                      
#> [61] purrr_1.2.2                                        
#> [62] readr_2.2.0                                        
#> [63] tidyr_1.3.2                                        
#> [64] tibble_3.3.1                                       
#> [65] ggplot2_4.0.3                                      
#> [66] tidyverse_2.0.0                                    
#> [67] seqwrappaper_0.0.2                                 
#> [68] seqwrap_0.8.1                                      
#> [69] here_1.0.2                                         
#> [70] ggtext_0.1.2                                       
#> [71] dplyr_1.2.1                                        
#> [72] cowplot_1.2.0                                      
#> 
#> loaded via a namespace (and not attached):
#>   [1] HDF5Array_1.40.0          TH.data_1.1-5            
#>   [3] vctrs_0.7.3               ggtangle_0.1.2           
#>   [5] digest_0.6.39             png_0.1-9                
#>   [7] mixsqp_0.3-54             ggrepel_0.9.8            
#>   [9] parallelly_1.47.0         fontLiberation_0.1.0     
#>  [11] SQUAREM_2026.1            reshape_0.8.10           
#>  [13] reshape2_1.4.5            qvalue_2.44.0            
#>  [15] xfun_0.57                 ggfun_0.2.0              
#>  [17] ggpubr_0.6.3              survival_3.8-6           
#>  [19] doRNG_1.8.6.3             memoise_2.0.1            
#>  [21] emmeans_2.0.3             gson_0.1.0               
#>  [23] systemfonts_1.3.2         gtools_3.9.5             
#>  [25] tidytree_0.4.7            zoo_1.8-15               
#>  [27] Formula_1.2-5             KEGGREST_1.52.0          
#>  [29] otel_0.2.0                httr_1.4.8               
#>  [31] rstatix_0.7.3             restfulr_0.0.17          
#>  [33] globals_0.19.1            rhdf5filters_1.24.1      
#>  [35] rhdf5_2.56.0              rstudioapi_0.18.0        
#>  [37] DOSE_4.6.0                processx_3.9.0           
#>  [39] h5mread_1.4.0             polyclip_1.10-7          
#>  [41] quadprog_1.5-8            SparseArray_1.12.2       
#>  [43] xtable_1.8-8              evaluate_1.0.5           
#>  [45] S4Arrays_1.12.0           preprocessCore_1.74.0    
#>  [47] hms_1.1.4                 irlba_2.3.7              
#>  [49] magrittr_2.0.5            later_1.4.8              
#>  [51] ggtree_4.2.0              lattice_0.22-9           
#>  [53] future.apply_1.20.2       genefilter_1.94.0        
#>  [55] XML_3.99-0.23             pillar_1.11.1            
#>  [57] nlme_3.1-169              compiler_4.6.0           
#>  [59] stringi_1.8.7             minqa_1.2.8              
#>  [61] GenomicAlignments_1.48.0  plyr_1.8.9               
#>  [63] crayon_1.5.3              abind_1.4-8              
#>  [65] BiocIO_1.22.0             truncnorm_1.0-9          
#>  [67] gridGraphics_0.5-1        bit_4.6.0                
#>  [69] sandwich_3.1-1            codetools_0.2-20         
#>  [71] multcomp_1.4-30           openssl_2.4.1            
#>  [73] plotly_4.12.0             multtest_2.68.0          
#>  [75] splines_4.6.0             Rcpp_1.1.1-1.1           
#>  [77] tidydr_0.0.6              sparseMatrixStats_1.24.0 
#>  [79] gridtext_0.1.6            blob_1.3.0               
#>  [81] fs_2.1.0                  listenv_0.10.1           
#>  [83] DelayedMatrixStats_1.34.0 Rdpack_2.6.6             
#>  [85] ggsignif_0.6.4            ggplotify_0.1.3          
#>  [87] estimability_1.5.1        callr_3.7.6              
#>  [89] statmod_1.5.2             tzdb_0.5.0               
#>  [91] tweenr_2.0.3              pkgconfig_2.0.3          
#>  [93] tools_4.6.0               cachem_1.1.0             
#>  [95] rbibutils_2.4.1           cigarillo_1.2.1          
#>  [97] RSQLite_3.52.0            viridisLite_0.4.3        
#>  [99] DBI_1.3.0                 numDeriv_2016.8-1.1      
#> [101] fastmap_1.2.0             Rsamtools_2.28.0         
#> [103] broom_1.0.13              patchwork_1.3.2          
#> [105] coda_0.19-4.1             BiocManager_1.30.27      
#> [107] carData_3.0-6             scrime_1.3.7             
#> [109] farver_2.1.2              reformulas_0.4.4         
#> [111] scatterpie_0.2.6          mgcv_1.9-4               
#> [113] yaml_2.3.12               rtracklayer_1.72.0       
#> [115] illuminaio_0.54.0         cli_3.6.6                
#> [117] siggenes_1.86.0           lifecycle_1.0.5          
#> [119] askpass_1.2.1             mvtnorm_1.3-7            
#> [121] lava_1.9.1                backports_1.5.1          
#> [123] BiocParallel_1.46.0       annotate_1.90.0          
#> [125] timechange_0.4.0          gtable_0.3.6             
#> [127] rjson_0.2.23              ape_5.8-1                
#> [129] enrichit_0.1.4            bitops_1.0-9             
#> [131] bit64_4.8.2               yulab.utils_0.2.4        
#> [133] base64_2.0.2              aisdk_1.1.0              
#> [135] GOSemSim_2.38.0           lazyeval_0.2.3           
#> [137] htmltools_0.5.9           enrichplot_1.32.0        
#> [139] GO.db_3.23.1              rappdirs_0.3.4           
#> [141] glue_1.8.1                httr2_1.2.2              
#> [143] gdtools_0.5.0             RCurl_1.98-1.19          
#> [145] rprojroot_2.1.1           treeio_1.36.1            
#> [147] mclust_6.1.3              boot_1.3-32              
#> [149] invgamma_1.2              igraph_2.3.1             
#> [151] TMB_1.9.21                R6_2.6.1                 
#> [153] ggiraph_0.9.6             GenomicFeatures_1.64.0   
#> [155] cluster_2.1.8.2           rngtools_1.5.2           
#> [157] Rhdf5lib_2.0.0            beanplot_1.3.1           
#> [159] aplot_0.2.9               nloptr_2.2.1             
#> [161] mcprogress_0.1.1          DelayedArray_0.38.1      
#> [163] ggforce_0.5.0             xml2_1.5.2               
#> [165] fontBitstreamVera_0.1.1   car_3.1-5                
#> [167] future_1.70.0             S7_0.2.2                 
#> [169] furrr_0.4.0               nor1mix_1.3-3            
#> [171] fontquiver_0.2.1          data.table_1.18.4        
#> [173] htmlwidgets_1.6.4         RColorBrewer_1.1-3       
#> [175] rlang_1.3.0               rentrez_1.2.4            
#> [177] lavaSearch2_2.0.3         ggnewscale_0.5.2
```

# References

<div id="refs" class="references csl-bib-body hanging-indent">

<div id="ref-marwick2018" class="csl-entry">

Marwick, Ben, Carl Boettiger, and Lincoln Mullen. 2018. *Packaging Data
Analytical Work Reproducibly Using R (and Friends)*. PeerJ Preprints.
<https://doi.org/10.7287/peerj.preprints.3192v2>.

</div>

<div id="ref-pillon2022" class="csl-entry">

<span class="nocase">Pillon, Nicolas J., Jonathon A. B. Smith, Petter S.
Alm, et al.</span> 2022. “Distinctive Exercise-Induced Inflammatory
Response and Exerkine Induction in Skeletal Muscle of People with Type 2
Diabetes.” *Science Advances* 8 (36): eabo3192.
<https://doi.org/10.1126/sciadv.abo3192>.

</div>

<div id="ref-GSE114763" class="csl-entry">

Seaborne, R. A., and A. P. Sharples. 2018. “Human Muscle Posses
Epigenetic Memory.” No. GSE114763. Gene Expression Omnibus.
<https://identifiers.org/geo:GSE114763>.

</div>

<div id="ref-seaborne2018" class="csl-entry">

Seaborne, Robert A., Juliette Strauss, Matthew Cocks, et al. 2018.
“Human Skeletal Muscle Possesses an Epigenetic Memory of Hypertrophy.”
*Scientific Reports* 8 (1): 1898.
<https://doi.org/10.1038/s41598-018-20287-3>.

</div>

<div id="ref-vestal_lmerseq_2022" class="csl-entry">

Vestal, Brian E., Elizabeth Wynn, and Camille M. Moore. 2022.
“<span class="nocase">lmerSeq</span>: An r Package for Analyzing
Transformed RNA-Seq Data with Linear Mixed Effects Models.” *BMC
Bioinformatics* 23 (1): 489.
<https://doi.org/10.1186/s12859-022-05019-9>.

</div>

<div id="ref-GSE202295" class="csl-entry">

Zierath, J. R., A. Krook, and N. J. Pillon. 2022. “Distinctive
Exercise-Induced Inflammatory Response and Exerkine Induction in
Skeletal Muscle of People with Type 2 Diabetes.” No. GSE202295. Gene
Expression Omnibus. <https://identifiers.org/geo:GSE202295>.

</div>

</div>
