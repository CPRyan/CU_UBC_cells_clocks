# Set color palette
cols <-c("#875692FF", "#F38400FF", "#A1CAF1FF", "#BE0032FF", "#C2B280FF",  "#008856FF", "#E68FACFF", "#0067A5FF", "#F99379FF", "#604E97FF", "#F6A600FF", "#B3446CFF", "#DCD300FF", "#882D17FF", "#8DB600FF", "#654522FF", "#E25822FF", "#2B3D26FF")


# Add "Null" to the data to get a Null group
categorical_variables_w_null <-c(categorical_variables, "Null")

#####################################################################################
# Function to create boxplot FOR CELLS
#####################################################################################
stratified_boxplots_cells <- function(categorical_variables_w_null) {

# Organize the Data  
    all_long <-cell_clock_df %>%
      mutate(Null = "Null") %>% 
      # pick categorical variables
    mutate(across(all_of(categorical_variables_w_null), as.factor)) %>% 
      # pick cells
    select(all_of(id), c(categorical_variables_w_null), Bas, Bmem, Bnv, CD4mem, CD4nv, CD8mem, CD8nv, Eos, Mono,  NK, Treg, Neu) %>% 
      # pivot longer
    pivot_longer(cols = c(Bas, Bmem, Bnv, CD4mem, CD4nv, CD8mem, CD8nv, Eos, Mono,  NK, Treg, Neu), names_to = "Cell Type", values_to = "Cell Count") 

  # Extract non_neutrophil data
  non_neu_long <-all_long %>% 
    filter(`Cell Type` != "Neu")
  # And take factor levels
  my_names <-levels(as_factor(non_neu_long$`Cell Type`))
  
  # Extract neutrophil data
  neu_long <-all_long %>% 
    filter(`Cell Type` == "Neu")
  
# Plot the data
  # Plot non-neutrophil data
  non_neu_plot <-non_neu_long %>% 
    # Remove na for categorical variable
    filter(!is.na(!!sym(categorical_variables_w_null))) %>% 
    ggplot() +
    stat_boxplot(aes(x = `Cell Type`, y = `Cell Count`, 
                     color = !!sym(categorical_variables_w_null)),
                 geom = "errorbar",
                 lwd = 1) +
    geom_boxplot(aes(x = `Cell Type`, y = `Cell Count`, 
                     color = !!sym(categorical_variables_w_null)),
                 outlier.shape = NA,
                 lwd = 1) +
    theme_bw() + 
    labs(x = "Cell Types", y = "Cell Counts") + 
    theme(legend.position = "top") +
    scale_x_discrete(labels = c(my_names)) + 
    theme(axis.text.x = element_text(angle = 45, vjust = 0.6, hjust = 0.5)) +
    theme(axis.title.x = element_blank())+
    scale_color_manual(values = cols)
  
  # Plot neutrophil data
  neu_plot <-neu_long %>% 
    filter(!is.na(!!sym(categorical_variables_w_null))) %>% 
    ggplot() +
    stat_boxplot(aes(x = `Cell Type`, y = `Cell Count`, 
                     color = !!sym(categorical_variables_w_null)),
                 geom = "errorbar",
                 lwd = 1) +
    geom_boxplot(aes(x = `Cell Type`, y = `Cell Count`, 
                     color = !!sym(categorical_variables_w_null)),
                 outlier.shape = NA,
                 lwd = 1) +
    theme_bw() + 
    labs(x = "Cell Types", y = "Cell Counts") + 
    theme(legend.position = "top") +
    scale_x_discrete(labels = "Neutrophils") + 
    theme(axis.text.x = element_text(angle = 45, vjust = 0.6, hjust = 0.5)) +
    theme(axis.title.x = element_blank())+
    scale_color_manual(values = cols)

# Pull out summary data from the plots (for summary files for further plotting)
  a <-ggplot_build(non_neu_plot)$data[[1]] %>% 
    select(ymin, lower, middle, upper, ymax, group)
  b <-ggplot_build(neu_plot)$data[[1]] %>% 
    select(ymin, lower, middle, upper, ymax, group)
  c <-bind_rows(a, b)
  
# Generate the CSV filename dynamically
  summary_filename <- paste0("Cells_Clocks_Output/Tables/",  study,  "_cells_", variable, "_summary.csv")
   
# Save the summary data to CSV
   write_csv(x = c %>% mutate(across(where(is.numeric), round, 3)), file = summary_filename)
  
  
# Join and print the figure itself
  full_plot = non_neu_plot + 
    neu_plot + theme(legend.position = "none") + plot_layout(ncol = 2, widths = c(9.3, 1)) 
  
  full_plot
}



#####################################################################################
# Function to create boxplots FOR CLOCKS
#####################################################################################


stratified_boxplots_clocks <- function(categorical_variables_w_null) {
  
  # Organize the Data  
  all_long <-cell_clock_df %>%
    mutate(Null = "Null") %>% 
    # pick categorical variables
    mutate(across(all_of(categorical_variables_w_null), as.factor)) %>% 
    # pick cells
    select(all_of(id), c(categorical_variables_w_null), PCHorvath1, PCPhenoAge, PCGrimAge, DunedinPACE) %>% 
    # pivot longer
    pivot_longer(cols = c(PCHorvath1, PCPhenoAge, PCGrimAge, DunedinPACE), names_to = "Clock Type", values_to = "Clock Estimate") 
  
  # Extract non_DunedinPACE data
  non_pace_long <-all_long %>% 
    filter(`Clock Type` != "DunedinPACE")
  # And take factor levels
  my_names <-levels(as_factor(non_pace_long$`Clock Type`))
  
  # Extract DunedinPACE data
  pace_long <-all_long %>% 
    filter(`Clock Type`== "DunedinPACE")
  
  # Plot the data
  # Plot non-DunedinPACE data
  non_pace_plot <-non_pace_long %>% 
    # Remove na for categorical variable
    filter(!is.na(!!sym(categorical_variables_w_null))) %>% 
    ggplot() +
    stat_boxplot(aes(x = `Clock Type`, y = `Clock Estimate`, 
                     color = !!sym(categorical_variables_w_null)),
                 geom = "errorbar",
                 lwd = 1) +
    geom_boxplot(aes(x = `Clock Type`, y = `Clock Estimate`, 
                     color = !!sym(categorical_variables_w_null)),
                 outlier.shape = NA,
                 lwd = 1) +
    theme_bw() + 
    labs(x = "Clock", y = "Clock Estimate") + 
    theme(legend.position = "top") +
    scale_x_discrete(labels = c(my_names)) + 
    theme(axis.text.x = element_text(angle = 45, vjust = 0.6, hjust = 0.5)) +
    theme(axis.title.x = element_blank())+
    scale_color_manual(values = cols)
  
  # Plot DunedinPACE data
  pace_plot <-pace_long %>% 
    filter(!is.na(!!sym(categorical_variables_w_null))) %>% 
    ggplot() +
    stat_boxplot(aes(x = `Clock Type`, y = `Clock Estimate`, 
                     color = !!sym(categorical_variables_w_null)),
                 geom = "errorbar",
                 lwd = 1) +
    geom_boxplot(aes(x = `Clock Type`, y = `Clock Estimate`, 
                     color = !!sym(categorical_variables_w_null)),
                 outlier.shape = NA,
                 lwd = 1) +
    theme_bw() + 
    labs(x = "Clock", y = "Clock Estimate") + 
    theme(legend.position = "top") +
    scale_x_discrete(labels = "DunedinPACE") + 
    theme(axis.text.x = element_text(angle = 45, vjust = 0.6, hjust = 0.5)) +
    theme(axis.title.x = element_blank())+
    scale_color_manual(values = cols)
  
  
  a <-ggplot_build(non_pace_plot)$data[[1]] %>% 
    select(ymin, lower, middle, upper, ymax, group)
  b <-ggplot_build(pace_plot)$data[[1]] %>% 
    select(ymin, lower, middle, upper, ymax, group)
  c <-bind_rows(a, b)
  
# Generate the CSV filename dynamically
  summary_filename <- paste0("Cells_Clocks_Output/Tables/", study, "_clocks_", variable, "_summary.csv")
  
# Save the summary data to CSV
  write_csv(x = c, file = summary_filename)
  
  
# Join and print
  full_plot = non_pace_plot + 
    pace_plot + theme(legend.position = "none") + plot_layout(ncol = 2, widths = c(9.3, 1)) 
  
  full_plot
}






# Create a list to store the plots
plots <- list()

# Run the boxplot function output for CELLS
for (variable in categorical_variables_w_null) {
  plot <- stratified_boxplots_cells(variable)
  plots[[variable]] <- plot
  # Save the plot using the variable name as part of the filename
  filename <- paste0(study, "_cells_", variable, "_boxplots.png")
  ggsave( filename = paste0("Cells_Clocks_Output/Figures/", filename), plot = plot)
}



# Create a list to store the plots
plots <- list()

# Run the boxplot function output for CLOCKS
for (variable in categorical_variables_w_null) {
  plot <- stratified_boxplots_clocks(variable)
  plots[[variable]] <- plot
  # Save the plot using the variable name as part of the filename
  filename <- paste0(study, "_clocks_", variable, "_boxplots.png")
  ggsave( filename = paste0("Cells_Clocks_Output/Figures/", filename), plot = plot)
}

