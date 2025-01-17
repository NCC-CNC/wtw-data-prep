#
# Authors: Dan Wismer & Jeffrey Hanson
#
# Date: October 2nd, 2024
#
# Description: This script generates the 4 mandatory files required to 
#              upload project data into Where To Work
#
# Inputs:  1. A metadata.csv that defines attributes of each raster layer
#          2. A folder of rasters (themes, weights, includes and excludes) 
#             that all have the same spatial properties (cell size, extent, CRS)
#          3. Required R libraries
#
# Outputs: 1. Configuration.yaml
#          2. Spatial.tif
#          3. Attribute.csv.gz
#          3. Boundary.csv.gz
#
# Requires R version 4.4.1. 
#
#===============================================================================
## Start timer
start_time <- Sys.time()

# 1.0 Load packages ------------------------------------------------------------

## Install wheretowork if not yet installed or is not updated to current version (HARD CODED FOR NOW)
if (!require(wheretowork) || packageVersion("wheretowork") != "1.2.3") { 
  if (!require(remotes)) install.packages("remotes")
  remotes::install_github("NCC-CNC/wheretowork", ref = "master")  
}


# If WTW fails to install, follow these steps ----
## 1. Create Github account
## 2. Generate a personal access token (classic) PAT
## 3. Create a .Renviron file in your Documents directory
## 4. Paste your PAT in your .Renviron file

# If rcbc fails to install, be sure to have Rtools44 installed
## https://cran.r-project.org/bin/windows/Rtools/


## Load packages
library(terra)
library(dplyr)
library(wheretowork)


# 2.0 Set up -------------------------------------------------------------------

## Set path where a QC'd metadata.csv version is located
PRJ_PATH <- "C:/Data/PRZ/WTW/CONSTECH/SW_ONTARIO_V3" # <--- CHANGE TO YOUR LOCAL WTW PROJECT FOLDER
META_NAME <- "it-swon-1km-metadata.csv" # <--- CHANGE TO NAME OF YOUR metadata.csv. NEED TO ADD ".csv" extension

## Set output variables for WTW file names
### What regional operating or business unit?
OU <- "IT"  # <--- REG_BC, REG_AB, REG SK, REG MB, REG ON, REG QC, REG AT, IT, CPP, SOS, MD etc.
### Planning unit scale
SCALE <- "1km2" # <--- Set scale in ha or km2
### Unique name that describes the WTW project
NAME <- "South Western Ontario Example" # <--- give a unique name
  
PRJ_NAME <- paste0(OU, ": ", NAME, ", ", SCALE)
PRJ_FILE_NAME <- gsub(" ", "_", gsub("[[:punct:]]", "", PRJ_NAME))

AUTHOR<- "Dan Wismer" # <----- your name
EMAIL <- "dan.wismer@natureconservancy.ca" # <----- your email
GROUPS <- "private" # <---- options: public or private  

meta_path <- file.path(PRJ_PATH, paste0("WTW/metadata/", META_NAME)) 
tiffs_path <- file.path(PRJ_PATH,"TIFFS")
pu_path <- file.path(PRJ_PATH,"PU/PU.tif")


# 3.0 Import meta data and PUs -------------------------------------------------

## Import formatted csv (metadata) as tibble 
metadata <- tibble::as_tibble(
  utils::read.table(
    meta_path, stringsAsFactors = FALSE, sep = ",", header = TRUE,
    comment.char = "", quote="\""
  )
)

## Assort by order column - optional
metadata <- dplyr::arrange(metadata, Order) 

## Validate metadata
assertthat::assert_that(
  all(metadata$Type %in% c("theme", "include", "weight", "exclude")),
  all(file.exists(file.path(tiffs_path, metadata$File)))
)

## Import study area (planning units) raster
pu <- terra::rast(pu_path)


# 3.1 Import rasters -----------------------------------------------------------

## Import theme, weight, include and exclude rasters as a list of SpatRasters 
## objects. If raster variable does not compare to study area, re-project raster 
## variable so it aligns to the study area.
raster_data <- lapply(file.path(tiffs_path, metadata$File), function(x) {
  raster_x <- terra::rast(x)
  names(raster_x) <- tools::file_path_sans_ext(basename(x)) # file name
  if (terra::compareGeom(pu, raster_x, stopOnError=FALSE)) {
    raster_x
  } else {
    print(paste0(names(raster_x), ": can not stack"))
    print(paste0("... aligning to ", names(pu)))
    terra::project(raster_x, y = pu, method = "near")
  }
}) 

## Convert list to a combined SpatRaster
raster_data <- do.call(c, raster_data)

# 4.0 Pre-processing -----------------------------------------------------------

## Prepare theme inputs ----
theme_data <- raster_data[[which(metadata$Type == "theme")]]
names(theme_data) <- gsub(".", "_", names(theme_data), fixed = TRUE)
theme_names <- metadata$Name[metadata$Type == "theme"]
theme_groups <- metadata$Theme[metadata$Type == "theme"]
theme_colors <- metadata$Color[metadata$Type == "theme"]
theme_units <- metadata$Unit[metadata$Type == "theme"]
theme_visible <- metadata$Visible[metadata$Type == "theme"]
theme_provenance <- metadata$Provenance[metadata$Type == "theme"]
theme_hidden <- metadata$Hidden[metadata$Type == "theme"]
theme_legend <- metadata$Legend[metadata$Type == "theme"]
theme_labels <- metadata$Labels[metadata$Type == "theme"]
theme_values <- metadata$Values[metadata$Type == "theme"]
theme_goals <- metadata$Goal[metadata$Type == "theme"]
theme_downloadble <- metadata$Downloadable[metadata$Type == "theme"]

## Prepare weight inputs (if there are any) ----
if ("weight" %in% unique(metadata$Type)) {
  weight_data <- raster_data[[which(metadata$Type == "weight")]]
  weight_data <- terra::clamp(weight_data, lower = 0)
  weight_names <- metadata$Name[metadata$Type == "weight"]
  weight_colors <- metadata$Color[metadata$Type == "weight"]
  weight_units <- metadata$Unit[metadata$Type == "weight"]
  weight_visible <- metadata$Visible[metadata$Type == "weight"]
  weight_hidden <- metadata$Hidden[metadata$Type == "weight"]
  weight_provenance <- metadata$Provenance[metadata$Type == "weight"]
  weight_legend <- metadata$Legend[metadata$Type == "weight"]
  weight_labels <- metadata$Labels[metadata$Type == "weight"]
  weight_values <- metadata$Values[metadata$Type == "weight"]
  weight_downloadble <- metadata$Downloadable[metadata$Type == "weight"]
} else {
  weight_data <- c() # no weights in project
}

## Prepare include inputs (if there are any) ----
if ("include" %in% unique(metadata$Type)) {
  include_data <- raster_data[[which(metadata$Type == "include")]]
  include_data <- terra::classify(include_data, matrix(c(-Inf,0.5,0, 0.5,Inf,1), ncol = 3, byrow = TRUE))
  include_names <- metadata$Name[metadata$Type == "include"]
  include_colors <- metadata$Color[metadata$Type == "include"]
  include_units <- metadata$Unit[metadata$Type == "include"]
  include_visible <- metadata$Visible[metadata$Type == "include"]
  include_provenance <- metadata$Provenance[metadata$Type == "include"]
  include_legend <- metadata$Legend[metadata$Type == "include"]
  include_labels <- metadata$Labels[metadata$Type == "include"]
  include_hidden <- metadata$Hidden[metadata$Type == "include"]
  include_downloadble <- metadata$Downloadable[metadata$Type == "include"]
} else {
  include_data <- c() # no includes in project
}

## Prepare exclude inputs (if there are any) ----
if ("exclude" %in% unique(metadata$Type)) {
  exclude_data <- raster_data[[which(metadata$Type == "exclude")]]
  exclude_data <- terra::classify(exclude_data, matrix(c(-Inf,0.5,0, 0.5,Inf,1), ncol = 3, byrow = TRUE))
  exclude_names <- metadata$Name[metadata$Type == "exclude"]
  exclude_colors <- metadata$Color[metadata$Type == "exclude"]
  exclude_units <- metadata$Unit[metadata$Type == "exclude"]
  exclude_visible <- metadata$Visible[metadata$Type == "exclude"]
  exclude_provenance <- metadata$Provenance[metadata$Type == "exclude"]
  exclude_legend <- metadata$Legend[metadata$Type == "exclude"]
  exclude_labels <- metadata$Labels[metadata$Type == "exclude"]
  exclude_hidden <- metadata$Hidden[metadata$Type == "exclude"]
  exclude_downloadble <- metadata$Downloadable[metadata$Type == "exclude"]
} else {
  exclude_data <- c() # no excludes in project
}


# 5.0 Build wheretowork objects ------------------------------------------------

# Requires wheretowork package (version 1.0.0)

## Create dataset ----
dataset <- wheretowork::new_dataset_from_auto(
  c(theme_data, weight_data, include_data, exclude_data)
)

## Create themes (must have) ----
### loop over unique theme groups (ex. Endemic Species, Species at Risk, etc.)
themes <- lapply(seq_along(unique(theme_groups)), function(i) {
  
  #### store temp variables associated with group (i)
  curr_theme_groups <- unique(theme_groups)[i]
  curr_theme_data <- theme_data[[which(theme_groups == curr_theme_groups)]]
  curr_theme_data_names <- names(curr_theme_data)
  curr_theme_names <- theme_names[theme_groups == curr_theme_groups]
  curr_theme_colors <- theme_colors[theme_groups == curr_theme_groups]
  curr_theme_labels <- theme_labels[theme_groups == curr_theme_groups]
  curr_theme_units <- theme_units[theme_groups == curr_theme_groups]
  curr_theme_visible <- theme_visible[theme_groups == curr_theme_groups]
  curr_theme_hidden <- theme_hidden[theme_groups == curr_theme_groups]
  curr_theme_provenance <- theme_provenance[theme_groups == curr_theme_groups] 
  curr_theme_legend <- theme_legend[theme_groups == curr_theme_groups]
  curr_theme_values <- theme_values[theme_groups == curr_theme_groups]
  curr_theme_goals <- theme_goals[theme_groups == curr_theme_groups]
  curr_theme_downloadable <- theme_downloadble[theme_groups == curr_theme_groups]
  
  #### create list of features (j) associated with group
  curr_features <- lapply(seq_along(curr_theme_names), function(j) {
    
    #### create variable (if manual legend)
    if (identical(curr_theme_legend[j], "manual")) {
      v <- wheretowork::new_variable(
        dataset = dataset,
        index = curr_theme_data_names[j],
        units = curr_theme_units[j],
        total = terra::global(curr_theme_data[[j]], fun ="sum", na.rm = TRUE)$sum,
        legend = wheretowork::new_manual_legend(
          values = c(as.numeric(trimws(unlist(strsplit(curr_theme_values[j], ","))))),
          colors = c(trimws(unlist(strsplit(curr_theme_colors[j], ",")))),
          labels = c(trimws(unlist(strsplit(curr_theme_labels[j], ","))))
        ),
        provenance = wheretowork::new_provenance_from_source(curr_theme_provenance[j])
      )
      
      #### create variable (if continuous legend)    
    } else if (identical(curr_theme_legend[j], "continuous")) {
      v <-  wheretowork::new_variable_from_auto(
        dataset = dataset,
        index = curr_theme_data_names[j],
        units = curr_theme_units[j],
        type = "continuous",
        colors = curr_theme_colors[j],
        provenance = curr_theme_provenance[j],
        labels = "missing",
        hidden = curr_theme_hidden[j]
      )
      
      #### create variable (if null legend)   
    } else if (identical(curr_theme_legend[j], "null")) {
      v <- wheretowork::new_variable(
        dataset = dataset,
        index = curr_theme_data_names[j],
        units = " ",
        total = terra::global(curr_theme_data[[j]], fun ="sum", na.rm = TRUE)$sum,
        legend = wheretowork::new_null_legend(),
        provenance = wheretowork::new_provenance_from_source("missing")
      )
    }
    
    #### create new feature
    wheretowork::new_feature(
      name = curr_theme_names[j],
      goal = curr_theme_goals[j],
      current = 0,
      limit_goal = 0,
      visible = curr_theme_visible[j],
      hidden = curr_theme_hidden[j],
      variable = v,
      downloadable = curr_theme_downloadable[j]
    )    
  })
  
  #### create theme from list of features
  curr_theme <- wheretowork::new_theme(curr_theme_groups,curr_features)
  
  #### return theme
  curr_theme
})

## Create weights (if there are any) ----
if (!is.null(weight_data)) {
  weights <- lapply(seq_len(terra::nlyr(weight_data)), function(i) {
    
    #### prepare variable (if manual legend)
    if (identical(weight_legend[i], "manual")) {
      v <- wheretowork::new_variable_from_auto(
        dataset = dataset,
        index = names(weight_data)[i],
        units = weight_units[i],
        type = "manual",
        colors = trimws(unlist(strsplit(weight_colors[i], ","))),
        provenance = weight_provenance[i],
        labels = trimws(unlist(strsplit(weight_labels[i], ",")))
      )
      
      #### prepare variable (if null legend)    
    } else if (identical(weight_legend[i], "null")) {
      v <- wheretowork::new_variable(
        dataset = dataset,
        index = names(weight_data)[i],
        units = " ",
        total = terra::global(weight_data[[i]], fun = "sum", na.rm=TRUE)$sum,
        legend = new_null_legend(),
        provenance = wheretowork::new_provenance_from_source("missing")
      )
      
      ### prepare variable (if continuous legend)    
    } else if (identical(weight_legend[i], "continuous")) { 
      v <- wheretowork::new_variable_from_auto(
        dataset = dataset,
        index = names(weight_data)[i],
        units = weight_units[i],
        type = "continuous",
        colors = weight_colors[i],
        provenance = weight_provenance[i]
      )
    }
    
    #### create weight
    wheretowork::new_weight(
      name = weight_names[i], variable = v, 
      visible = weight_visible[i], hidden = weight_hidden[i],
      downloadable = weight_downloadble[i]
    )
  })
}

## Create includes (if there are any) ----
if (!is.null(include_data)) {
  includes <- lapply(seq_len(terra::nlyr(include_data)), function(i) {
    
    ### build legend
    if (identical(include_legend[i], "null")) {
      legend <- wheretowork::new_null_legend()
    } else {
      legend <- wheretowork::new_manual_legend(
        values = c(0, 1),
        colors = trimws(unlist(strsplit(include_colors[i], ","))),
        labels = trimws(unlist(strsplit(include_labels[i], ",")))
      )
    }
    
    ### build include
    wheretowork::new_include(
      name = include_names[i],
      visible = include_visible[i],
      hidden = include_hidden[i],
      downloadable = include_downloadble[i],
      variable = wheretowork::new_variable(
        dataset = dataset,
        index = names(include_data)[i],
        units = include_units[i],
        total = terra::global(include_data[[i]], fun = "sum", na.rm = TRUE)$sum,
        legend = legend,
        provenance = wheretowork::new_provenance_from_source(include_provenance[i])
      )
    )
  })
}

## Create excludes (if there are any) ----
if (!is.null(exclude_data)){
  excludes <- lapply(seq_len(terra::nlyr(exclude_data)), function(i) {
    
    ### build legend
    if (identical(exclude_legend[i], "null")) {
      legend <- wheretowork::new_null_legend()
    } else {
      legend <- wheretowork::new_manual_legend(
        values = c(0, 1),
        colors = trimws(unlist(strsplit(exclude_colors[i], ","))),
        labels = trimws(unlist(strsplit(exclude_labels[i], ",")))
      )
    }
    
    ### build exclude
    wheretowork::new_exclude(
      name = exclude_names[i],
      visible = exclude_visible[i],
      hidden = exclude_hidden[i],
      downloadable = include_downloadble[i],
      variable = wheretowork::new_variable(
        dataset = dataset,
        index = names(exclude_data)[i],
        units = exclude_units[i],,
        total = terra::global(exclude_data[[i]], fun = "sum", na.rm = TRUE)$sum,
        legend = legend,
        provenance = wheretowork::new_provenance_from_source(exclude_provenance[i])
      )
    )
  })
}

# 6.0  Export Where To Work objects --------------------------------------------

if (!is.null(weight_data)) {
  wtw_objects <- append(themes, weights) # Themes and Weights
} else{
  wtw_objects <- themes # Themes
}

if (!is.null(include_data)) {
  wtw_objects <- append(wtw_objects, includes) # Themes, Weights and Includes
} 

if (!is.null(exclude_data)) {
  wtw_objects <- append(wtw_objects, excludes) # Themes, Weights Includes and Excludes
} 


## Save project to disk ---- 
wheretowork::write_project(
  x = wtw_objects,
  dataset = dataset,
  name = PRJ_NAME, 
  path = file.path(PRJ_PATH, "WTW", paste0(PRJ_FILE_NAME, ".yaml")),
  spatial_path = file.path(PRJ_PATH, "WTW", paste0(PRJ_FILE_NAME, ".tif")),
  attribute_path = file.path(PRJ_PATH, "WTW", paste0(PRJ_FILE_NAME, "_attribute.csv.gz")), 
  boundary_path = file.path(PRJ_PATH, "WTW", paste0(PRJ_FILE_NAME, "_boundary.csv.gz")),
  mode = "advanced",
  user_groups = GROUPS,
  author_name = AUTHOR, 
  author_email = EMAIL 
)


# 7.0 Clear R environment ------------------------------------------------------ 

## End timer
end_time <- Sys.time()
end_time - start_time

## Comment these lines below to keep all the objects in the R session
rm(list=ls())
gc()
