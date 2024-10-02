# Authors: Dan Wismer, Marc Edwards & Richard Schuster
#
# Date: June 27, 2024
#
# Description: This script extracts national 1km data to a local 1km pu grid
#
# Inputs:  1. a planning unit raster
#          2. an output folder location
#
# Outputs: 1. a 1km x 1km raster layer for each variable that intersects 
#             the pu's
#
# Tested on R Versions: 4.3.0 and 4.3.1 
#
#===============================================================================
# Start timer
start_time <- Sys.time()

# 1.0 Load packages ------------------------------------------------------------

library(sf)
library(terra)
library(dplyr)
library(prioritizr)
library(stringr)
library(gdalUtilities)
library(Matrix)
source("scripts/functions/fct_matrix_intersect.R")
source("scripts/functions/fct_matrix_to_raster.R")
terra::gdalCache(size = 8000) # set cache to 8gb

# 2.0 Set up -------------------------------------------------------------------


## Nat 1KM data
NAT_1KM <- "C:/Data/PRZ/NAT_DATA/NAT_1KM_20240626" # <--- CHANGE TO YOUR NAT_1KM PATH
## Prepped planning units
PU_TIF <- "C:/Data/PRZ/WTW/SW_ONTARIO_V2/PU/PU.tif" # <--- SET PATH TO PU.tif
## WTW National project path
PRJ_PATH <- "C:/Data/PRZ/WTW/SW_ONTARIO_V2/National" # <--- SET OUTPUT PATH FOR CLIPPED RASTERS. PONT TO "National" FOLDER WITHIN YOUR PROJECT. 

# 3.0 prep folders and PUs -----------------------------------------------------

## Create output folder directory ----
dir.create(file.path(PRJ_PATH))
dir.create(file.path(PRJ_PATH, "_Tables"))
dir.create(file.path(PRJ_PATH, "Excludes"))
dir.create(file.path(PRJ_PATH, "Includes"))
dir.create(file.path(PRJ_PATH, "Themes"))
dir.create(file.path(PRJ_PATH, "Weights"))

dir.create(file.path(PRJ_PATH, "Themes", "ECCC_CH"))
dir.create(file.path(PRJ_PATH, "Themes", "ECCC_SAR"))
dir.create(file.path(PRJ_PATH, "Themes", "IUCN_AMPH"))
dir.create(file.path(PRJ_PATH, "Themes", "IUCN_BIRD"))
dir.create(file.path(PRJ_PATH, "Themes", "IUCN_MAMM"))
dir.create(file.path(PRJ_PATH, "Themes", "IUCN_REPT"))
dir.create(file.path(PRJ_PATH, "Themes", "LC"))
dir.create(file.path(PRJ_PATH, "Themes", "KM"))
dir.create(file.path(PRJ_PATH, "Themes", "NSC_END"))
dir.create(file.path(PRJ_PATH, "Themes", "NSC_SAR"))
dir.create(file.path(PRJ_PATH, "Themes", "NSC_SPP"))

# Copy / paste metadata  ----
file.copy(
  file.path(NAT_1KM, "WTW_NAT_SPECIES_METADATA.xlsx"), 
  file.path(PRJ_PATH, "_Tables")
)

file.copy(
  file.path(NAT_1KM, "WTW_NAT_FEATURES_METADATA.xlsx"), 
  file.path(PRJ_PATH, "_Tables")
)

## Read-in PU .tiff ----
pu_1km <- rast(PU_TIF)
pu_1km_ext <- ext(pu_1km) # get extent

## Read-in national 1km grid (all of Canada) ----
ncc_1km <- rast(file.path(NAT_1KM, "_1km/idx.tif"))
ncc_1km_idx <- terra::init(ncc_1km, fun="cell") # 267,790,000 pu
ncc_1km_idx_NA <- terra::init(ncc_1km_idx, fun=NA)

## Align pu to same extent and same number of rows/cols as national grid ----
### get spatial properties of ncc grid
proj4_string <- terra::crs(ncc_1km,  proj=TRUE) # projection string
bbox <- terra::ext(ncc_1km) # bounding box
### variables for gdalwarp
te <- c(bbox[1], bbox[3], bbox[2], bbox[4]) # xmin, ymin, xmax, ymax
ts <- c(terra::ncol(ncc_1km), terra::nrow(ncc_1km)) # ncc grid: columns/rows
### gdalUtilities::gdalwarp does not require a local GDAL installation ----
gdalUtilities::gdalwarp(srcfile = PU_TIF,
                        dstfile = paste0(tools::file_path_sans_ext(PU_TIF), "_align.tif"),
                        te = te,
                        t_srs = proj4_string,
                        ts = ts,
                        overwrite = TRUE)

## Get aligned planning units ---- 
aoi_pu <- rast(paste0(tools::file_path_sans_ext(PU_TIF), "_align.tif"))
# Create pu_rij matrix: 11,010,932 planing units activated 
pu_rij <- prioritizr::rij_matrix(ncc_1km, c(aoi_pu, ncc_1km_idx))
rownames(pu_rij) <- c("AOI", "Idx")
rm(ncc_1km_idx) %>% gc(verbose = FALSE) # clear some RAM


# 4.0 national data to PU -----------------------------------------------------

## ECCC Critical Habitat (theme) ----
natdata_rij <- readRDS(file.path(NAT_1KM, "biod/RIJ_ECCC_CH.rds"))
matrix_overlap <- matrix_intersect(natdata_rij, pu_rij)
rm(natdata_rij) %>% gc(verbose = FALSE) # clear some RAM
matrix_to_raster(ncc_1km_idx_NA, matrix_overlap, pu_1km_ext, 
                 paste0(PRJ_PATH, "/Themes/ECCC_CH"), "", "INT2U") # no prefix needed

## ECCC Species at risk (theme) ----
natdata_rij <- readRDS(file.path(NAT_1KM, "biod/RIJ_ECCC_SAR.rds"))
matrix_overlap <- matrix_intersect(natdata_rij, pu_rij)
rm(natdata_rij) %>% gc(verbose = FALSE) # clear some RAM
matrix_to_raster(ncc_1km_idx_NA, matrix_overlap, pu_1km_ext, 
                 paste0(PRJ_PATH, "/Themes/ECCC_SAR"), "", "INT2U") # no prefix needed

## IUCN Amphibians (theme) ----
natdata_rij <- readRDS(file.path(NAT_1KM, "biod/RIJ_IUCN_AMPH.rds"))
matrix_overlap <- matrix_intersect(natdata_rij, pu_rij)
rm(natdata_rij) %>% gc(verbose = FALSE) # clear some RAM
matrix_to_raster(ncc_1km_idx_NA, matrix_overlap, pu_1km_ext,
                 paste0(PRJ_PATH, "/Themes/IUCN_AMPH"), "T_NAT_IUCN_AMPH_", "INT1U")

## IUCN Birds (theme) ----
natdata_rij <- readRDS(file.path(NAT_1KM, "biod/RIJ_IUCN_BIRD.rds"))
matrix_overlap <- matrix_intersect(natdata_rij, pu_rij)
rm(natdata_rij) %>% gc(verbose = FALSE) # clear some RAM
matrix_to_raster(ncc_1km_idx_NA, matrix_overlap, pu_1km_ext,
                 paste0(PRJ_PATH, "/Themes/IUCN_BIRD"), "T_NAT_IUCN_BIRD_", "INT1U")

## IUCN Mammals (theme) ----
natdata_rij <- readRDS(file.path(NAT_1KM, "biod/RIJ_IUCN_MAMM.rds"))
matrix_overlap <- matrix_intersect(natdata_rij, pu_rij)
rm(natdata_rij) %>% gc(verbose = FALSE) # clear some RAM
matrix_to_raster(ncc_1km_idx_NA, matrix_overlap, pu_1km_ext,
                 paste0(PRJ_PATH, "/Themes/IUCN_MAMM"), "T_NAT_IUCN_MAMM_", "INT1U")

## IUCN Reptiles (theme) ----
natdata_rij <- readRDS(file.path(NAT_1KM, "biod/RIJ_IUCN_REPT.rds"))
matrix_overlap <- matrix_intersect(natdata_rij, pu_rij)
rm(natdata_rij) %>% gc(verbose = FALSE) # clear some RAM
matrix_to_raster(ncc_1km_idx_NA, matrix_overlap, pu_1km_ext,
                 paste0(PRJ_PATH, "/Themes/IUCN_REPT"), "T_NAT_IUCN_REPT_", "INT1U")

## Nature Serve Canada Endemics (theme) ----
natdata_rij <- readRDS(file.path(NAT_1KM, "biod/RIJ_NSC_END.rds"))
matrix_overlap <- matrix_intersect(natdata_rij, pu_rij)
rm(natdata_rij) %>% gc(verbose = FALSE) # clear some RAM
matrix_to_raster(ncc_1km_idx_NA, matrix_overlap, pu_1km_ext,
                 paste0(PRJ_PATH, "/Themes/NSC_END"), "T_NAT_NSC_END_", "INT1U")

## Nature Serve Canada Species at risk (theme) ----
natdata_rij <- readRDS(file.path(NAT_1KM, "biod/RIJ_NSC_SAR.rds"))
matrix_overlap <- matrix_intersect(natdata_rij, pu_rij) 
rm(natdata_rij) %>% gc(verbose = FALSE) # clear some RAM
matrix_to_raster(ncc_1km_idx_NA, matrix_overlap, pu_1km_ext,
                 paste0(PRJ_PATH, "/Themes/NSC_SAR"), "T_NAT_NSC_SAR_", "INT1U")

## Nature Serve Canada Common Species (theme) ----
natdata_rij <- readRDS(file.path(NAT_1KM, "biod/RIJ_NSC_SPP.rds"))
matrix_overlap <- matrix_intersect(natdata_rij, pu_rij)
rm(natdata_rij) %>% gc(verbose = FALSE) # clear some RAM
matrix_to_raster(ncc_1km_idx_NA, matrix_overlap, pu_1km_ext,
                 paste0(PRJ_PATH, "/Themes/NSC_SPP"), "T_NAT_NSC_SPP_", "INT1U")

## Forest - LC (theme) ----
natdata_r <- rast(file.path(NAT_1KM, "habitat/forest_lc.tif"))
natdata_rij <- prioritizr::rij_matrix(ncc_1km, natdata_r)
rownames(natdata_rij) <- c("Forest-lc")
matrix_overlap  <- matrix_intersect(natdata_rij, pu_rij)
rm(natdata_rij) # clear some RAM
matrix_to_raster(ncc_1km_idx_NA, matrix_overlap, pu_1km_ext,
                 paste0(PRJ_PATH, "/Themes/LC"), "T_NAT_LC_", "INT2U")

## Grassland (theme) ----
natdata_r <- rast(file.path(NAT_1KM, "habitat/grass.tif"))
natdata_rij <- prioritizr::rij_matrix(ncc_1km, natdata_r)
rownames(natdata_rij) <- c("Grassland")
matrix_overlap  <- matrix_intersect(natdata_rij, pu_rij) 
rm(natdata_rij) # clear some RAM
matrix_to_raster(ncc_1km_idx_NA, matrix_overlap, pu_1km_ext,
                 paste0(PRJ_PATH, "/Themes/LC"), "T_NAT_LC_", "INT2U")

## Lakes (theme) ----
natdata_r <- rast(file.path(NAT_1KM, "habitat/lakes.tif"))
natdata_rij <- prioritizr::rij_matrix(ncc_1km, natdata_r)
rownames(natdata_rij) <- c("Lakes")
matrix_overlap  <- matrix_intersect(natdata_rij, pu_rij)
rm(natdata_rij) # clear some RAM
matrix_to_raster(ncc_1km_idx_NA, matrix_overlap, pu_1km_ext,
                 paste0(PRJ_PATH, "/Themes/LC"), "T_NAT_LC_", "FLT4S")

## River length (theme) ----
natdata_r <- rast(file.path(NAT_1KM, "habitat/river.tif"))
natdata_rij <- prioritizr::rij_matrix(ncc_1km, natdata_r)
rownames(natdata_rij) <- c("River_length")
matrix_overlap  <- matrix_intersect(natdata_rij, pu_rij) 
rm(natdata_rij) # clear some RAM
matrix_to_raster(ncc_1km_idx_NA, matrix_overlap, pu_1km_ext,
                 paste0(PRJ_PATH, "/Themes/KM"), "T_NAT_KM_", "FLT4S")

## Shoreline (theme) ----
natdata_r <- rast(file.path(NAT_1KM, "habitat/shore.tif"))
natdata_rij <- prioritizr::rij_matrix(ncc_1km, natdata_r)
rownames(natdata_rij) <- c("Shoreline_length")
matrix_overlap  <- matrix_intersect(natdata_rij, pu_rij) 
rm(natdata_rij) # clear some RAM
matrix_to_raster(ncc_1km_idx_NA, matrix_overlap, pu_1km_ext,
                 paste0(PRJ_PATH, "/Themes/KM"), "T_NAT_KM_", "FLT4S")

## Wetlands (theme) ----
natdata_r <- rast(file.path(NAT_1KM, "habitat/wet.tif"))
natdata_rij <- prioritizr::rij_matrix(ncc_1km, natdata_r)
rownames(natdata_rij) <- c("Wetlands")
matrix_overlap  <- matrix_intersect(natdata_rij, pu_rij)
rm(natdata_rij) # clear some RAM
matrix_to_raster(ncc_1km_idx_NA, matrix_overlap, pu_1km_ext,
                 paste0(PRJ_PATH, "/Themes/LC"), "T_NAT_LC_", "FLT4S")

## Carbon storage (weight) ----
natdata_r <- rast(file.path(NAT_1KM, "carbon/carbon_s.tif"))
natdata_rij <- prioritizr::rij_matrix(ncc_1km, natdata_r)
rownames(natdata_rij) <- c("Carbon_storage")
matrix_overlap  <- matrix_intersect(natdata_rij, pu_rij) 
rm(natdata_rij) # clear some RAM
matrix_to_raster(ncc_1km_idx_NA, matrix_overlap, pu_1km_ext,
                 paste0(PRJ_PATH, "/Weights"), "W_NAT_", "FLT4S")

## Carbon potential (weight) ----
natdata_r <- rast(file.path(NAT_1KM, "carbon/carbon_p.tif"))
natdata_rij <- prioritizr::rij_matrix(ncc_1km, natdata_r)
rownames(natdata_rij) <- c("Carbon_potential")
matrix_overlap  <- matrix_intersect(natdata_rij, pu_rij) 
rm(natdata_rij) # clear some RAM
matrix_to_raster(ncc_1km_idx_NA, matrix_overlap, pu_1km_ext,
                 paste0(PRJ_PATH, "/Weights"), "W_NAT_", "FLT4S")

## Climate forward velocity (weight) ----
natdata_r <- rast(file.path(NAT_1KM, "climate/climate_c.tif"))
natdata_rij <- prioritizr::rij_matrix(ncc_1km, natdata_r)
rownames(natdata_rij) <- c("Climate_shortest_path")
matrix_overlap  <- matrix_intersect(natdata_rij, pu_rij)
rm(natdata_rij) # clear some RAM
matrix_to_raster(ncc_1km_idx_NA, matrix_overlap, pu_1km_ext,
                 paste0(PRJ_PATH, "/Weights"), "W_NAT_", "FLT4S")

## Climate refugia (weight) ----
natdata_r <- rast(file.path(NAT_1KM, "climate/climate_r.tif"))
natdata_rij <- prioritizr::rij_matrix(ncc_1km, natdata_r)
rownames(natdata_rij) <- c("Climate_refugia")
matrix_overlap  <- matrix_intersect(natdata_rij, pu_rij) 
rm(natdata_rij) # clear some RAM
matrix_to_raster(ncc_1km_idx_NA, matrix_overlap, pu_1km_ext,
                 paste0(PRJ_PATH, "/Weights"), "W_NAT_", "FLT4S")

## Climate extremes (weight) ----
natdata_r <- rast(file.path(NAT_1KM, "climate/climate_e.tif"))
natdata_rij <- prioritizr::rij_matrix(ncc_1km, natdata_r)
rownames(natdata_rij) <- c("Climate_extremes")
matrix_overlap  <- matrix_intersect(natdata_rij, pu_rij) 
rm(natdata_rij) # clear some RAM
matrix_to_raster(ncc_1km_idx_NA, matrix_overlap, pu_1km_ext,
                 paste0(PRJ_PATH, "/Weights"), "W_NAT_", "FLT4S")

## Connectivity (weight) ----
natdata_r <- rast(file.path(NAT_1KM, "connect/connect.tif"))
natdata_rij <- prioritizr::rij_matrix(ncc_1km, natdata_r)
rownames(natdata_rij) <- c("Connectivity")
matrix_overlap  <- matrix_intersect(natdata_rij, pu_rij) 
rm(natdata_rij) # clear some RAM
matrix_to_raster(ncc_1km_idx_NA, matrix_overlap, pu_1km_ext,
                 paste0(PRJ_PATH, "/Weights"), "W_NAT_", "FLT4S")

## Human footprint (weight) ----
natdata_r <- rast(file.path(NAT_1KM, "threats/hfi.tif"))
natdata_rij <- prioritizr::rij_matrix(ncc_1km, natdata_r)
rownames(natdata_rij) <- c("Human_footprint")
matrix_overlap  <- matrix_intersect(natdata_rij, pu_rij) 
rm(natdata_rij) # clear some RAM
matrix_to_raster(ncc_1km_idx_NA, matrix_overlap, pu_1km_ext,
                 paste0(PRJ_PATH, "/Weights"), "W_NAT_", "FLT4S")

## KBAs (weight) ----
natdata_r <- rast(file.path(NAT_1KM, "biod/kba.tif"))
natdata_rij <- prioritizr::rij_matrix(ncc_1km, natdata_r)
rownames(natdata_rij) <- c("Key_biodiversity_areas")
matrix_overlap  <- matrix_intersect(natdata_rij, pu_rij) 
rm(natdata_rij) # clear some RAM
matrix_to_raster(ncc_1km_idx_NA, matrix_overlap, pu_1km_ext,
                 paste0(PRJ_PATH, "/Weights"), "W_NAT_", "FLT4S")

## Recreation (weight) ----
natdata_r <- rast(file.path(NAT_1KM, "eservices/rec.tif"))
natdata_rij <- prioritizr::rij_matrix(ncc_1km, natdata_r)
rownames(natdata_rij) <- c("Recreation")
matrix_overlap  <- matrix_intersect(natdata_rij, pu_rij) 
rm(natdata_rij) # clear some RAM
matrix_to_raster(ncc_1km_idx_NA, matrix_overlap, pu_1km_ext,
                 paste0(PRJ_PATH, "/Weights"), "W_NAT_", "FLT4S")

## Freshwater (weight) ----
natdata_r <- rast(file.path(NAT_1KM, "eservices/freshw.tif"))
natdata_rij <- prioritizr::rij_matrix(ncc_1km, natdata_r)
rownames(natdata_rij) <- c("Freshwater")
matrix_overlap  <- matrix_intersect(natdata_rij, pu_rij)
rm(natdata_rij) # clear some RAM
matrix_to_raster(ncc_1km_idx_NA, matrix_overlap, pu_1km_ext,
                 paste0(PRJ_PATH, "/Weights"), "W_NAT_", "FLT4S")

## Protected (include) ----
### Canadian protected and conserved areas database - Terrestrial Biomes (CPCAD) +
### NCC Fee simple (FS) + NCC conservation agreements (CA) 
natdata_r <- rast(file.path(NAT_1KM, "cons/cons.tif"))
natdata_rij <- prioritizr::rij_matrix(ncc_1km, natdata_r)
rownames(natdata_rij) <- c("Protected")
matrix_overlap  <- matrix_intersect(natdata_rij, pu_rij) 
rm(natdata_rij) # clear some RAM
matrix_to_raster(ncc_1km_idx_NA, matrix_overlap, pu_1km_ext,
                 paste0(PRJ_PATH, "/Includes"), "I_NAT_", "INT1U")


# 5.0 Clear R environment ------------------------------------------------------ 

# End timer
end_time <- Sys.time()
end_time - start_time

# Remove objects
rm(list=ls())
gc()
