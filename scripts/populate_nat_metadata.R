#
# Author: Dan Wismer 
#
# Date: March 29th, 2023
#
# Description: Copies prepped National rasters to the Tiffs folder.
#              Generates a metadata.csv for all national layers. This csv is 
#              a required input for 03_format_data_wtw.R.  
#
# Inputs:  1. A folder of national rasters (from natdata_to_aoi_1km_grid.R) 
#          2. Output names and paths
#
# Outputs: 1. A metadata.csv to QC (quality control)
#
#
# 1.0 Load packages ------------------------------------------------------------

## Start timer
start_time <- Sys.time()

## Package names
packages <- c("tibble", "raster", "dplyr", "stringr", "readr", "readxl")

## Install packages not yet installed
installed_packages <- packages %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(packages[!installed_packages])
}

library(tibble)
library(raster)
library(dplyr)
library(stringr)
library(readr)
library(readxl)
source("scripts/functions/fct_sci_to_common.R")
source("scripts/functions/fct_init_metadata.R")

# 2.0 Set up -------------------------------------------------------------------

## File path variables ----

### CHANGE PATH AND NAMES FOR NEW PROJECT
output_metadata_name <- "sw-on" 

aoi_data_folder <- "National"
tiff_folder <-"Tiffs"
metadata_folder <- "WTW/metadata" 
table_path <- "National/_Tables"
input_aoi_name <- "AOI.tif"

# NOTE: The datasets required for WTW can be edited at the bottom of the next
# section by changing the 'WtW' list object

# 3.0 Copy to Tiffs ------------------------------------------------------------

# Get list of files ----
ECCC_CH <- list.files(paste0(aoi_data_folder, "Themes/ECCC_CH"), 
                      pattern='.tif$', full.names = T, recursive = F)

ECCC_SAR <- list.files(paste0(aoi_data_folder, "Themes/ECCC_SAR"), 
                       pattern='.tif$', full.names = T, recursive = F)

IUCN_AMPH <- list.files(paste0(aoi_data_folder, "Themes/IUCN_AMPH"), 
                        pattern='.tif$', full.names = T, recursive = F)

IUCN_BIRD <- list.files(paste0(aoi_data_folder, "Themes/IUCN_BIRD"), 
                        pattern='.tif$', full.names = T, recursive = F)

IUCN_MAMM <- list.files(paste0(aoi_data_folder, "Themes/IUCN_MAMM"), 
                        pattern='.tif$', full.names = T, recursive = F)

IUCN_REPT <- list.files(paste0(aoi_data_folder, "Themes/IUCN_REPT"), 
                        pattern='.tif$', full.names = T, recursive = F)

NSC_END <- list.files(paste0(aoi_data_folder, "Themes/NSC_END"), 
                      pattern='.tif$', full.names = T, recursive = F)

NSC_SAR <- list.files(paste0(aoi_data_folder, "Themes/NSC_SAR"), 
                      pattern='.tif$', full.names = T, recursive = F)

NSC_SPP <- list.files(paste0(aoi_data_folder, "Themes/NSC_SPP"), 
                      pattern='.tif$', full.names = T, recursive = F)

LC <- list.files(paste0(aoi_data_folder, "Themes/LC"), 
                 pattern='.tif$', full.names = T, recursive = F)

KM <- list.files(paste0(aoi_data_folder, "Themes/KM"), 
                 pattern='.tif$', full.names = T, recursive = F)

W <- list.files(paste0(aoi_data_folder,"Weights"), 
                pattern='.tif$', full.names = T, recursive = F)

Incl <- list.files(paste0(aoi_data_folder, "Includes"), 
                   pattern='.tif$', full.names = T, recursive = F)

Excl <- list.files(paste0(aoi_data_folder, "Excludes"), 
                   pattern='.tif$', full.names = T, recursive = F)

# Change list here to include or exclude layers to copy ----
WtW <- list(ECCC_CH, ECCC_SAR, 
            IUCN_AMPH, IUCN_BIRD, IUCN_MAMM, IUCN_REPT, 
            NSC_END, NSC_SAR, NSC_SPP, 
            LC, KM, 
            W, Incl, Excl)

# Copy files to Tiff folder ----
for (file in WtW) {
  name <- tools::file_path_sans_ext(basename(file))
  file.copy(file, paste0(tiff_folder, "/", name, ".tif"))
}

# 4.0 Prep for metadata --------------------------------------------------------

# Read-in look up tables ----
ECCC_SAR_LU <- read_csv(file.path(table_path, "ECCC_SAR_Metadata.csv"))
ECCC_CH_LU <- read_excel(file.path(table_path,  "ECCC_CH_Metadata.xlsx"))
IUCN_LU <- read_csv(file.path(table_path, "IUCN_Metadata.csv"))
NSC_END_LU <- read_excel(file.path(table_path,  "NSC_END_Metadata.xlsx"))
NSC_SAR_LU <- read_excel(file.path(table_path, "NSC_SAR_Metadata.xlsx"))
NSC_SPP_LU <- read_excel(file.path(table_path, "NSC_SPP_Metadata.xlsx"))

## Read-in tiff file paths ----
file_list <- list.files(tiff_folder, pattern='.tif$', 
                        full.names = T, recursive = T) 

## Remove AOI from file list (if it's in there) ----
aoi_path <- file.path(tiff_folder, input_aoi_name) 
file_list <- file_list[file_list != aoi_path]

## Build empty data.frame (template for metadata.csv) ----
df <- init_metadata()

# 5.0 Populate metadata --------------------------------------------------------

## Set up counter
counter <- 1
len <- length(file_list)

## Loop over each tiff file:
for (file in file_list) {
  
  ### Read-in raster
  wtw_raster <- raster(file)
  
  ## FILE ----------------------------------------------------------------------
  ### assign file name with extension of layer (ex. I_Protected.tif)
  file_no_ext <- paste0(tools::file_path_sans_ext(basename(file)))
  file <-  paste0(file_no_ext,".tif")
  #### message
  print(paste0("Populating ", counter, " of ", len, ": ", file))
  
  ## TYPE ----------------------------------------------------------------------
  ### Aoi
  if (startsWith(file_no_ext, "AOI")) {
    type <- "-"
    ### Theme  
  } else if (startsWith(file_no_ext, "T_")) {
    type <- "theme"
    ### Weight  
  } else if (startsWith(file_no_ext, "W_")) {
    type <- "weight"
    ### Include  
  } else if (startsWith(file_no_ext, "I_")) {
    type <- "include"
    ### Exclude  
  } else if (startsWith(file_no_ext, "E_")) {
    type <- "exclude"
    ### Other ...    
  } else {
    type <- ""
  }
  
  ## NAME ----------------------------------------------------------------------
  ### ECCC SAR
  if (startsWith(file_no_ext, "T_ECCC_SAR_")) {
    name <- unlist(str_split(file_no_ext, "T_ECCC_SAR_COSEWICID_"))[2] 
    name <- sar_cosewicid_to_name(ECCC_SAR_LU, name, "common")
    ### ECCC CH  
  } else if (startsWith(file_no_ext, "T_ECCC_CH")) {
    name <- unlist(str_split(file_no_ext, "T_ECCC_CH_COSEWICID_"))[2]
    name <- ch_cosewicid_to_name(ECCC_CH_LU, name, "common")
    ### IUCN AMPH  
  } else if (startsWith(file_no_ext, "T_IUCN_AMPH")) {
    name <- unlist(str_split(file, "T_IUCN_AMPH_"))[2]
    name <- iucn_to_name(IUCN_LU, name)
    ### IUCN BIRD  
  } else if (startsWith(file_no_ext, "T_IUCN_BIRD")) {
    name <- unlist(str_split(file, "T_IUCN_BIRD_"))[2]
    name <- iucn_to_name(IUCN_LU, name)
    ### IUCN MAMM  
  } else if (startsWith(file_no_ext, "T_IUCN_MAMM")) {
    name <- unlist(str_split(file, "T_IUCN_MAMM_"))[2]
    name <- iucn_to_name(IUCN_LU, name)
    ### IUCN REPT  
  } else if (startsWith(file_no_ext, "T_IUCN_REPT")) {
    name <- unlist(str_split(file, "T_IUCN_REPT_"))[2]
    name <- iucn_to_name(IUCN_LU, name)
    ### NSC END  
  } else if (startsWith(file_no_ext, "T_NSC_END")) {
    name <- unlist(str_split(file_no_ext, "T_NSC_END_"))[2] 
    name <- str_replace_all(name, "_", " ")
    name <- nsc_end_to_name(NSC_END_LU, name)
    ### NSC SAR  
  } else if (startsWith(file_no_ext, "T_NSC_SAR")) {
    name <- unlist(str_split(file_no_ext, "T_NSC_SAR_"))[2] 
    name <- str_replace_all(name, "_", " ") 
    name <- nsc_sar_to_name(NSC_SAR_LU, name)
    ### NSC SPP  
  } else if (startsWith(file_no_ext, "T_NSC_SPP")) {
    name <- unlist(str_split(file_no_ext, "T_NSC_SPP_"))[2] 
    name <- str_replace_all(name, "_", " ")
    name <- nsc_spp_to_name(NSC_SPP_LU, name)
    ### LC  
  } else if (startsWith(file_no_ext, "T_LC_")) {
    name <- unlist(str_split(file_no_ext, "T_LC_"))[2] 
    name <- str_replace_all(name, "_", " ") 
    if (name == "Forest-lc") {
      name <- "Forest (LC)"
    } else if (name == "Forest-lu") {
      name <- "Forest (LU)"
    }
    ### KM - Rivers, Shoreline  
  } else if (startsWith(file_no_ext, "T_KM_")) {
    name <- unlist(str_split(file_no_ext, "T_KM_"))[2]
    name <- str_replace_all(name, "_", " ") 
    if (name == "River length") {
      name <- "Rivers"
    } else if (name == "Shoreline length") {
      name <- "Shoreline"
    }
    ### Weights  
  } else if (startsWith(file_no_ext, "W_")) {
    name_ <- unlist(str_split(file_no_ext, "W_"))[2] # split string
    name <- str_replace_all(name_, "_", " ") # replace underscore with space
    ### Includes  
  } else if (startsWith(file_no_ext, "I_Protected")) {
    name <- "Existing Conservation (CPCAD)"
    ### Other ...   
  } else {
    name <- ""
  }
  
  ## THEME ---------------------------------------------------------------------
  ### ECCC SAR
  if (startsWith(file_no_ext, "T_ECCC_SAR")) {
    theme <- "Species at Risk (ECCC)"
    ### ECCC CH  
  } else if (startsWith(file_no_ext, "T_ECCC_CH")) {
    theme <- "Critical Habitat (ECCC)"      
    ### IUCN AMPH  
  } else if (startsWith(file_no_ext, "T_IUCN_AMPH")) {
    theme <- "Amphibians (IUCN)"
    ### IUCN BIRD  
  } else if (startsWith(file_no_ext, "T_IUCN_BIRD")) {
    theme <- "Birds (IUCN)" 
    ### IUCN MAMM  
  } else if (startsWith(file_no_ext, "T_IUCN_MAMM")) {
    theme <- "Mammals (IUCN)"
    ### IUCN REPT  
  } else if (startsWith(file_no_ext, "T_IUCN_REPT")) {
    theme <- "Reptiles (IUCN)"
    ### NSC SAR  
  } else if (startsWith(file_no_ext, "T_NSC_SAR")) {
    theme <- "Species at Risk (NSC)"
    ### NSC END  
  } else if (startsWith(file_no_ext, "T_NSC_END")) {
    theme <- "Endemic Species (NSC)"
    ### NSC SPP      
  } else if (startsWith(file_no_ext, "T_NSC_SPP")) {
    theme <- "Common Species (NSC)"
    ### LC  
  } else if (startsWith(file_no_ext, "T_LC")) {
    theme <- "Land Cover"
    ### KM, Rivers  
  } else if (startsWith(file_no_ext, "T_KM_River")) {
    theme <- "Rivers"
    ### KM, Shoreline  
  } else if (startsWith(file_no_ext, "T_KM_Shore")) {
    theme <- "Shoreline"
    ### Other ...      
  } else {
    theme <- ""
  }
  
  ## Legend --------------------------------------------------------------------
  ### Species, Includes, KBA
  if (any(startsWith(file_no_ext, c("T_ECCC", "T_IUCN", "T_NSC", "I_", "W_Key")))) {
    legend <- "manual"
    ### LC, KM, Weights  
  } else if (any(startsWith(file_no_ext, c("T_LC", "T_KM", "W_")))) {
    legend <- "continuous"
    ### Other ...    
  } else {
    legend <- ""
  }
  
  ## Values --------------------------------------------------------------------
  ### Species
  if (any(startsWith(file_no_ext, c("T_ECCC", "T_IUCN", "T_NSC")))) {
    if (raster::minValue(wtw_raster) == 0) {
      values <- "0, 1"
    } else {
      values <- "1" # layer covers entire AOI
    }
    ### Includes  
  } else if (startsWith(file_no_ext, "I")) {
    values <- "0, 1"  
    ### KBA  
  } else if (startsWith(file_no_ext, "W_Key")) {
    values <- "0, 1"
    ### Other ...    
  } else {
    values <- ""
  }
  
  ## Color ---------------------------------------------------------------------
  ### ECCC SAR
  if (startsWith(file_no_ext, "T_ECCC_SAR")) {
    if (startsWith(values, "0")) {
      color <- "#00000000, #fb9a99"
    } else {
      color <- "#fb9a99" # layer covers entire AOI
    }
    ### ECCC CH  
  } else if (startsWith(file_no_ext, "T_ECCC_CH")) {
    if (startsWith(values, "0")) {
      color <- "#00000000, #ffed6f"
    } else {
      color <- "#ffed6f" # layer covers entire AOI
    }
    ### IUCN AMPH  
  } else if (startsWith(file_no_ext, "T_IUCN_AMPH")) {
    if (startsWith(values, "0")) {
      color <- "#00000000, #a6cee3"
    } else {
      color <- "#a6cee3" # layer covers entire AOI
    }
    ### IUCN BIRD  
  } else if (startsWith(file_no_ext, "T_IUCN_BIRD")) {
    if (startsWith(values, "0")) {    
      color <- "#00000000, #ff7f00"
    } else {
      color <- "#ff7f00" # layer covers entire AOI
    }
    ### IUCN MAMM  
  } else if (startsWith(file_no_ext, "T_IUCN_MAMM")) {
    if (startsWith(values, "0")) {     
      color <- "#00000000, #b15928"
    } else {
      color <- "#b15928" # layer covers entire AOI
    }
    ### IUCN REPT  
  } else if (startsWith(file_no_ext, "T_IUCN_REPT")) {
    if (startsWith(values, "0")) { 
      color <- "#00000000, #b2df8a"
    } else {
      color <- "#b2df8a" # layer covers entire AOI
    }
    ### NSC SAR  
  } else if (startsWith(file_no_ext, "T_NSC_SAR")) {
    if (startsWith(values, "0")) {     
      color <- "#00000000, #d73027"
    } else {
      color <- "#d73027" # layer covers entire AOI
    }
    ## NSC END  
  } else if (startsWith(file_no_ext, "T_NSC_END")) {
    if (startsWith(values, "0")) { 
      color <- "#00000000, #4575b4"
    } else {
      color <- "#4575b4" # layer covers entire AOI
    }
    ### NSC SPP  
  } else if (startsWith(file_no_ext, "T_NSC_SPP")) {
    if (startsWith(values, "0")) { 
      color <- "#00000000, #e6f598"
    } else {
      color <- "#e6f598" # layer covers entire AOI
    }
    ### LC  
  } else if (startsWith(file_no_ext, "T_LC")) {
    color <- "viridis"
    ### Rivers  
  } else if (startsWith(file_no_ext, "T_KM_R")) {
    color <- "Blues"
    ### Shoreline  
  } else if (startsWith(file_no_ext, "T_KM_S")) {
    color <- "YlOrBr"     
    ### Includes  
  } else if (startsWith(file_no_ext, "I")) {
    color <- "#00000000, #7fbc41"
    ### Carbon  
  } else if (startsWith(file_no_ext, "W_Carbon")) {
    color <- "YlOrBr"    
    ### Climate  
  } else if (startsWith(file_no_ext, "W_Climate")) {
    color <- "magma"
    ### Human Footprint Index  
  } else if (startsWith(file_no_ext, "W_Human")) {
    color <- "rocket"
    ### Freshwater  
  } else if (startsWith(file_no_ext, "W_Freshwater")) {
    color <- "Blues"
    ### Recreation  
  } else if (startsWith(file_no_ext, "W_Recreation")) {
    color <- "Greens"
    ### Connectivity  
  } else if (startsWith(file_no_ext, "W_Connectivity")) {
    color <- "mako"    
    ### KBA  
  } else if (startsWith(file_no_ext, "W_Key")) {
    color <- "#00000000, #1c9099"
    ### Other ...  
  } else {
    color <- ""
  }  
  
  ## LABEL ---------------------------------------------------------------------
  ### Species 
  if (any(startsWith(file_no_ext, c("T_ECCC", "T_IUCN", "T_NSC")))) {
    if (startsWith(values, "0")) {
      labels <- "absence, presence"
    } else {
      labels <- "presence" # layer covers entire AOI
    }
    ### Includes  
  } else if (startsWith(file_no_ext, "I_")) {
    labels <- "not included, included"
    ### KBA  
  } else if (startsWith(file_no_ext, "W_Key")) {
    labels <- "not KBA, KBA" 
    ### Other ...    
  } else {
    labels <- ""
  }   
  
  ## UNITS ---------------------------------------------------------------------
  ### Species, Includes, KBA
  if (any(startsWith(file_no_ext, c("T_ECCC", "T_IUCN", "T_NSC", "I_","W_Key")))) {
    unit <- "km2"
    ### LC  
  } else if (file_no_ext %in% c("T_LC_Forest-lc", "T_LC_Forest-lu", "T_LC_Wetlands", "T_LC_Lakes", "T_LC_Grassland")) {
    unit <- "ha"
    ### KM  
  } else if (file_no_ext %in% c("T_KM_River_length", "T_KM_Shoreline_length")) {
    unit <- "km"       
    ### Carbon potential  
  } else if (startsWith(file_no_ext, "W_Carbon_potential")) {
    unit <- "tonnes/yr"   
    ### Carbon storage  
  } else if (startsWith(file_no_ext, "W_Carbon_storage")) {
    unit <- "tonnes"
    ### Connectivity  
  } else if (startsWith(file_no_ext, "W_Connectivity")) {
    unit <- "current density"    
    ### Climate, HFI  
  } else if (file_no_ext %in% c("W_Climate_forward_velocity", "W_Climate_refugia", "W_Climate_extremes", "W_Human_footprint")) {
    unit <- "index" 
    ### Freshwater, Recreation  
  } else if (any(startsWith(file_no_ext, c("W_Freshwater", "W_Recreation")))) {
    unit <- "ha"      
    ### Other ...  
  } else {
    unit <- ""
  }  
  
  ## PROVENANCE ----------------------------------------------------------------
  provenance <- "national"
  
  ## ORDER ---------------------------------------------------------------------
  order <- "" # manual assignment in csv
  
  ## VISIBLE -------------------------------------------------------------------
  ### Includes
  if (startsWith(file_no_ext, "I_")) {
    visible <- "TRUE"
  } else {
    visible <- "FALSE" 
  }
  
  ## HIDDEN --------------------------------------------------------------------
  hidden <- "FALSE" 
  
  ## GOAL ----------------------------------------------------------------------
  if (type == "theme") {
    goal <- "0.2"  # default 
  } else {
    goal <- ""
  }
  
  ## Append row to data.frame ----
  new_row <- c(type, theme, file, name, legend, values, color, labels, unit, 
               provenance, order, visible, hidden, goal)
  
  df <- structure(rbind(df, new_row), .Names = names(df))
  
  ## Update counter
  counter <- 1 + counter
} 


# Write to CSV ----
write.csv(df, 
          file.path(metadata_folder, paste0(output_metadata_name, "-metadata-NEEDS-QC.csv")),
          row.names = FALSE)

# 4.0 Clear R environment ------------------------------------------------------ 

## End timer
end_time <- Sys.time()
end_time - start_time