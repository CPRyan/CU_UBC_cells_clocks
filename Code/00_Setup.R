##############################################################################
# Load packages
##############################################################################

library(tidyverse)
library(sjlabelled)
library(readr)
library(patchwork)
library(broom)

##############################################################################
# Make an output folder for the Data
##############################################################################

xfun::dir_create("Cells_Clocks_Output/Figures")
xfun::dir_create("Cells_Clocks_Output/Tables")


##############################################################################
# Load your data
##############################################################################

cell_clock_df = read_csv(here::here("Output/Data", "clhns_ics_complete_df.csv"))
# Load your dataset as "cell_clock_df"
# Rows should be individuals, columns should be clocks, cells, ids, and your continuous and categorical/factor covariates.

##############################################################################
# Name your study, id and variables
##############################################################################

# Name your study 
study <-"CLHNS_ICs"
# e.g. CLHNS, Framingham, WHI, etc.

# Pick your participant ID variable
id <-"uncchdid"

# Pick your categorical variables
categorical_variables <-c("Female", "currently_pregnant")

# Pick your continous variables
continuous_variables <-c("Age")

# Pick your key covariates. This is anything from your study that you think might affect the outcomes that ARE NOT in your categorical variables. 
control_covariates <-c("Sample_Plate", "Array")


##############################################################################
# Create Study Summary Table
##############################################################################


##############################################################################
# Cell Clock Summary and Boxplots
# Summary and Boxplots for both CELLS and CLOCKS for WHOLE SAMPLE and as STRATIFIED by levels in each of "categorical_variables"
# For boxplots, categorical variable can only have 18 colored categories. The remaining categories will not be colored.
##############################################################################

source("Code/01_Cell_Clock_Summary_Boxplots.R")

##############################################################################
# Run the Univariate Cell Clock Associations
##############################################################################

# For WHOLE SAMPLE
source("Code/02A_Univariate_Cell_Clock_Associations.R")

# STRATIFIED by levels in each of "categorical_variables"
source("Code/02B_Univariate_Cell_Clock_Associations_Stratified.R")

##############################################################################
# Run the Cell Clock Delta R2
##############################################################################

source("Code/03_Cell_Clock_Delta_R2.R")

##############################################################################
# Run the Exposure ~ Cell OR Clock associations
##############################################################################

source("Code/04_Exposure_Cell_Clock_Associations.R")

##############################################################################
# Run the Exposure ~ Clock associations, adjusted for cells or not
##############################################################################

source("Code/05_Exposure_Clock_Associations_Adj_Cells.R")

##############################################################################
# Done
##############################################################################
