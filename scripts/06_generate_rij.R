#
# Authors: Marc Edwards and Dan Wismer
#
# Date: June 20 2023
#
# Description: This script converts the Tiffs used to generate WTW input data
#              into an rij matrix for use in other workflows
#
# Inputs:  1. Planning unit raster
#          2. A folder of rasters (themes, weights, includes and excludes) 
#             that all have the same spatial properties (cell size, extent, CRS)
#
# Outputs: 1. A set of .rds spare matrices describing the amount of each feature
#             in each planning unit
#
#===============================================================================
## Start timer
start_time <- Sys.time()

# 1.0 Load packages ------------------------------------------------------------

library(terra)
library(prioritizr)


# 2.0 Setup --------------------------------------------------------------------

# planning units
pu_path <- "PU/PU.tif"
pu <- rast(pu_path)

## Set path where rasters are located
tiffs_path <- "Tiffs"

# set folder to save output .rds files
out_path <- "RIJ"

# make output folder
dir.create(out_path)


# 3.1 Parse tiffs --------------------------------------------------------------

# Parse tiffs file names into multiple vectors, each vector will be converted
# into a separate .rds sparse matrix
# Using Themes, Includes, Weights as an example here

# vectors of tiffs
tiffs_T <- list.files(tiffs_path,  pattern = "^T_.*tif$|tiff$", full.names = TRUE)
tiffs_W <- list.files(tiffs_path,  pattern = "^W_.*tif$|tiff$", full.names = TRUE)
tiffs_I <- list.files(tiffs_path,  pattern = "^I_.*tif$|tiff$", full.names = TRUE)

# combine into a list of vectors, list element names will become .rds file names
l <- list(tiffs_T, tiffs_I, tiffs_W)
names(l) <- c("themes", "includes", "weights")


# 3.2 Generate matrices --------------------------------------------------------

# Loop over list
for(i in seq_along(l)){
  
  # generate sparse matrix
  rij <- rij_matrix(pu,  rast(l[[i]]))
  
  # save as rds
  saveRDS(rij, file.path(out_path, paste0(names(l)[i], ".rds")), compress = TRUE)
}
