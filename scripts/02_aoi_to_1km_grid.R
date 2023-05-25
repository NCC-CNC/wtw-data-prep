#
# Author: Dan Wismer
#
# Date: March 29th, 2023
#
# Description: Generates vector and raster 1km PU's from a boundary shapefile. 
#              Outputs take the extent of the input shapefile boundary.
#
# Inputs:  1. Output folder location
#          2. Input shapefile boundary
#          3. Constant_1KM_IDX.tif; The the NCC constant grid where each cell 
#             value is the index (4700 rows, 5700 cols, 26790000 cells, 
#             Canada_Albers_WGS_1984).
#
# Outputs: 1. 1km vector grid with NCCID and PUID 
#          2. 1km raster grid (values are all 1)
#          3. 1km raster grid (values are all 0)
#
#===============================================================================
# Start timer
start_time <- Sys.time()

# 1.0 Load packages ------------------------------------------------------------

library(raster)
library(terra)
library(sf)
library(fasterize)
library(dplyr)


# 2.0 Set up -------------------------------------------------------------------

# Input boundary shapefile path
SHP <- "PU/AOI.shp" # <- CHANGE TO YOUR SHP PATH

# Output folder path to save PU.shp, PU.tif and PU0.tif
OUTPUT <- "PU" # <- CHANGE TO YOUR OUTPUT FOLDER PATH

# Read-in constant 1km raster grid
CONSTANT_1KM <- raster("data/Constant_1KM_IDX.tif") # <- CHANGE TO YOUR GRID PATH


# 3.0 Processing ---------------------------------------------------------------

# Read-in boundary shapefile
Boundary <- read_sf(SHP) %>% 
  st_transform(crs = st_crs(CONSTANT_1KM))

# Fasterize boundary polygon: 4700 rows, 5700 cols, 26790000 cells
pu_1km <- Boundary %>%
  mutate(BURN = 1) %>%
  st_buffer(1000) %>% # buffer by 1km
  fasterize(CONSTANT_1KM, "BURN")

# Raster 1km grid, cell values are NCC indexes, mask values to boundary
r_pu <- terra::mask(terra::rast(pu_1km * CONSTANT_1KM), terra::vect(Boundary)) 

# Vector 1km grid
v_pu <- sf::st_as_sf(terra::as.polygons(r_pu)) %>%
  rename(NCCID = layer) %>%
  mutate(PUID = row_number())
write_sf(v_pu, file.path(OUTPUT, "PU.shp"), overwrite = TRUE) 

# Create raster template matching vector grid extent
r_pu_template <- terra::rast(terra::vect(v_pu), res = 1000)

# Rasterize vector grid, values are all 1
r_pu <- terra::rasterize(terra::vect(v_pu), r_pu_template, 1)
terra::writeRaster(r_pu, file.path(OUTPUT, "PU.tif"), datatype = "INT1U", overwrite = TRUE)

# Convert all cell values to 0
r_pu[r_pu > 0] <- 0
terra::writeRaster(r_pu, file.path(OUTPUT, "PU0.tif"), datatype = "INT1U", overwrite = TRUE)


# End timer
end_time <- Sys.time()
end_time - start_time