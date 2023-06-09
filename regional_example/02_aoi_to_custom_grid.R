#
# Authors: Marc Edwards
#
# Date: April 4th, 2023
#
# Description: This script creates a custom grid covering an AOI. Output 
#              projections match the input AOI shapefile
#
# Inputs:  1. An AOI shapefile
#          2. The grid size in units matching the AOI projection
#          3. The output folder
#
# Outputs: 1. Custom vector grid with PUID 
#          2. Custom raster grid (values are all 1)
#          3. Custom raster grid (values are all 0)

# NOTE: this can take a while to run. On my machine, ~10 mins for a PU grid 
# with ~130,000 cells.
#===============================================================================

# 1.0 Load packages ------------------------------------------------------------

library(dplyr)
library(sf)
library(terra)


# 2.0 Set up -------------------------------------------------------------------

aoi_shp <- "PU/AOI.shp" # <- CHANGE TO YOUR SHP PATH
grid_size <- 10000 # <- CHANGE TO YOUR GRID SIZE IN UNITS MATCHING PROJECTION


out_dir <- "PU"


# 3.0 Create vector grid -------------------------------------------------------

# Read-in boundary shapefile
boundary <- read_sf(aoi_shp)

# Make grid
grid_sf <- sf::st_make_grid(boundary, cellsize = c(grid_size, grid_size), what = 'polygons')

# select cells intersecting boundary polygon
x <- st_intersects(grid_sf, boundary)
grid_sf_sub <- grid_sf[lengths(x) > 0]
grid_sf <- sf::st_sf(geometry = grid_sf_sub, data.frame('PUID' = 1:length(grid_sf_sub)))

# save shp
st_write(grid_sf, file.path(out_dir, "PU.shp"), append=FALSE)


# 4.0 Create raster grid -------------------------------------------------------

# Create raster template matching vector grid extent
r_pu_template <- terra::rast(terra::vect(grid_sf), res = grid_size)

# Rasterize vector grid, values are all 1
r_pu1 <- grid_sf %>%
  mutate(one = 1) %>%
  terra::vect() %>%
  terra::rasterize(r_pu_template, "one")
names(r_pu1) <- "pu"

# make a version where values are all zero
r_pu0 <- r_pu1
r_pu0[r_pu0 == 1] <- 0

# save
terra::writeRaster(r_pu1, file.path(out_dir, "PU.tif"), datatype = "INT1U", overwrite = TRUE)
terra::writeRaster(r_pu0, file.path(out_dir, "PU0.tif"), datatype = "INT1U", overwrite = TRUE)