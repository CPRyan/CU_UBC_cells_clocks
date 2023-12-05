
# Create a list of column names you want to process
# # Cell columns
cell_columns <- c("Bas", "Bmem", "Bnv", "CD4mem", "CD4nv", "CD8mem", "CD8nv", "Eos", "Mono",  "NK", "Treg", "Neu")
# # Clock columns
clock_columns <- c("PCHorvath1", "PCPhenoAge", "PCGrimAge", "DunedinPACE")

# # merged together for residualization
all_columns <-c(clock_columns, cell_columns)

#####################################################################################
# Function to perform the regression and standardization
#####################################################################################
regression_and_standardization <- function(column_name, data) {
  data <-data %>% select(Age, all_of(all_columns), all_of(control_covariates)) %>% na.omit()
  # Perform the linear regression
  regression_model <- lm(data[[column_name]] ~ Age, data = data)
  # Get the residuals and standardize them
  residuals <- as.vector(scale(resid(regression_model)))
  # Return the standardized residuals as a named vector
  return(residuals)
}

############################
# Use lapply to run the regression and standardization for each column
############################
standardized_residuals_list <- lapply(all_columns, function(column) {
  regression_and_standardization(column, cell_clock_df)
})

# Name the columns of residualized outcomes
names(standardized_residuals_list) <- paste0(all_columns, "_resids")

cell_clock_df <-bind_cols(cell_clock_df, as_tibble(standardized_residuals_list)) 

#####################################################################################
# Function to take the input from above and run regressions with clock, one cell at a time, and covariates
# then take estimate of cell with clock, and CI for each one, then save as a table
#####################################################################################


# Create an empty data frame to store the results
results_df <- data.frame(Clock_Variable = character(),
                         Cell_Variable = character(), 
                         Beta = numeric(),
                         Lower_CI = numeric(),
                         Upper_CI = numeric(),
                         stringsAsFactors = FALSE)

# Iterate through clock_columns
for (clock_var in paste0(clock_columns, "_resids")) {
  # Iterate through cell_columns
  for (cell_var in paste0(cell_columns, "_resids")) {
    
    # Fit a linear regression model
    model <- lm(paste0(clock_var, " ~ ", cell_var, " + ", paste(control_covariates, collapse = " + ")), data = cell_clock_df)
    
    # Extract coefficients and confidence intervals using broom
    tidy_model <- tidy(model)
    
    # Filter the coefficients for the cell variable
    cell_coefficients <- filter(tidy_model, term == cell_var)
    
    # Calculate the standard error
    se <- cell_coefficients$std.error
    
    # Calculate the confidence intervals
    lower_ci <- cell_coefficients$estimate - 1.96 * se
    upper_ci <- cell_coefficients$estimate + 1.96 * se
    
    # Add the results to the results data frame
    results_df <- bind_rows(results_df, data.frame(Clock_Variable = clock_var,
                                                   Cell_Variable = cell_var,
                                                   Beta = cell_coefficients$estimate,
                                                   Lower_CI = lower_ci,
                                                   Upper_CI = upper_ci)) %>% mutate(across(where(is.numeric), round, 3))
  }
}

# Generate the CSV filename dynamically
univariate_correlations_filename <- paste0("Cells_Clocks_Output/Tables/", study, "_clock_cell_univariate_correlations.csv")

# Save the summary data to CSV
write_csv(x = results_df, file = univariate_correlations_filename)
rm(results_df)
