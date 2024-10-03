#
# Authors: Marc Edwards
#
# Date: April 4th, 2023
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
# Tested on R Versions: 4.3.0
#
#===============================================================================


# See https://github.com/NCC-CNC/wtw-data-prep for an explanation of the
# various workflows

# 1.0 Install required packages ------------------------------------------------------------

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


# 2.0 Load packages ------------------------------------------------------------

library(sf)


# 3.0 Set up -------------------------------------------------------------------

# Set project parameters
project_folder <- "../New_Brunswick_test"
aoi_shp <- "../New_Brunswick_test/input_data/geonb_provinciallimits-limitesprovinciales.shp"
project_data_type <- "REGIONAL" # NATIONAL or REGIONAL or BOTH


# 4.0 Processing ----------------------------------------------------------------

# create folder structure
dir.create(file.path(project_folder, "PU"), recursive = TRUE)
dir.create(file.path(project_folder, "scripts"), recursive = TRUE)
dir.create(file.path(project_folder, "Tiffs"), recursive = TRUE)
dir.create(file.path(project_folder, "WTW/metadata"), recursive = TRUE)

if(project_data_type == "NATIONAL"){
  dir.create(file.path(project_folder, "National"), recursive = TRUE)
}
if(project_data_type == "REGIONAL"){
  dir.create(file.path(project_folder, "Regional"), recursive = TRUE)
}
if(project_data_type == "BOTH"){
  dir.create(file.path(project_folder, "Regional"), recursive = TRUE)
  dir.create(file.path(project_folder, "National"), recursive = TRUE)
}

# Copy AOI into PU folder
x <- st_read(aoi_shp)
st_write(x, file.path(project_folder, "PU/AOI.shp"), append = FALSE)