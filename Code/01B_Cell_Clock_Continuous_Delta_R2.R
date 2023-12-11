################
# To find the correlation (R2) of Continuous variable X and Cells or Clocks (accounting for other coavariates)
# Fit a model with X and all covariates
# Fit a model with only covariates
# Calculate the delta R2

################

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
  data <-data %>% select(Age, all_of(all_columns), 
                         any_of(control_covariates)) %>% na.omit()
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
# 
#####################################################################################

# Create an empty data frame to store the results
results_df <- data.frame(Cell_or_Clock_Outcome = character(),
                         Continuous_Variable = character(), 
                         R2_no_continuous_variable = numeric(),
                         R2_w_continuous_variable = numeric(),
                         Delta_R2 = numeric(),
                         n_obs = numeric(),
                         stringsAsFactors = FALSE)


# For each of the cell and clock outcomes.
for (key_var in paste0(all_columns, "_resids")) {
  # fit the basic model without the continuous_var
  basic_model <- lm(paste0(key_var, " ~ ", paste(control_covariates, collapse = " + ")), data = cell_clock_df)  
  # Extract coefficients using broom
  basic_model_r2 <- glance(basic_model)$adj.r.squared
  
  # Then, fit a model with the continous var, looping over each one at a time.
  for(continuous_var in continuous_variables){  
    # Fit the model with continuous_var
    full_model <- lm(paste0(key_var, " ~ ", continuous_var, " + ", paste(control_covariates, collapse = " + ")), data = cell_clock_df)    
    # Extract coefficients using broom
    full_model_r2 <- glance(full_model)$adj.r.squared
    nobs <-glance(full_model)$nobs
    
  
  results_df <- dplyr::bind_rows(results_df, data.frame(Cell_or_Clock_Outcome = key_var,
                                                        Continuous_Variable = continuous_var,
                                                        R2_no_continuous_variable = basic_model_r2,
                                                        R2_w_continuous_variable = full_model_r2,
                                                        Delta_R2 = full_model_r2 - basic_model_r2, 
                                                        n_obs = nobs) %>% mutate(across(where(is.numeric), round, 3))
  )
  }
}

# Generate the CSV filename dynamically
continuous_correlations_filename <- paste0("Cells_Clocks_Output/Tables/", study, "_clock_cell_continuous_delta_R2.csv")

# Save the summary data to CSV
write_csv(x = results_df, file = continuous_correlations_filename)
rm(results_df)