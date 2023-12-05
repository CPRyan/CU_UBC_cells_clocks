# Delta R2 for each clock with and without cells
# Basic model:
# Regressions on Clock OR Cell
#  Create a list of all clocks and cells columns
#  Run regressions of each exposure on each cell and clock
#  Include covariates - should I include Age even if I've included Age residualized Clock/Cells?


# Create a list of column names you want to process
# # Cell columns
cell_columns <- c("Bas", "Bmem", "Bnv", "CD4mem", "CD4nv", "CD8mem", "CD8nv", "Eos", "Mono",  "NK", "Treg", "Neu")
# # Clock columns
clock_columns <- c("PCHorvath1", "PCPhenoAge", "PCGrimAge", "DunedinPACE")

all_columns <-c(clock_columns, cell_columns)

# Create an empty data frame to store the results
results_df <- data.frame(Cell_or_Clock = character(),
                         Exposure = character(),
                         Beta = numeric(),
                         Lower_CI = numeric(),
                         Upper_CI = numeric(),
                         stringsAsFactors = FALSE)

#####################################################################################
# Basic model not stratified. 
#####################################################################################

# Iterate through categorical variables
for (categorical_var in categorical_variables) {
  cell_clock_df_resids_nona <-cell_clock_df %>% filter(!is.na(!!sym(categorical_var)))
  
  # Iterate through clock_columns
  for (cell_clock_column in paste0(all_columns, "_resids")) {
    
    # Fit a linear regression model
    model <- lm(paste0(cell_clock_column, " ~ ", "Age", " + ", paste(control_covariates, collapse = " + "), "+", categorical_var), data = cell_clock_df_resids_nona)
    
    # Extract coefficients and confidence intervals using broom
    tidy_model <- tidy(model)
    
    # Filter the coefficients for the cell variables
    exposure_coefficients <- tidy_model %>% filter(grepl(categorical_var, term))
    
    # Calculate the standard error
    se <- exposure_coefficients$std.error
    
    # Calculate the confidence intervals
    lower_ci <- exposure_coefficients$estimate - 1.96 * se
    upper_ci <- exposure_coefficients$estimate + 1.96 * se
    
    # Add the results to the results data frame
    results_df <- bind_rows(results_df, data.frame(Cell_or_Clock = cell_clock_column, 
                                                   Exposure = exposure_coefficients$term,
                                                   Beta = exposure_coefficients$estimate,
                                                   Lower_CI = lower_ci,
                                                   Upper_CI = upper_ci)) %>% mutate(across(where(is.numeric), round, 3))
  }
}
  

# Generate the CSV filename dynamically
exposure_cell_or_clock_assoc <- paste0("Cells_Clocks_Output/Tables/", study, "_exposure_cell_or_clock_associations.csv")

# Save the summary data to CSV
write_csv(x = results_df, file =exposure_cell_or_clock_assoc)

rm(results_df)

  