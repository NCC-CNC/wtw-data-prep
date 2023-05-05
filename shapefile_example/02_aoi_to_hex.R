#
# Authors: Marc Edwards
#
# Date: May 3th, 2023
#
# Description: This script creates a set of hexagonal PUs as an example of
# planning units that require the shapefile format
#
#===============================================================================

# 1.0 Load packages ------------------------------------------------------------

library(dplyr)
library(sf)
library(terra)


# 2.0 Set up -------------------------------------------------------------------

aoi_shp <- "PU/AOI.shp" # <- CHANGE TO YOUR SHP PATH
cell_size <- 50000 # <- CHANGE TO YOUR GRID SIZE IN UNITS MATCHING PROJECTION
out_dir <- "PU"


# 3.0 Create vector grid -------------------------------------------------------

# Read-in boundary shapefile
boundary <- read_sf(aoi_shp)

# Make grid
grid_sf <- sf::st_make_grid(boundary, cellsize = cell_size, what = 'polygons', square = FALSE)

# select cells intersecting boundary polygon
x <- st_intersects(grid_sf, boundary)
grid_sf_sub <- grid_sf[lengths(x) > 0]
grid_sf <- sf::st_sf(geometry = grid_sf_sub, data.frame('PUID' = 1:length(grid_sf_sub)))

# save shp
st_write(grid_sf, file.path(out_dir, "PU.shp"), append=FALSE)
