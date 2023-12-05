# Cells and Clocks Analysis

## Introduction

Welcome! This document supports the accompanying pipeline for our collaboration looking at the associations between epigenetic clocks and immune cell composition across exposures and contexts. It guides users through the data and computational requirements to run the pipeline, provides instructions for running the pipeline, and describes the outputs generated. The pipeline allows us to harmonize data products across studies without requiring our collaborators to share raw data. If you would rather temporarily share your data and have us calculate the outputs for your, please contact Calen Ryan (cpr2139\@cumc.columbia.edu) or Dan Belsky (db3275\@cumc.columbia.edu).

## Requirements

### Computational Requirements

This pipeline was constructed in R version 4.2.2 -- "Innocent and Trusting". All versions 2022-10-31 or later should be compatible with the packages used.

An effort was made to minimize the use of unusual or uncommon packages. Nevertheless, the pipeline relies on certain packages that must be installed prior to execution.

-   `tidyverse`: Needed for `dplyr`, `tidyr`, `ggplot2`, `readr` and `tibble`.
-   `sjlabelled`: Used for easily reclassifying variables
-   `patchwork`: Used for patching together several figures easily
-   `broom`: used for cleaning up model outputs and making them 'tidy'
-   `xfun`: used for creating directories for output
-   `here`: used to create relative (vs. absolute) file paths for data io.

Please ensure these packages (and all dependencies) are installed prior to running the pipeline.

### Data Requirements

The data should be a tibble (preferable) or dataframe must include the following columns (at minimum):

1.  Age: Must be called `Age` and designated in years. This matches the input required for epigenetic clock calculators and should be standard in your data.
2.  Sex: Must be called `Female` and designated as `0` (for males) or `1` (for females). This matches the input required for epigenetic clock calculators and should be standard in your data.
3.  ID: Some individual ID variable. The name can be selected by you in the `00_Setup.R` file. See below.
4.  Bioinformatically estimated cells composition: Immune cell composition based on [Salas et al. 2022](https://www.nature.com/articles/s41467-021-27864-7).
    -   Must include: `Bas`, `Bmem`, `Bnv`, `CD4mem`, `CD4nv`, `CD8mem`, `CD8nv`, `Eos`, `Mono`, `NK`, `Treg`, `Neu`
    -   Note: To get the reference dataset required for the Salas extended cell types, you will need to sign a [licensing agreement with Dartmouth University](https://github.com/immunomethylomics/FlowSorted.BloodExtended.EPIC/blob/main/SoftwareLicense.FlowSorted.BloodExtended.EPIC%20to%20sign.pdf). If you do not have the reference dataset, the cell deconvolution method will still work, but will not be accurate.
5.  Epigenetic Clocks
    -   Must include: `PCHorvath1`, `PCPhenoAge`, `PCGrimAge`, and `DunedinPACE`

    -   Pipeline is not currently setup for other clocks, but if this is important to you please discuss with Calen or Dan.

Additionally, you will have the opportunity to include additional variables that may matter to your dataset:

6.  Categorical Variables: These will be provided by the user in the `00_Setup.R` file and will be called `categorical_variables`. Should include `Female`, as well as other interesting categories where immune cell composition or epigenetic clocks may be different by groups (e.g. health status, menopausal status, treatment group, etc.)
7.  Continuous Variables: These will be provided by the user in the `00_Setup.R` file and will be called called `continuous_variables`. Should include `Age`, as well as well as other interesting categories where immune cell composition or epigenetic clocks may differ (e.g. BMI, time-since-surgery, etc.).
8.  Control Variables: These will be provided by the user in the `00_Setup.R` file and will be called `control_covariates`. These will include technical variation you may with to control for in your output, such as plate, chip, row, batch, etc.

## Procedure

Technically, the only file you will need to open and run is the `00_Setup.R` file. Individual pipeline steps and output will be described in detail after guiding the user through `00_Setup.R`.

### `00_Setup.R`

The file follows the following procedure:

-   Loads packages
-   Creates `Figures` and `Tables` folders for output.
-   Loads data and allows user assigned variables (below).
-   Runs individual source files to produce data output.

##### Several steps require your input:

-   Reading in your dataset. You will need to load your dataset and name it `cell_clock_df`. This dataset should include all of the variables that you will be using, with each row corresponding to an individual, and columns corresponding to clocks, cells, ids, and your continuous and categorical/factor covariates. See \@ref(data-requirements) for more information.
-   Name your study. Assign your study name to the object `study`. This will be used to dynamically name the file outputs.
-   Name your id variable: Assign your id variable to the object `id`
-   Provide names of `categorical_variables`. These will be used for stratifying outputs.
-   Provide names of `continuous_variables`. These will be used for analyses of continuous associations.
-   Provide names of `control_covariates`. These will be used in model building and stratifying outputs.

### 01_Cell_Clock_Summary_Boxplots.R

Creates a series of boxplots and numerical summaries of those boxplots for each clock and each cell type. These are run on the study as a whole (Null) and stratified on levels of `categorical_variables`. At present, code will not plot categorical variables with \>18 groups.

### 02A_Univariate_Cell_Clock_Associations.R

Takes the residuals of each clock and each cell on `Age`. Runs a series of univariate correlations between each clock and each cell, one at a time.

### 02B_Univariate_Cell_Clock_Associations_Stratified.R

Similar to `02A_Univariate_Cell_Clock_Associations.R`, takes the residuals of each clock and each cell on `Age`. Runs a series of univariate correlations between each clock and each cell, one at a time. This time correlations are run for each level of each category in `categorical_variables` (i.e. correlations are stratified by group in categorical variables).

### 03_Cell_Clock_Delta_R2.R

For each clock, regresses epigenetic clock age (residualized for age) on `Age`, and `control_covariates` without all cells, and with all cells. Compares the R2 between the two. Carried out for the dataset as a whole, and stratified by each group with in each `categorical_variables`.

### 04_Exposure_Cell_Clock_Associations.R

Calculates the estimate and confidence intervals for the effect of `categorical_variable` on all clocks and all cells (residualized for age), accounting for `control_covariates`.

### 05_Exposure_Clock_Associations_Stratified.R

Calculates the estimate and confidence intervals for the effect of `categorical_variable` on each epigenetic clock output, with and without including cells.

Currently only works for 2 level categorical variables.
