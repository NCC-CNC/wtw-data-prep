# Authors: Dan Wismer & Marc Edwards
#
# Date: Sept 18th, 2023
#
# Description: Summarizes national data in tiff folder
#
# Inputs:  1. root folders 
#          2. path for species .csv 
#
# Outputs: 1. a csv that lists metadata on each feature such as total area and 
#             % protected inside and outside of AOI
#
# Tested on R Versions: 4.3.0
#
#===============================================================================
# Start timer
start_time <- Sys.time()

# Load packages ---- 
library(dplyr)
library(readr)
library(readxl)
library(stringr)
library(terra)

## Set folder paths ----
PRJ_PATH <- "C:/Data/PRZ/WTW/SW_ONTARIO_V2" # <--- CHANGE TO LOCAL WTW PROJECT

tif_path <- file.path(PRJ_PATH, "Tiffs")
tbl_path <- file.path(PRJ_PATH, "National/_Tables")

## Set output csv ----
output_csv <- file.path(PRJ_PATH, "Tiffs/METADATA.csv")

# Read-in metadata xlsx's ----
## species
ECCC_CH_META <- read_excel(file.path(tbl_path,  "WTW_NAT_SPECIES_METADATA.xlsx"), sheet = 1)
ECCC_SAR_META <- read_excel(file.path(tbl_path,  "WTW_NAT_SPECIES_METADATA.xlsx"), sheet = 2)
IUCN_AMPH_META <- read_excel(file.path(tbl_path,  "WTW_NAT_SPECIES_METADATA.xlsx"), sheet = 3)
IUCN_BIRD_META <- read_excel(file.path(tbl_path,  "WTW_NAT_SPECIES_METADATA.xlsx"), sheet = 4)
IUCN_MAMM_META <- read_excel(file.path(tbl_path,  "WTW_NAT_SPECIES_METADATA.xlsx"), sheet = 5)
IUCN_REPT_META <- read_excel(file.path(tbl_path,  "WTW_NAT_SPECIES_METADATA.xlsx"), sheet = 6)
NSC_END_META <- read_excel(file.path(tbl_path,  "WTW_NAT_SPECIES_METADATA.xlsx"), sheet = 7)
NSC_SAR_META <- read_excel(file.path(tbl_path,  "WTW_NAT_SPECIES_METADATA.xlsx"), sheet = 8)
NSC_SPP_META <- read_excel(file.path(tbl_path,  "WTW_NAT_SPECIES_METADATA.xlsx"), sheet = 9)
## other national themes, weights and includes
FEATURES_META <- read_excel(file.path(tbl_path,  "WTW_NAT_FEATURES_METADATA.xlsx"))

# List files in Tiffs folder ----
tif_lst <- list.files(
  tif_path, pattern='.tif$', full.names = TRUE, recursive = FALSE
)

# List includes ----
include_lst <- list.files(
  tif_path, pattern='^I.*\\.tif$', full.names = TRUE, recursive = FALSE
)

# Mosaic includes into one raster ----
includes <- terra::mosaic(sprc(rast(include_lst)), fun = "max")

# Build empty df ----
df <- data.frame(
  Source = character(), # source
  Type = character(),   # theme, weight, include or exclude
  File = character(),   # file name
  Provenance = character(), # national or regional
  Theme = character(), # layer theme
  Sci_Name = character(), # scientific name
  Common_Name = character(), # common name
  CA_Total_Km2 = numeric(), # total range / AOH area in Canada
  CA_Protected_Km2 = numeric(), # total range / AOH protected in Canada
  CA_Pct_Protected = numeric(), # % total range / AOH protected protected in Canada
  Goal = numeric(), # species goal
  WTW_Total_Km2 = numeric(), # total range / AOH area in WTW project
  WTW_Protected_Km2 = numeric(), # total range / AOH protected in WTW project
  WTW_Pct_Protected = numeric() # % total range / AOH protected protected in WTW project
)

# Populate species df ----
for (i in seq_along(tif_lst)) {
  
  ## read-in raster
  wtw_raster <- rast(tif_lst[i])
  
  ## file
  file_no_ext <- paste0(tools::file_path_sans_ext(basename(tif_lst[i])))
  file <-  paste0(file_no_ext, ".tif")
  
  ## message
  print(paste0(file, " (", i, "/", length(tif_lst), ")"))
  
  ## get metadata associated with file name
  if (file %in% ECCC_CH_META$File) {
    # ECCC_CH
    wtw_meta <- ECCC_CH_META
  } else if (file %in% ECCC_SAR_META$File) {
    # ECCC_SAR
    wtw_meta <- ECCC_SAR_META
  } else if (file %in% IUCN_AMPH_META$File) {
    # IUCN_AMPH
    wtw_meta <- IUCN_AMPH_META
  } else if (file %in% IUCN_BIRD_META$File) {
    # IUCN_BIRD
    wtw_meta <- IUCN_BIRD_META
  } else if (file %in% IUCN_MAMM_META$File) {
    # IUCN_MAMM
    wtw_meta <- IUCN_MAMM_META
  } else if (file %in% IUCN_REPT_META$File) {
    # IUCN_REPT
    wtw_meta <- IUCN_REPT_META
  } else if (file %in% NSC_END_META$File) {
    # NSC_END
    wtw_meta <- NSC_END_META
  } else if (file %in% NSC_SAR_META$File) {
    # NSC_SAR
    wtw_meta <- NSC_SAR_META
  } else if (file %in% NSC_SPP_META$File) {
    # NSC_SPP
    wtw_meta <- NSC_SPP_META
    # NON SPECIES DATA
  } else  if (file %in% FEATURES_META$File) {
    wtw_meta <- FEATURES_META
  } else {
    # REGIONAL DATA or NON SPECIES DATA
    wtw_meta <- NULL
  }
  
  ## process National species ----
  if (!is.null(wtw_meta)) {
   
    ### return a single row
    wtw_meta_row <- wtw_meta %>% filter(File == file)
    
    ### get source
    source <- wtw_meta_row$Source
    ### get type
    type <- suppressWarnings(ifelse(is.null(wtw_meta_row$Type), "theme", wtw_meta_row$Type))
    ### get provenance
    prv <- "national"
    ### get theme
    theme <- wtw_meta_row$Theme   
    ### get file
    file <- wtw_meta_row$File
    ### get sci name
    sci <- suppressWarnings(ifelse(is.null(wtw_meta_row$Sci_Name), "", wtw_meta_row$Sci_Name))
    ### get common name
    com <- suppressWarnings(ifelse(is.null(wtw_meta_row$Common_Name), "", wtw_meta_row$Common_Name))
    ### get total range / AOH area in Canada
    ca_km2 <- suppressWarnings(ifelse(is.null(wtw_meta_row$Total_Km2), "", wtw_meta_row$Total_Km2))
    ### get range / AOH protected in Canada
    ca_i <- suppressWarnings(ifelse(is.null(wtw_meta_row$Protected_Km2), "", wtw_meta_row$Protected_Km2))
    ### get range / AOH % protected in Canada
    ca_pct_i <- suppressWarnings(ifelse(is.null(wtw_meta_row$Pct_Protected), "", wtw_meta_row$Pct_Protected))
    ### get goal
    goal <- suppressWarnings(ifelse(is.null(wtw_meta_row$Goal), "", wtw_meta_row$Goal))
  }
  
  ## get range / AOH area in WTW project
  prj_km2 <- terra::global(wtw_raster, fun="sum", na.rm=TRUE)[[1]]
  if (source %in% c("ECCC_CH", "ECCC_SAR")) {
    prj_km2 <- prj_km2 / 100 
  } 
  
  ## get range / AOH area project WTW project
  prj_i <- terra::global(wtw_raster * includes, fun="sum", na.rm=TRUE)[[1]]
  if (source %in% c("ECCC_CH", "ECCC_SAR")) {
    prj_i <- prj_i / 100 
  } 
  
  ## get range / AOH % project WTW project
  prj_pct_i <-  round(((prj_i / prj_km2) * 100),2)
  
  # Build row ----
  if (!is.null(wtw_meta)) {
    ## national row 
    new_row <- c(
      source, type, file, prv, theme, sci, com, 
      ca_km2, ca_i, ca_pct_i, goal,
      prj_km2, prj_i, prj_pct_i
    )
  } else {
    ## regional row 
    new_row <- c(
      "", "", file, "regional", "", "", "", 
      "", "", "", "", "0.2", 
      prj_km2, prj_i, prj_pct_i
    )  
  }
  
  ## append to df ----
  df <- structure(rbind(df, new_row), .Names = names(df))
  
} 

# Write to csv ----
write.csv(df, file.path(output_csv),row.names = FALSE)

# End timer
end_time <- Sys.time()
end_time - start_time  
  