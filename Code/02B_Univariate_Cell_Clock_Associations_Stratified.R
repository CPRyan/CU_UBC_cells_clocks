
#####################################################################################
# Function to take the input from above and run regressions with clock, one cell at a time, and covariates
# then take estimate of cell with clock, and CI for each one, then save as a table
# ****
# STRATIFIED BY GROUPS
# ****
#####################################################################################


# Create an empty data frame to store the results
results_df <- data.frame(Clock_Variable = character(),
                         Categorical_Variable = character(),
                         Categorical_Level = character(),
                         Cell_Variable = character(), 
                         Beta = numeric(),
                         Lower_CI = numeric(),
                         Upper_CI = numeric(),
                         stringsAsFactors = FALSE)


# Iterate through categorical variables
for (categorical_var in categorical_variables) {
  # Ensure that the categorical variable is treated as a factor
  cell_clock_df[[categorical_var]] <- as.factor(cell_clock_df[[categorical_var]])
  
  # Get unique non-NA levels of the categorical variable
  levels <- unique(na.omit(cell_clock_df[[categorical_var]]))
  
  # Skip categorical variables with fewer than two unique non-NA levels
  if (length(levels) < 2) {
    next
  }
  
  # Iterate through levels
  for (level in levels) {
    # Fit a linear regression model for each clock variable, including all cell variables and covariates
    for (clock_var in paste0(clock_columns, "_resids")) {
      # Iterate through cell_columns
      for (cell_var in paste0(cell_columns, "_resids")) {
        # Subset the data for the current level of the categorical variable
        subset_data <- cell_clock_df %>% filter(.data[[categorical_var]] == level)
        
        # Check if there are enough observations for the model
        if (nrow(subset_data) < 2) {
          next
        }
        
        # Fit the model
        model <- lm(paste0(clock_var, " ~ ", cell_var, " + ", paste(control_covariates, collapse = " + ")), data = subset_data)
        
        # Extract coefficients using broom
        tidy_model <- broom::tidy(model)
        
        # Filter the coefficients for the cell variable
        cell_coefficients <- filter(tidy_model, term == cell_var)
        
        # Calculate the standard error
        se <- cell_coefficients$std.error
        
        # Calculate the confidence intervals
        lower_ci <- cell_coefficients$estimate - 1.96 * se
        upper_ci <- cell_coefficients$estimate + 1.96 * se
        
        # Add the results to the results data frame
        results_df <- dplyr::bind_rows(results_df, data.frame(Cell_Variable = cell_coefficients$term,
                                                              Clock_Variable = clock_var,
                                                              Categorical_Variable = categorical_var,
                                                              Categorical_Level = level,
                                                              Beta = cell_coefficients$estimate,
                                                              Lower_CI = lower_ci,
                                                              Upper_CI = upper_ci)) %>% mutate(across(where(is.numeric), round, 3))
      }
    }
  }
}


# Generate the CSV filename dynamically
univariate_correlations_filename_stratified <- paste0("Cells_Clocks_Output/Tables/", study, "_clock_cell_univariate_correlations_stratified.csv")

# Save the summary data to CSV
write_csv(x = results_df %>% arrange(desc(Clock_Variable), Cell_Variable, Categorical_Variable), file = univariate_correlations_filename_stratified)
rm(results_df)