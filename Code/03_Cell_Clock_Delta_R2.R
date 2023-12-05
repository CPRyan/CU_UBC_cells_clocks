# Delta R2 for each clock with and without cells
# Basic model:
#   Outcome: Clock (residualized for age)
#   Covariates: Age (again), any other technical components listed in "covariate_variables"
# Full model
#   Outcome: Clock (residualized for age)
#   Covariates: same as above + all 12 cells
#
# 
# Pseudocode:
#  Model for level i of categorical variable j without cells
#   Repeat for all clocks in clock_var
#  Model for level i of categorical variable j with cells
#   Repeat for all clocks in clock_var
#   Calculate delta R2 for level i of categorical variable j
#    Repeat for all clocks in clock_var
#  Model for level i+1 of categorical variable j without cells
#   Repeat for all clocks in clock_var
#  Model for level i+1 of categorical variable j with cells
#   Repeat for all clocks in clock_var
#   Calculate delta R2 for level i+1 of categorical variable j
#    Repeat for all clocks in clock_var
#  Repeat for all levels of categorical variable j
#  Move onto categorical variable j+1 and repeat


# Create an empty data frame to store the results
results_df <- data.frame(Clock_Variable = character(),
                         Categorical_Variable = character(),
                         Categorical_Level = character(),
                         R2_no_cells = numeric(),
                         R2_cells = numeric(),
                         Delta_R2 = numeric(),
                         n_obs = numeric(),
                         stringsAsFactors = FALSE)


#####################################################################################
# Basic model not stratified. 
#####################################################################################

# Fit a linear regression model for each clock variable, including all cell variables and covariates
for (clock_var in paste0(clock_columns, "_resids")) {
  # Fit the model WITHOUT CELLS
  basic_model <- lm(paste0(clock_var, " ~ ", "Age", " + ", paste(control_covariates, collapse = " + ")), data = cell_clock_df)  
  
  # Extract coefficients using broom
  basic_model_r2 <- glance(basic_model)$adj.r.squared
  
  # Fit the model WITH CELLS
  full_model <- lm(paste0(clock_var, " ~ ", "Age", "+", paste(paste0(cell_columns, "_resids"), collapse = " + "), " + ", paste(control_covariates, collapse = " + ")), data = cell_clock_df)    
  
  # Extract coefficients using broom
  full_model_r2 <- glance(full_model)$adj.r.squared
  nobs <-glance(full_model)$nobs
  
  
  results_df <- dplyr::bind_rows(results_df, data.frame(Clock_Variable = clock_var,
                                                        Categorical_Variable = "Full Dataset",
                                                        Categorical_Level = "Full Dataset",
                                                        R2_no_cells = basic_model_r2,
                                                        R2_cells = full_model_r2,
                                                        Delta_R2 = full_model_r2 - basic_model_r2, 
                                                        n_obs = nobs) %>% mutate(across(where(is.numeric), round, 3))
  )
}





#####################################################################################
# Stratified
#####################################################################################





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
      # Subset the data for the current level of the categorical variable
      subset_data <- cell_clock_df %>% filter(.data[[categorical_var]] == level)
      
      # Check if there are enough observations for the model
      if (nrow(subset_data) < 2) {
        next
      }
      
      # Fit the model WITHOUT CELLS
      basic_model <- lm(paste0(clock_var, " ~ ", "Age", " + ", paste(control_covariates, collapse = " + ")), data = subset_data)  
      
      # Extract coefficients using broom
      basic_model_r2 <- glance(basic_model)$adj.r.squared
      
      # Fit the model WITH CELLS
      full_model <- lm(paste0(clock_var, " ~ ", "Age", "+", paste(paste0(cell_columns, "_resids"), collapse = " + "), " + ", paste(control_covariates, collapse = " + ")), data = subset_data)    
      
      # Extract coefficients using broom
      full_model_r2 <- glance(full_model)$adj.r.squared
      nobs <-glance(full_model)$nobs
      
      # Add the results to the results data frame
      results_df <- dplyr::bind_rows(results_df, data.frame(Clock_Variable = clock_var,
                                                            Categorical_Variable = categorical_var,
                                                            Categorical_Level = level,
                                                            R2_no_cells = basic_model_r2,
                                                            R2_cells = full_model_r2,
                                                            Delta_R2 = full_model_r2 - basic_model_r2, 
                                                            n_obs = nobs) %>% mutate(across(where(is.numeric), round, 3))
      )
    }
  }    
}  
      
delta_R2_filename <- paste0("Cells_Clocks_Output/Tables/", study, "_delta_r2.csv")
write_csv(x = results_df, file = delta_R2_filename)
rm(results_df)
      
      