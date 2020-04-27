# ----
# Supplemental R script for:
# Soils' dirty little secret: Depth-based comparisons can be inadequate
# for quantifying changes in soil organic carbon
# and other mineral soil properties.
# By:
# Adam C. von Haden, Wendy H. Yang, Evan H. DeLucia

# Purpose: To calculate SOC stocks and SOC mass percentages
# using the equivalent soil mass approach.

# Author: Adam C. von Haden

# Date: 2020-03-23

# Notes:
# Example_datasets.xlsx is available as a supplemental file
# See Supplemental Information for full documentation

# Load required libraries ----
# These libraries may first need to be installed by the user
library(openxlsx)
library(dplyr)
library(tidyr)

# Get input from user ----
# Filename of the input XLSX spreadsheet
input_file_name <- "Example_datasets.xlsx"

# Name of the sheet on the spreadsheet that contains the data
input_file_sheet <- "a_temporal_paired"

# The minimum core length acceptable to use for ESM
min_core_length_cm <- 0

# Determines if extrapolation will be allowed outside of sample mass
# Options are TRUE and FALSE
extrapolation <- TRUE

# Sets the (lower) depths at which reference masses are calculated
# Depths must be present in references
ESM_depths_cm <- c(10, 30, 50, 100)

# Desired filename of the ouput XLSX spreadsheet
output_filename <- "FD_ESM_output.xlsx"

# Import XLSX file ----
raw_FD <- read.xlsx(input_file_name, sheet=input_file_sheet)

# Check input for basic errors ----
is_error <- FALSE
required_colnames <- c("ID", "Ref_ID", "Rep", "Upper_cm", "Lower_cm","SOC_pct", "SOM_pct", "BD_g_cm3")

if (!all(required_colnames %in% colnames(raw_FD))){
 is_error <- TRUE
 stop(gettextf("Missing or misspelled column name(s)"))
}

if (any(is.na(raw_FD$ID) | is.na(raw_FD$Ref_ID) | is.na(raw_FD$Rep))){
 is_error <- TRUE
 stop(gettextf("Missing ID, Rep, or Ref_ID values"))
}

if (any(is.na(raw_FD$Upper_cm) | is.na(raw_FD$Lower_cm))) {
 is_error <- TRUE
 stop(gettextf("Missing Upper_cm or Lower_cm values"))
}

if (any(!is.numeric(raw_FD$Upper_cm) | !is.numeric(raw_FD$Lower_cm))) {
 is_error <- TRUE
 stop(gettextf("Non-numeric Upper_cm or Lower_cm values"))
}

if (any(!is.numeric(raw_FD$SOC_pct) | !is.numeric(raw_FD$BD_g_cm3) |!is.numeric(raw_FD$SOM_pct))){
 is_error <- TRUE
 stop(gettextf("Non-numeric SOC_pct, BD_g_cm3, or SOM_pct values"))
}

# Stop script if there is an error with the input file ----
if (is_error){
 warning(gettextf("ESM script has failed due to error(s) listed above"))
} else {

  # Begin processing input file ----

  # Remove extra columns and add FD type
  reduced_FD <- subset(raw_FD, select=c(ID, Rep, Ref_ID, Upper_cm, Lower_cm, SOC_pct, SOM_pct, BD_g_cm3))
  reduced_FD$Type <- "FD"

  # Order columns
  reduced_FD <- reduced_FD[, c("Type", "ID", "Rep", "Ref_ID", "Upper_cm", "Lower_cm", "SOC_pct", "SOM_pct", "BD_g_cm3")]

  # Remove cores that do not have a surface (0 cm) sample
  filtered_FD <- reduced_FD %>% group_by(ID, Rep) %>%
  filter(min(Upper_cm) == 0)

  # Remove samples that have NAs
  filtered_FD <- filtered_FD %>% drop_na

  # Remove any samples that are below a zone of non-contiguity
  filtered_FD <- filtered_FD %>% arrange(ID, Rep, Upper_cm, Lower_cm)

  all_contiguous_FD <- filtered_FD %>%
  group_by(ID, Rep) %>%
  filter(all(Upper_cm==dplyr::lag(Lower_cm, default=FALSE)))

  noncontiguous_FD <- filtered_FD %>%
  group_by(ID, Rep) %>%
  filter(any(Upper_cm!=dplyr::lag(Lower_cm, default=FALSE)))

  removed_noncontiguous_FD <- noncontiguous_FD %>%
  group_by(ID, Rep) %>%
  filter(Upper_cm < Upper_cm[which(Upper_cm!=dplyr::lag(Lower_cm,
  default=FALSE))])

  filtered_FD <- rbind(all_contiguous_FD, removed_noncontiguous_FD)
 
  # Remove cores that do not have a sample deeper than min_core_length_cm
  filtered_FD <- filtered_FD %>%
  group_by(ID, Rep) %>%
  filter(!max(Lower_cm) < min_core_length_cm)

  # Throw an error if there are no observations left in dataset
  if (nrow(filtered_FD)==0){
  stop(gettextf("No observations remaining in dataset"))
  }

  # Add in zero masses at zero cm (for interpolation of first interval)
  modified_FD <- filtered_FD %>%
  group_by(ID, Ref_ID, Rep) %>%
  summarise() %>%
  mutate(Type = "FD", Upper_cm=0, Lower_cm=0,
  SOC_pct=0, SOM_pct=0, BD_g_cm3=0) %>%
  bind_rows(filtered_FD, .) %>%
  arrange(ID, Ref_ID, Rep, Upper_cm, Lower_cm)

  # Begin FD-based calculations ----

  # Calculate soil mass in each interval
  modified_FD$Soil_g_cm2 <-
  (modified_FD$Lower_cm-modified_FD$Upper_cm)*modified_FD$BD_g_cm3

  # Calculate SOC mass in each interval
  modified_FD$SOC_g_cm2 <- (modified_FD$SOC_pct/100)*modified_FD$Soil_g_cm2

  # Calculate SOM mass in each interval
  modified_FD$SOM_g_cm2 <- (modified_FD$SOM_pct/100)*modified_FD$Soil_g_cm2

  # Calculate mineral soil mass in each interval
  modified_FD$Min_Soil_g_cm2 <- modified_FD$Soil_g_cm2-modified_FD$SOM_g_cm2

  # Calculate cumulative masses
  cumulative_FD <- modified_FD %>%
  group_by(ID, Rep) %>%
  mutate(Cum_Soil_g_cm2 = cumsum(Soil_g_cm2),
         Cum_SOC_g_cm2 = cumsum(SOC_g_cm2),
         Cum_SOM_g_cm2 = cumsum(SOM_g_cm2),
         Cum_Min_Soil_g_cm2 = cumsum(Min_Soil_g_cm2))
        
  # Begin ESM-based calculations
  cumulative_ESM <- data.frame()

  for (i in 1:nrow(distinct(cumulative_FD, ID, Ref_ID, Rep))){
    current_vals <- distinct(cumulative_FD, ID, Ref_ID, Rep)[i,]
    current_Rep <- subset(cumulative_FD, ID==current_vals$ID &
                            Ref_ID==current_vals$Ref_ID &
                            Rep==current_vals$Rep)

    # Subset the reference set of values
    current_refs <- subset(cumulative_FD, ID==current_vals$Ref_ID)

    # Average the reference values (in case of multiple values per depth)
    current_refs_mean <- current_refs %>% group_by(Upper_cm, Lower_cm) %>%
      filter(Lower_cm %in% ESM_depths_cm) %>%
      mutate_at(vars(-Upper_cm, -Lower_cm, -Cum_Min_Soil_g_cm2),
                function(x) x = NA) %>%
      mutate(Cum_Min_Soil_g_cm2 = mean(Cum_Min_Soil_g_cm2, na.rm=TRUE)) %>%
      summarise_all(mean) %>%
      mutate(ID=current_vals$ID, Ref_ID=current_vals$Ref_ID,
             Rep=current_vals$Rep, Type="ESM")

    #Determine whether extrapolation outside of maximum mass occurs
    if (extrapolation == FALSE) {
      # Remove references where mineral mass is greater than the sample max
      # Completely avoids extrapolation outside of spline model
      current_refs_filtered <-
        current_refs_mean[which(current_refs_mean$Cum_Min_Soil_g_cm2
                              <= max(current_Rep$Cum_Min_Soil_g_cm2)),]
    } else {
      # Remove references that have a depth greater than sample max
      # Extraoplates only to the maximum depth of the samples
      current_refs_filtered <-
        current_refs_mean[which(current_refs_mean$Lower_cm <=
                                max(current_Rep$Lower_cm)),]
    }

    # Interpolate SOC and SOM using cubic spline models
    current_refs_filtered$Cum_SOC_g_cm2 <-
      spline(x=current_Rep$Cum_Min_Soil_g_cm2,
             y=current_Rep$Cum_SOC_g_cm2,
             xout=current_refs_filtered$Cum_Min_Soil_g_cm2,
             method="hyman")$y

    current_refs_filtered$Cum_SOM_g_cm2 <-
      spline(x=current_Rep$Cum_Min_Soil_g_cm2,
             y=current_Rep$Cum_SOM_g_cm2,
             xout=current_refs_filtered$Cum_Min_Soil_g_cm2,
             method="hyman")$y
        
    # Calculate non-cumulative masses
    current_refs_final <- current_refs_filtered %>%
      group_by(ID, Ref_ID, Rep) %>%
      mutate(Min_Soil_g_cm2 =
              Cum_Min_Soil_g_cm2-dplyr::lag(Cum_Min_Soil_g_cm2, default=0), 
              SOC_g_cm2 = Cum_SOC_g_cm2-dplyr::lag(Cum_SOC_g_cm2, default=0),
              SOM_g_cm2 = Cum_SOM_g_cm2-dplyr::lag(Cum_SOM_g_cm2, default=0))

    current_refs_final$Soil_g_cm2 <-
      current_refs_final$Min_Soil_g_cm2 + current_refs_final$SOM_g_cm2

    current_refs_final$BD_g_cm3 <-
      current_refs_final$Soil_g_cm2/
      (current_refs_final$Lower_cm-current_refs_final$Upper_cm)

    current_refs_final$SOC_pct <-
      current_refs_final$SOC_g_cm2/current_refs_final$Soil_g_cm2*100

    current_refs_final$SOM_pct <-
      current_refs_final$SOM_g_cm2/current_refs_final$Soil_g_cm2*100

    current_refs_final$Cum_Soil_g_cm2 <-
      cumsum(current_refs_final$Soil_g_cm2)

    current_ESM <- data.frame(current_refs_final)
      cumulative_ESM <- rbind(cumulative_ESM, current_ESM)
  }

  # Post-processing cleanup and output ----
  # Remove zero masses at zero depth ESM and FD
  cumulative_FD <- subset(cumulative_FD, !(Upper_cm == 0 & Lower_cm == 0))
  cumulative_ESM <- subset(cumulative_ESM, !(Upper_cm == 0 & Lower_cm == 0))

  # Add NA for FD reference ID
  cumulative_FD$Ref_ID <- NA

  # Re-order column names in ESM dataset
  cumulative_ESM <- cumulative_ESM[colnames(cumulative_FD)]

  # Output datasets to XLSX file
  output_wb <- createWorkbook()
  addWorksheet(output_wb, "FD")
  addWorksheet(output_wb, "ESM")
  writeData(output_wb, "FD", cumulative_FD)
  writeData(output_wb, "ESM", cumulative_ESM)
  saveWorkbook(output_wb, output_filename)
  print(paste("Results have been saved to", output_filename, sep=" "))

  # Clear objects from R environment
  rm(list = ls())
}
