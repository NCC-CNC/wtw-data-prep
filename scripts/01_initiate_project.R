#
# Authors: Marc Edwards
#
# Date: October 3rd, 2024
#
# Description: This script sets up the folder structure for generating input 
#              data for a Where To Work project
#
# Inputs:  1. The project folder path
#          2. An AOI shapefile
#          3. The data type for the project (National or regional)
#
# Outputs: 1. Project folder structure
#
# Tested on R Versions: 4.4.1
#
#===============================================================================


# See https://github.com/NCC-CNC/wtw-data-prep for an explanation of the
# various workflows

# 1.0 Install and load required packages ---------------------------------------

## Package names
packages <- c(
  "dplyr", 
  "gdalUtilities",
  "prioritizr",
  "sf",
  "stringr", 
  "terra", 
  "tibble", 
  "readr", 
  "readxl"
)

## Install packages not yet installed
installed_packages <- packages %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(packages[!installed_packages])
}

## load packages
library(sf)

# 2.0 Set up -------------------------------------------------------------------

# Set project parameters
PRJ_FOLDER <- "C:/Data/PRZ/WTW/SW_ONTARIO_V3" # <--- CHANGE TO YOUR ROOT PROJECT FOLDER
COPY_AOI_SHP <- "" # <--- CHANGE TO LOCATION OF AOI.shp. LEAVE STRING EMPTY IF YOU RATHER COPY MANUALLY.
PROJECT_TYPE <- "NATIONAL" # NATIONAL or REGIONAL or BOTH


# 3.0 Processing ----------------------------------------------------------------

# create folder structure
dir.create(file.path(project_folder, "PU"), recursive = TRUE)
dir.create(file.path(project_folder, "scripts"), recursive = TRUE)
dir.create(file.path(project_folder, "Tiffs"), recursive = TRUE)
dir.create(file.path(project_folder, "WTW/metadata"), recursive = TRUE)

if(PROJECT_TYPE == "NATIONAL"){
  dir.create(file.path(project_folder, "National"), recursive = TRUE)
}
if(PROJECT_TYPE == "REGIONAL"){
  dir.create(file.path(project_folder, "Regional"), recursive = TRUE)
}
if(PROJECT_TYPE == "BOTH"){
  dir.create(file.path(project_folder, "Regional"), recursive = TRUE)
  dir.create(file.path(project_folder, "National"), recursive = TRUE)
}

# Copy AOI into PU folder
if (COPY_AOI_SHP != "") {
  x <- st_read(aoi_shp)
  st_write(x, file.path(project_folder, "PU/AOI.shp"), append = FALSE)  
}
