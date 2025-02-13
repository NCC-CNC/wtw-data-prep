#
# Author: Dan Wismer & Marc Edwards
#
# Date: October 2nd, 2024
#
# Description: Copies prepped National rasters to the Tiffs folder.
#              Generates a metadata.csv for all national layers. This csv is 
#              a required input for 05_wtw_formatting.R.  
#
# Inputs:  1. A folder of national rasters (from natdata_to_1km_pu_grid.R) 
#          2. Output names and paths
#
# Outputs: 1. A metadata.csv to QC (quality control)
#
# Tested on R Versions: 4.4.1
#
#===============================================================================
## Start timer
start_time <- Sys.time()

# 1.0 Load packages ------------------------------------------------------------

library(tibble)
library(terra)
library(dplyr)
library(stringr)
library(readr)
library(readxl)
# source("scripts/functions/fct_sci_to_common.R") # <--- NOT NEEDED, KEEP FOR NOW
source("scripts/functions/fct_init_metadata.R")
# source("scripts/functions/fct_calculate_targets.R") # <--- NOT NEEDED, KEEP FOR NOW

# 2.0 Set up -------------------------------------------------------------------

## Name of output metadata .csv
META_NAME <- "it-swon-1km" # <--- CHANGE TO A SHORT WTW PROJECT NAME (OU/BU-shortname-scale)
## Path to local WTW project
PRJ_PATH <- "C:/Data/PRZ/WTW/CONSTECH/SW_ONTARIO_V3" # <--- CHANGE TO YOUR LOCAL WTW PROJECT FOLDER

tiff_path <- file.path(PRJ_PATH, "Tiffs")
meta_path <-  file.path(PRJ_PATH, "WTW/metadata") 
tbl_path <- file.path(PRJ_PATH, "National/_Tables")   
pu_path <- file.path(tiff_path, "PU.tif") 

# 3.0 Copy to Tiffs ------------------------------------------------------------

ECCC_CH <- list.files(file.path(PRJ_PATH, "National/Themes/ECCC_CH"), 
                      pattern='.tif$', full.names = T, recursive = F)

ECCC_SAR <- list.files(file.path(PRJ_PATH, "National/Themes/ECCC_SAR"), 
                       pattern='.tif$', full.names = T, recursive = F)

IUCN_AMPH <- list.files(file.path(PRJ_PATH, "National/Themes/IUCN_AMPH"), 
                        pattern='.tif$', full.names = T, recursive = F)

IUCN_BIRD <- list.files(file.path(PRJ_PATH, "National/Themes/IUCN_BIRD"), 
                        pattern='.tif$', full.names = T, recursive = F)

IUCN_MAMM <- list.files(file.path(PRJ_PATH, "National/Themes/IUCN_MAMM"), 
                        pattern='.tif$', full.names = T, recursive = F)

IUCN_REPT <- list.files(file.path(PRJ_PATH, "National/Themes/IUCN_REPT"), 
                        pattern='.tif$', full.names = T, recursive = F)

NSC_END <- list.files(file.path(PRJ_PATH, "National/Themes/NSC_END"), 
                      pattern='.tif$', full.names = T, recursive = F)

NSC_SAR <- list.files(file.path(PRJ_PATH, "National/Themes/NSC_SAR"), 
                      pattern='.tif$', full.names = T, recursive = F)

NSC_SPP <- list.files(file.path(PRJ_PATH, "National/Themes/NSC_SPP"), 
                      pattern='.tif$', full.names = T, recursive = F)

LC <- list.files(file.path(PRJ_PATH, "National/Themes/LC"), 
                 pattern='.tif$', full.names = T, recursive = F)

KM <- list.files(file.path(PRJ_PATH, "National/Themes/KM"), 
                 pattern='.tif$', full.names = T, recursive = F)

W <- list.files(file.path(PRJ_PATH,"National/Weights"), 
                pattern='.tif$', full.names = T, recursive = F)

Incl <- list.files(file.path(PRJ_PATH, "National/Includes"), 
                   pattern='.tif$', full.names = T, recursive = F)

Excl <- list.files(file.path(PRJ_PATH, "National/Excludes"), 
                   pattern='.tif$', full.names = T, recursive = F)

## Change list here to include or exclude layers to copy 
WtW <- list(ECCC_CH, ECCC_SAR, 
            IUCN_AMPH, IUCN_BIRD, IUCN_MAMM, IUCN_REPT, 
            NSC_END, NSC_SAR, NSC_SPP, 
            LC, KM, 
            W, Incl, Excl)

## Copy files to Tiff folder 
for (file in WtW) {
  name <- tools::file_path_sans_ext(basename(file))
  file.copy(file, paste0(tiff_path, "/", name, ".tif"))
}


# 4.0 Prep for metadata --------------------------------------------------------

## Read-in metadata xlsx's ----
### species
ECCC_CH_META <- read_excel(file.path(tbl_path,  "WTW_NAT_SPECIES_METADATA.xlsx"), sheet = 1)
ECCC_SAR_META <- read_excel(file.path(tbl_path,  "WTW_NAT_SPECIES_METADATA.xlsx"), sheet = 2)
IUCN_AMPH_META <- read_excel(file.path(tbl_path,  "WTW_NAT_SPECIES_METADATA.xlsx"), sheet = 3)
IUCN_BIRD_META <- read_excel(file.path(tbl_path,  "WTW_NAT_SPECIES_METADATA.xlsx"), sheet = 4)
IUCN_MAMM_META <- read_excel(file.path(tbl_path,  "WTW_NAT_SPECIES_METADATA.xlsx"), sheet = 5)
IUCN_REPT_META <- read_excel(file.path(tbl_path,  "WTW_NAT_SPECIES_METADATA.xlsx"), sheet = 6)
NSC_END_META <- read_excel(file.path(tbl_path,  "WTW_NAT_SPECIES_METADATA.xlsx"), sheet = 7)
NSC_SAR_META <- read_excel(file.path(tbl_path,  "WTW_NAT_SPECIES_METADATA.xlsx"), sheet = 8)
NSC_SPP_META <- read_excel(file.path(tbl_path,  "WTW_NAT_SPECIES_METADATA.xlsx"), sheet = 9)
### other national themes, weights and includes
FEATURES_META <- read_excel(file.path(tbl_path,  "WTW_NAT_FEATURES_METADATA.xlsx"))

## Read-in tiff file paths ----
file_list <- list.files(tiff_path, pattern='.tif$', full.names = T, recursive = T) 

## Remove PU from file list (if it's in there) ----
file_list <- file_list[file_list != pu_path]

## Build empty data.frame (template for metadata.csv) ----
df <- init_metadata()

# 5.0 Populate metadata --------------------------------------------------------
## Loop over each tiff file:
for (i in seq_along(file_list)) {
  
  ### Read-in raster
  wtw_raster <- rast(file_list[i])
  
  ### Get raster stats
  if (!is.factor(wtw_raster)) {
    ## df
    wtw_raster_df <- terra::as.data.frame(wtw_raster, na.rm=TRUE)
    ## number of unique value
    u_values <- nrow(unique(wtw_raster_df)) %>% as.numeric()
    ## max raster value
    max_value <- max(wtw_raster_df) %>% as.numeric() # <- CAN NOT GET MAX ON CATEGORICAL DATA
  }
  
  ## FILE ----------------------------------------------------------------------
  file_no_ext <- paste0(tools::file_path_sans_ext(basename(file_list[i])))
  file <-  paste0(file_no_ext, ".tif")
  
  #### message
  print(paste0(file, " (", i, "/", length(file_list), ")"))
  
  #### get metadata associated with file name
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
    # REGIONAL DATA
    wtw_meta <- NULL
  }
  
  # Process National ----
  if (!is.null(wtw_meta)) {
  
    #### return a single row
    wtw_meta_row <- wtw_meta %>% filter(File == file)
    
    #### get source
    source <- wtw_meta_row$Source
    
    ## TYPE ----------------------------------------------------------------------
    ## there is no "Type" column in species metadata
    type <- wtw_meta_row %>% 
      {if ("Type" %in% colnames(wtw_meta)) pull(., Type) else "theme"} 
    
    ## NAME ----------------------------------------------------------------------
    ## there is no "Name" column in species metadata
    name <- wtw_meta_row %>% 
      pull(ifelse(("Name" %in% colnames(wtw_meta)), Name, Common_Name)) 
    
    ## THEME ---------------------------------------------------------------------
    theme <- wtw_meta_row %>% pull(Theme)
      
    ## LEGEND --------------------------------------------------------------------
    legend <- if (u_values > 2) "continuous" else "manual"
    
    ## VALUES --------------------------------------------------------------------
    if (identical(u_values, 2) && identical(max_value, 1)) {
      values <- "0, 1" # IUCN, NSC, KBA, Includes 
    } else if (identical(u_values, 2)) {
      values <- paste0("0,", max_value) # ECCC: rare case if only 2 unique values
    } else if (identical(u_values, 1)) {
      values <- max_value # covers entire AOI
    } else {
      values <- "" # continuous data does not need values
    }
  
    ## COLOR ---------------------------------------------------------------------
    ## there is no "Color" column in species metadata 
    color <- case_when(
      identical(source, "ECCC_CH") && identical(u_values, 2) ~  "#00000000, #756bb1",
      identical(source, "ECCC_CH") && identical(u_values, 1) ~  "#756bb1", 
      identical(source, "ECCC_CH") && identical(legend, "continuous")  ~  "Purples",
      identical(source, "ECCC_SAR") && identical(u_values, 2) ~  "#00000000, #fb9a99",
      identical(source, "ECCC_SAR") && identical(u_values, 1) ~  "#fb9a99", 
      identical(source, "ECCC_SAR") && identical(legend, "continuous") ~  "Reds",
      identical(source, "IUCN_AMPH") && identical(u_values, 2) ~  "#00000000, #a6cee3",
      identical(source, "IUCN_AMPH") && identical(u_values, 1) ~  "#a6cee3",
      identical(source, "IUCN_BIRD") && identical(u_values, 2) ~  "#00000000, #ff7f00",
      identical(source, "IUCN_BIRD") && identical(u_values, 1) ~  "#ff7f00",
      identical(source, "IUCN_MAMM") && identical(u_values, 2) ~  "#00000000, #b15928",
      identical(source, "IUCN_MAMM") && identical(u_values, 1) ~  "#b15928",
      identical(source, "IUCN_REPT") && identical(u_values, 2) ~  "#00000000, #b2df8a",
      identical(source, "IUCN_REPT") && identical(u_values, 1) ~  "#b2df8a",
      identical(source, "NSC_END") && identical(u_values, 2) ~  "#00000000, #4575b4",
      identical(source, "NSC_END") && identical(u_values, 1) ~  "#4575b4",
      identical(source, "NSC_SAR") && identical(u_values, 2) ~  "#00000000, #d73027",
      identical(source, "NSC_SAR") && identical(u_values, 1) ~  "#d73027",
      identical(source, "NSC_SPP") && identical(u_values, 2) ~  "#00000000, #e6f598",
      identical(source, "NSC_SPP") && identical(u_values, 1) ~  "#e6f598",
      TRUE ~ {if ("Color" %in% colnames(wtw_meta)) pull(wtw_meta_row, Color) else "" }
    )
    
    ## LABELS --------------------------------------------------------------------
    ## there is no "Label" column in species metadata
    labels <- case_when(
      identical(source, "ECCC_CH") && identical(u_values, 2) ~  "Non Habitat, Habitat",
      identical(source, "ECCC_CH") && identical(u_values, 1) ~  "Habitat",
      identical(source, "ECCC_CH") && identical(legend, "continuous") ~  "",
      identical(source, "ECCC_SAR") && identical(u_values, 2) ~  "Non Range, Range",
      identical(source, "ECCC_SAR") && identical(u_values, 1) ~  "Range",
      identical(source, "ECCC_SAR") && identical(legend, "continuous") ~  "",
      identical(substring(source, 1, 4), "IUCN") && identical(u_values, 2) ~  "Non Habitat, Habitat",
      identical(substring(source, 1, 4), "IUCN") && identical(values, 1) ~  "Habitat",
      identical(substring(source, 1, 3), "NSC") && identical(u_values, 2) ~  "Non Occurrence, Occurrence",
      identical(substring(source, 1, 3), "NSC") && identical(values, 1) ~  "Occurrence",
      TRUE ~ {if ("Labels" %in% colnames(wtw_meta)) pull(wtw_meta_row, Labels) else "" }
    )
    
    ## UNITS ---------------------------------------------------------------------
    ## there is no "Unit" column in species metadata
    unit <- case_when(
      (identical(source, "ECCC_CH")) ~ "ha",
      (identical(source, "ECCC_SAR")) ~  "ha",
      identical(source, "IUCN_AMPH") ~  "km2",
      identical(source, "IUCN_BIRD") ~  "km2",
      identical(source, "IUCN_MAMM") ~  "km2",
      identical(source, "IUCN_REPT") ~  "km2",
      identical(source, "NSC_END") ~  "km2",
      identical(source, "NSC_SAR") ~  "km2",
      identical(source, "NSC_SPP") ~  "km2",
      TRUE ~ {if ("Unit" %in% colnames(wtw_meta)) pull(wtw_meta_row, Unit) else "" }
    )   
    
    ## PROVENANCE ----------------------------------------------------------------
    provenance <- "national"
    
    ## ORDER ---------------------------------------------------------------------
    order <- "" # manual assignment in csv
    
    ## VISIBLE -------------------------------------------------------------------
    visible <- if (startsWith(file_no_ext, "I_NAT")) "TRUE" else "FALSE" 
    
    ## HIDDEN --------------------------------------------------------------------
    hidden <- "FALSE"
    
    ## DOWNLOADABLE ------------------------------------------------------------
    downloadable <- if (startsWith(file_no_ext, "T_NAT_NSC")) "FALSE" else "TRUE"     
    
    ## GOAL ----------------------------------------------------------------------
    ## only set goals for themes
    if (identical(type, "theme")) {
      ## only set Rodrigues goals on species data
      species_sources <- c(
        "ECCC_CH", "ECCC_SAR", 
        "IUCN_AMPH", "IUCN_BIRD", "IUCN_MAMM", "IUCN_REPT",
        "NSC_END", "NSC_SAR", "NSC_SPP"
      )
      if (source %in% species_sources) {
        goal <- wtw_meta_row$Goal # species
      } else {
        goal <- "0.2" # forest, wetland, rivers, lakes, shoreline
      }
    } else {
      goal <- "" # weights, includes, excludes
    }    

    ## Build new national row ----
    new_row <- c(
      type, theme, file, name, legend, 
      values, color, labels, unit, provenance, 
      order, visible, hidden, downloadable, goal
    )
    
  } else {
    
    ## Build new regional row ----
    new_row <- c(
      "", "", file, "", "", 
      "", "", "", "", "regional", 
      "", "", "", "" , "0.2"
    )
  }
  
  ## Append to DF
  df <- structure(rbind(df, new_row), .Names = names(df))
  
} 

# Write to csv ----
write.csv(
  df,
  file.path(meta_path, paste0(META_NAME, "-metadata-NEEDS-QC.csv")),
  row.names = FALSE
)

# End timer
end_time <- Sys.time()
end_time - start_time
