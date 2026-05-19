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

<!-- README.md is generated from README.Rmd. Please edit that file -->

<!---
[![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/trainome/seqwrappaper/master?urlpath=rstudio)
--->

This repository contains all relevant code to reproduce the results
presented in the paper *“seqwrap: an R package for flexible iterative
fitting of high-dimensional data”* (in review). The paper presents the
[seqwrap](https://github.com/trainome/seqwrap) package, designed for the
analysis of omic-type (e.g., RNA-seq, proteomics) data using
user-defined regression models.

## Contents repository structure

### Reproducibility

This repository is organized as a research compendium (Marwick et al.
2018), developed using the statistical programming language R. To work
with the compendium, you will need installed on your computer the [R
software](https://cloud.r-project.org/) itself and optionally [RStudio
Desktop](https://rstudio.com/products/rstudio/download/).

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

<div id="refs" class="references csl-bib-body hanging-indent">

<div id="ref-marwick2018" class="csl-entry">

Marwick, Ben, Carl Boettiger, and Lincoln Mullen. 2018. *Packaging Data
Analytical Work Reproducibly Using R (and Friends)*. PeerJ Preprints.
<https://doi.org/10.7287/peerj.preprints.3192v2>.

</div>

</div>
