# Create an empty data frame to store the results
results_df <- data.frame(Clock_Variable = character(),
                         Exposure = character(),
                         Beta_no_cells = numeric(),
                         Lower_CI_no_cells = numeric(),
                         Upper_CI_no_cells = numeric(),
                         Beta_cells = numeric(),
                         Lower_CI_cells = numeric(),
                         Upper_CI_cells = numeric(),
                         stringsAsFactors = FALSE)



# Iterate through categorical variables to make a subset
for (categorical_var in categorical_variables) {
 
   # Iterate through clock columns
  for (clock_var in paste0(clock_columns, "_resids")) {
    
  # Make sure I'm not missing any data points
  cell_clock_df_resids_nona <-cell_clock_df %>% filter(!is.na(!!sym(categorical_var)))
  
      
      # Fit the model WITHOUT CELLS
      model <- lm(paste0(clock_var, " ~ ", "Age", " + ", paste(control_covariates, collapse = " + "), "+", categorical_var), data = cell_clock_df_resids_nona)  
      
      # Extract coefficients and confidence intervals using broom
      tidy_model <- tidy(model)
      
      # Filter the coefficients for the cell variables
      exposure_coefficients <- tidy_model %>% filter(grepl(categorical_var, term))
      
      # Calculate the standard error
      se <- exposure_coefficients$std.error
      
      # Calculate the confidence intervals
      lower_ci <- exposure_coefficients$estimate - 1.96 * se
      upper_ci <- exposure_coefficients$estimate + 1.96 * se
      
      # -------------
      
      # Fit a linear regression model WITH CELLS
      model_cells <- lm(paste0(clock_var, " ~ ", "Age", " + ", paste(control_covariates, collapse = " + "), "+", paste(paste0(cell_columns, "_resids"), collapse = " + "), "+", categorical_var), data = cell_clock_df_resids_nona)
      
      # Extract coefficients and confidence intervals using broom
      tidy_model_cells <- tidy(model_cells)
      
      # Filter the coefficients for the cell variables
      exposure_coefficients_cells <- tidy_model_cells %>% filter(grepl(categorical_var, term))
      
      # Calculate the standard error
      se_cells <- exposure_coefficients_cells$std.error
      
      # Calculate the confidence intervals
      lower_ci_cells <- exposure_coefficients_cells$estimate - 1.96 * se_cells
      upper_ci_cells <- exposure_coefficients_cells$estimate + 1.96 * se_cells
      
      
      # Add the results to the results data frame
      results_df <- dplyr::bind_rows(results_df, data.frame(Clock_Variable = clock_var,
                                                 Exposure = exposure_coefficients$term,
                                                 Beta_no_cells = exposure_coefficients$estimate,
                                                 Lower_CI_no_cells = lower_ci,
                                                 Upper_CI_no_cells = upper_ci,
                                                 Beta_cells = exposure_coefficients_cells$estimate,
                                                 Lower_CI_cells = lower_ci_cells,
                                                 Upper_CI_cells = upper_ci_cells)) %>% mutate(across(where(is.numeric), round, 3))
    }
  }



# Generate the CSV filename dynamically
exposure_clock_w_wo_cells <- paste0("Cells_Clocks_Output/Tables/", study, "_exposure_clock_with_without_cells.csv")

# Save the summary data to CSV
write_csv(x = results_df, file = exposure_clock_w_wo_cells)

rm(results_df)