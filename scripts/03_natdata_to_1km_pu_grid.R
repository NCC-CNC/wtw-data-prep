# Authors: Richard Schuster & Dan Wismer
#
# Date: September 1st, 2022
#
# Description: This script extracts national data to a 1km pu grid
#
# Inputs:  1. a planning unit raster
#          2. an output folder location
#          3. required R libraries
#
# Outputs: 1. a 1km x 1km raster layer for each variable that intersects 
#             the pu's
#          2. a csv that lists the species that intersect the pu's
#
#===============================================================================
# Start timer
start_time <- Sys.time()

# 1.0 Load packages ------------------------------------------------------------

library(sf)
library(raster)
library(dplyr)
library(prioritizr)
library(sp)
library(stringr)
library(gdalUtilities) 
source("scripts/functions/fct_matrix_intersect.R")
source("scripts/functions/fct_matrix_to_raster.R")


# 2.0 Set up -------------------------------------------------------------------

## Set output folder and PU ----
input_data_path <- "PRZ_TOOL\DATAPREP\data_20220405" # <--- SET PATH TO PREPPED NATIONAL DATA FOLDER
pu_path <- "PU/PU.tif"
pu_data_folder <- "National" # <--- THIS IS THE LOCATION TO STORE THE CLIPPED RASTERS IN THE PROJECT FOLDER


# 3.0 prep folders and PUs -----------------------------------------------------

## Create output folder directory ----
dir.create(file.path(pu_data_folder))
dir.create(file.path(pu_data_folder, "_Tables"))
dir.create(file.path(pu_data_folder, "Excludes"))
dir.create(file.path(pu_data_folder, "Includes"))
dir.create(file.path(pu_data_folder, "Themes"))
dir.create(file.path(pu_data_folder, "Weights"))

dir.create(file.path(pu_data_folder, "Themes", "ECCC_CH"))
dir.create(file.path(pu_data_folder, "Themes", "ECCC_SAR"))
dir.create(file.path(pu_data_folder, "Themes", "IUCN_AMPH"))
dir.create(file.path(pu_data_folder, "Themes", "IUCN_BIRD"))
dir.create(file.path(pu_data_folder, "Themes", "IUCN_MAMM"))
dir.create(file.path(pu_data_folder, "Themes", "IUCN_REPT"))
dir.create(file.path(pu_data_folder, "Themes", "LC"))
dir.create(file.path(pu_data_folder, "Themes", "KM"))
dir.create(file.path(pu_data_folder, "Themes", "NSC_END"))
dir.create(file.path(pu_data_folder, "Themes", "NSC_SAR"))
dir.create(file.path(pu_data_folder, "Themes", "NSC_SPP"))

# Copy / paste LUT ----
LUT <- list.files(file.path(input_data_path, "/national/species"), pattern='.xlsx$|.csv$', full.names = T)
file.copy(LUT, file.path(pu_data_folder, "_Tables"))

## Read-in PU .tiff ----
pu_1km <- raster(pu_path) 
pu_name <- names(pu_1km)
pu_1km0 <- pu_1km 
### Convert pu to all 0's (was needed for mosaic, but now we crop)... keep for now
pu_1km0[pu_1km0 > 0] <- 0 

## Read-in national 1km grid (all of Canada) ----
ncc_1km <- raster(file.path(input_data_path, "national/_nccgrid/NCC_PU.tif"))
ncc_1km_idx <- ncc_1km
ncc_1km_idx[] <- 1:ncell(ncc_1km_idx) # 267,790,000 available planning units

## Align pu to same extent and same number of rows/cols as national grid ----
### get spatial properties of ncc grid
proj4_string <- sp::proj4string(ncc_1km) # projection string
bbox <- raster::bbox(ncc_1km) # bounding box
### variables for gdalwarp
te <- c(bbox[1,1], bbox[2,1], bbox[1,2], bbox[2,2]) # xmin, ymin, xmax, ymax
ts <- c(raster::ncol(ncc_1km), raster::nrow(ncc_1km)) # ncc grid: columns/rows
### gdalUtilities::gdalwarp does not require a local GDAL installation ----
gdalUtilities::gdalwarp(srcfile = pu_path,
                        dstfile = paste0(tools::file_path_sans_ext(pu_path), "_align.tif"),
                        te = te,
                        t_srs = proj4_string,
                        ts = ts,
                        overwrite = TRUE)

## Get aligned planning units ---- 
aoi_pu <- raster(paste0(tools::file_path_sans_ext(pu_path), "_align.tif"))
# Create pu_rij matrix: 11,010,932 planing units activated 
pu_rij <- prioritizr::rij_matrix(ncc_1km, stack(aoi_pu, ncc_1km_idx))
rownames(pu_rij) <- c("AOI", "Idx")


# 4.0 national data to PU -----------------------------------------------------

## ECCC Critical Habitat (theme) ----
natdata_rij <- readRDS(file.path(input_data_path, "national/species/rij_ECCC_CH.rds"))
matrix_overlap <- matrix_intersect(natdata_rij, pu_rij) 
matrix_to_raster(ncc_1km_idx, matrix_overlap, pu_1km0,
                 paste0(pu_data_folder, "/Themes/ECCC_CH"), "T_ECCC_CH_", "INT1U")

## ECCC Species at risk (theme) ----
natdata_rij <- readRDS(file.path(input_data_path, "national/species/rij_ECCC_SAR.rds"))
matrix_overlap <- matrix_intersect(natdata_rij, pu_rij) 
matrix_to_raster(ncc_1km_idx, matrix_overlap, pu_1km0,
                 paste0(pu_data_folder, "/Themes/ECCC_SAR"), "T_ECCC_SAR_", "INT1U")

## IUCN Amphibians (theme) ----
natdata_rij <- readRDS(file.path(input_data_path, "national/species/rij_IUCN_AMPH.rds"))
matrix_overlap <- matrix_intersect(natdata_rij, pu_rij) 
matrix_to_raster(ncc_1km_idx, matrix_overlap, pu_1km0,
                 paste0(pu_data_folder, "/Themes/IUCN_AMPH"), "T_IUCN_AMPH_", "INT1U")

## IUCN Birds (theme) ----
natdata_rij <- readRDS(file.path(input_data_path, "national/species/rij_IUCN_BIRD.rds"))
matrix_overlap <- matrix_intersect(natdata_rij, pu_rij) 
matrix_to_raster(ncc_1km_idx, matrix_overlap, pu_1km0,
                 paste0(pu_data_folder, "/Themes/IUCN_BIRD"), "T_IUCN_BIRD_", "INT1U")

## IUCN Mammals (theme) ----
natdata_rij <- readRDS(file.path(input_data_path, "national/species/rij_IUCN_MAMM.rds"))
matrix_overlap <- matrix_intersect(natdata_rij, pu_rij) 
matrix_to_raster(ncc_1km_idx, matrix_overlap, pu_1km0,
                 paste0(pu_data_folder, "/Themes/IUCN_MAMM"), "T_IUCN_MAMM_", "INT1U")

## IUCN Reptiles (theme) ----
natdata_rij <- readRDS(file.path(input_data_path, "national/species/rij_IUCN_REPT.rds"))
matrix_overlap <- matrix_intersect(natdata_rij, pu_rij) 
matrix_to_raster(ncc_1km_idx, matrix_overlap, pu_1km0,
                 paste0(pu_data_folder, "/Themes/IUCN_REPT"), "T_IUCN_REPT_", "INT1U")

## Nature Serve Canada Endemics (theme) ----
natdata_rij <- readRDS(file.path(input_data_path, "national/species/rij_NSC_END.rds"))
matrix_overlap <- matrix_intersect(natdata_rij, pu_rij) 
matrix_to_raster(ncc_1km_idx, matrix_overlap, pu_1km0,
                 paste0(pu_data_folder, "/Themes/NSC_END"), "T_NSC_END_", "INT1U")

## Nature Serve Canada Species at risk (theme) ----
natdata_rij <- readRDS(file.path(input_data_path, "national/species/rij_NSC_SAR.rds"))
matrix_overlap <- matrix_intersect(natdata_rij, pu_rij) 
matrix_to_raster(ncc_1km_idx, matrix_overlap, pu_1km0,
                 paste0(pu_data_folder, "/Themes/NSC_SAR"), "T_NSC_SAR_", "INT1U")

## Nature Serve Canada Common Species (theme) ----
natdata_rij <- readRDS(file.path(input_data_path, "national/species/rij_NSC_SPP.rds"))
matrix_overlap <- matrix_intersect(natdata_rij, pu_rij) 
matrix_to_raster(ncc_1km_idx, matrix_overlap, pu_1km0,
                 paste0(pu_data_folder, "/Themes/NSC_SPP"), "T_NSC_SPP_", "INT1U")

## Forest - LC (theme) ----
natdata_r <- raster(file.path(input_data_path, "national/forest/FOREST_LC_COMPOSITE_1KM.tif"))
natdata_rij <- prioritizr::rij_matrix(ncc_1km, natdata_r)
rownames(natdata_rij) <- c("Forest-lc")
matrix_overlap  <- matrix_intersect(natdata_rij, pu_rij) 
matrix_to_raster(ncc_1km_idx, matrix_overlap, pu_1km0,
                 paste0(pu_data_folder, "/Themes/LC"), "T_LC_", "INT2U")

## Forest - LU (theme) ----
natdata_r <- raster(file.path(input_data_path, "national/forest/FOREST_LU_COMPOSITE_1KM.tif"))
natdata_rij <- prioritizr::rij_matrix(ncc_1km, natdata_r)
rownames(natdata_rij) <- c("Forest-lu")
matrix_overlap  <- matrix_intersect(natdata_rij, pu_rij) 
matrix_to_raster(ncc_1km_idx, matrix_overlap, pu_1km0,
                 paste0(pu_data_folder, "/Themes/LC"), "T_LC_", "INT2U")

## Grassland (theme) ----
natdata_r <- raster(file.path(input_data_path, "national/grassland/Grassland_AAFC_LUTS_Total_Percent.tif"))
natdata_rij <- prioritizr::rij_matrix(ncc_1km, natdata_r)
rownames(natdata_rij) <- c("Grassland")
matrix_overlap  <- matrix_intersect(natdata_rij, pu_rij) 
matrix_to_raster(ncc_1km_idx, matrix_overlap, pu_1km0,
                 paste0(pu_data_folder, "/Themes/LC"), "T_LC_", "INT2U")

## Lakes (theme) ----
natdata_r <- raster(file.path(input_data_path, "national/water/Lakes_CanVec_50k_ha.tif"))
natdata_rij <- prioritizr::rij_matrix(ncc_1km, natdata_r)
rownames(natdata_rij) <- c("Lakes")
matrix_overlap  <- matrix_intersect(natdata_rij, pu_rij) 
matrix_to_raster(ncc_1km_idx, matrix_overlap, pu_1km0,
                 paste0(pu_data_folder, "/Themes/LC"), "T_LC_", "FLT4S")

## River length (theme) ----
natdata_r <- raster(file.path(input_data_path, "national/water/grid_1km_water_linear_flow_length_1km.tif"))
natdata_rij <- prioritizr::rij_matrix(ncc_1km, natdata_r)
rownames(natdata_rij) <- c("River_length")
matrix_overlap  <- matrix_intersect(natdata_rij, pu_rij) 
matrix_to_raster(ncc_1km_idx, matrix_overlap, pu_1km0,
                 paste0(pu_data_folder, "/Themes/KM"), "T_KM_", "FLT4S")

## Shoreline (theme) ----
natdata_r <- raster(file.path(input_data_path, "national/water/Shoreline.tif"))
natdata_rij <- prioritizr::rij_matrix(ncc_1km, natdata_r)
rownames(natdata_rij) <- c("Shoreline_length")
matrix_overlap  <- matrix_intersect(natdata_rij, pu_rij) 
matrix_to_raster(ncc_1km_idx, matrix_overlap, pu_1km0,
                 paste0(pu_data_folder, "/Themes/KM"), "T_KM_", "FLT4S")

## Wetlands (theme) ----
natdata_r <- raster(file.path(input_data_path, "national/wetlands/Wetland_comb_proj_diss_90m_Arc.tif"))
natdata_rij <- prioritizr::rij_matrix(ncc_1km, natdata_r)
rownames(natdata_rij) <- c("Wetlands")
matrix_overlap  <- matrix_intersect(natdata_rij, pu_rij) 
matrix_to_raster(ncc_1km_idx, matrix_overlap, pu_1km0,
                 paste0(pu_data_folder, "/Themes/LC"), "T_LC_", "FLT4S")

## Carbon storage (weight) ----
natdata_r <- raster(file.path(input_data_path, "national/carbon/Carbon_Mitchell_2021_t.tif"))
natdata_rij <- prioritizr::rij_matrix(ncc_1km, natdata_r)
rownames(natdata_rij) <- c("Carbon_storage")
matrix_overlap  <- matrix_intersect(natdata_rij, pu_rij) 
matrix_to_raster(ncc_1km_idx, matrix_overlap, pu_1km0,
                 paste0(pu_data_folder, "/Weights"), "W_", "FLT4S")

## Carbon potential (weight) ----
natdata_r <- raster(file.path(input_data_path, "national/carbon/Carbon_Potential_NFI_2011_CO2e_t_year.tif"))
natdata_rij <- prioritizr::rij_matrix(ncc_1km, natdata_r)
rownames(natdata_rij) <- c("Carbon_potential")
matrix_overlap  <- matrix_intersect(natdata_rij, pu_rij) 
matrix_to_raster(ncc_1km_idx, matrix_overlap, pu_1km0,
                 paste0(pu_data_folder, "/Weights"), "W_", "FLT4S")

## Climate forward velocity (weight) ----
natdata_r <- raster(file.path(input_data_path, "national/climate/Climate_FwdShortestPath_2080_RCP85.tif"))
natdata_rij <- prioritizr::rij_matrix(ncc_1km, natdata_r)
rownames(natdata_rij) <- c("Climate_shortest_path")
matrix_overlap  <- matrix_intersect(natdata_rij, pu_rij) 
matrix_to_raster(ncc_1km_idx, matrix_overlap, pu_1km0,
                 paste0(pu_data_folder, "/Weights"), "W_", "FLT4S")

## Climate refugia (weight) ----
natdata_r <- raster(file.path(input_data_path, "national/climate/Climate_Refugia_2080_RCP85.tif"))
natdata_rij <- prioritizr::rij_matrix(ncc_1km, natdata_r)
rownames(natdata_rij) <- c("Climate_refugia")
matrix_overlap  <- matrix_intersect(natdata_rij, pu_rij) 
matrix_to_raster(ncc_1km_idx, matrix_overlap, pu_1km0,
                 paste0(pu_data_folder, "/Weights"), "W_", "FLT4S")

## Climate extremes (weight) ----
natdata_r <- raster(file.path(input_data_path, "national/climate/Climate_LaSorte_ExtremeHeatEvents.tif"))
natdata_rij <- prioritizr::rij_matrix(ncc_1km, natdata_r)
rownames(natdata_rij) <- c("Climate_extremes")
matrix_overlap  <- matrix_intersect(natdata_rij, pu_rij) 
matrix_to_raster(ncc_1km_idx, matrix_overlap, pu_1km0,
                 paste0(pu_data_folder, "/Weights"), "W_", "FLT4S")

## Connectivity (weight) ----
natdata_r <- raster(file.path(input_data_path, "national/connectivity/Connectivity_Pither_Current_Density.tif"))
natdata_rij <- prioritizr::rij_matrix(ncc_1km, natdata_r)
rownames(natdata_rij) <- c("Connectivity")
matrix_overlap  <- matrix_intersect(natdata_rij, pu_rij) 
matrix_to_raster(ncc_1km_idx, matrix_overlap, pu_1km0,
                 paste0(pu_data_folder, "/Weights"), "W_", "FLT4S")

## Human footprint (weight) ----
natdata_r <- raster(file.path(input_data_path, "national/disturbance/CDN_HF_cum_threat_20221031_NoData.tif"))
natdata_rij <- prioritizr::rij_matrix(ncc_1km, natdata_r)
rownames(natdata_rij) <- c("Human_footprint")
matrix_overlap  <- matrix_intersect(natdata_rij, pu_rij) 
matrix_to_raster(ncc_1km_idx, matrix_overlap, pu_1km0,
                 paste0(pu_data_folder, "/Weights"), "W_", "FLT4S")

## KBAs (weight) ----
natdata_r <- raster(file.path(input_data_path, "national/kba/KBA.tif"))
natdata_rij <- prioritizr::rij_matrix(ncc_1km, natdata_r)
rownames(natdata_rij) <- c("Key_biodiversity_areas")
matrix_overlap  <- matrix_intersect(natdata_rij, pu_rij) 
matrix_to_raster(ncc_1km_idx, matrix_overlap, pu_1km0,
                 paste0(pu_data_folder, "/Weights"), "W_", "FLT4S")

## Recreation (weight) ----
natdata_r <- raster(file.path(input_data_path, "national/recreation/rec_pro_1a_norm.tif"))
natdata_rij <- prioritizr::rij_matrix(ncc_1km, natdata_r)
rownames(natdata_rij) <- c("Recreation")
matrix_overlap  <- matrix_intersect(natdata_rij, pu_rij) 
matrix_to_raster(ncc_1km_idx, matrix_overlap, pu_1km0,
                 paste0(pu_data_folder, "/Weights"), "W_", "FLT4S")

## Freshwater (weight) ----
natdata_r <- raster(file.path(input_data_path, "national/water/water_provision_2a_norm.tif"))
natdata_rij <- prioritizr::rij_matrix(ncc_1km, natdata_r)
rownames(natdata_rij) <- c("Freshwater")
matrix_overlap  <- matrix_intersect(natdata_rij, pu_rij) 
matrix_to_raster(ncc_1km_idx, matrix_overlap, pu_1km0,
                 paste0(pu_data_folder, "/Weights"), "W_", "FLT4S")

## Protected (include) ----
### Canadian protected and conserved areas database - Terrestrial Biomes (CPCAD) +
### NCC Fee simple (FS) + NCC conservation agreements (CA) 
natdata_r <- raster(file.path(input_data_path, "national/protected/CPCAD_NCC_FS_CA.tif"))
natdata_rij <- prioritizr::rij_matrix(ncc_1km, natdata_r)
rownames(natdata_rij) <- c("Protected")
matrix_overlap  <- matrix_intersect(natdata_rij, pu_rij) 
matrix_to_raster(ncc_1km_idx, matrix_overlap, pu_1km0,
                 paste0(pu_data_folder, "/Includes"), "I_", "INT1U")


# 5.0 Clear R environment ------------------------------------------------------ 

rm(list=ls())
gc()

# End timer
end_time <- Sys.time()
end_time - start_time