#
# Authors: Dan Wismer & Jeffrey Hanson
#
# Date: September 30th, 2022
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
#===============================================================================
## Start timer
start_time <- Sys.time()

# 1.0 Load packages ------------------------------------------------------------

## Install wheretowork if not yet installed
if (!require(wheretowork)) {
  if (!require(remotes)) install.packages("remotes")
  remotes::install_github("NCC-CNC/wheretowork")  
}

## Load packages
library(raster)
library(dplyr)
library(wheretowork)


# 2.0 Set up -------------------------------------------------------------------
setwd("C:/Data/PRZ/WTW_PROJECTS/SW_ONTARIO_V2")
## Set path where a QC'd metadata.csv version is located
metadata_path <- "WTW/metadata/sw-on-v2-metadata.csv" # <--- CHANGE PATH HERE FOR NEW PROJECT

## Set path where rasters are located
tiffs_path <- "Tiffs" # <--- CHANGE PATH HERE FOR NEW PROJECT

## Name of study area (planning unit) raster
study_area_file <- "PU/PU.tif" # <--- CHANGE PATH HERE FOR NEW PROJECT

## Set output variables for WTW file names
prj_name <- "SW Ontario" # <----- spaces allowed
prj_file_name <-"sw_on" # <----- no spaces allowed
author_name <- "Dan Wismer" # <----- your name
author_email <- "dan.wismer@natureconservancy.ca" # <----- your email


# 3.0 Import meta data and PUs -------------------------------------------------

## Import formatted csv (metadata) as tibble 
metadata <- tibble::as_tibble(
  utils::read.table(
    metadata_path, stringsAsFactors = FALSE, sep = ",", header = TRUE,
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
study_area_data <- raster::raster(study_area_file)


# 3.1 Import rasters -----------------------------------------------------------

## Import themes, includes and weights rasters as a raster stack. If raster 
## variable does not stack to study area, re-project raster variable so it aligns 
## to the study area
raster_data <- lapply(file.path(tiffs_path, metadata$File), function(x) {
  raster_x <- raster::raster(x)
  if (raster::compareRaster(study_area_data, raster_x, stopiffalse=FALSE)) {
    raster_x
  } else {
    print(paste0(names(raster_x), ": can not stack"))
    print(paste0("... aligning to ", names(study_area_data)))
    raster::projectRaster(raster_x, to = study_area_data, method = "ngb")
  }
}) %>% raster::stack()


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

## Prepare weight inputs ----
weight_data <- raster_data[[which(metadata$Type == "weight")]]
weight_data <- raster::clamp(weight_data, lower = 0)
weight_names <- metadata$Name[metadata$Type == "weight"]
weight_colors <- metadata$Color[metadata$Type == "weight"]
weight_units <- metadata$Unit[metadata$Type == "weight"]
weight_visible <- metadata$Visible[metadata$Type == "weight"]
weight_hidden <- metadata$Hidden[metadata$Type == "weight"]
weight_provenance <- metadata$Provenance[metadata$Type == "weight"]
weight_legend <- metadata$Legend[metadata$Type == "weight"]
weight_labels <- metadata$Labels[metadata$Type == "weight"]
weight_values <- metadata$Values[metadata$Type == "weight"]

## Prepare include inputs ----
include_data <- raster_data[[which(metadata$Type == "include")]]
include_data <- raster::reclassify(include_data, matrix(c(-Inf,0.5,0, 0.5,Inf,1), ncol = 3, byrow = TRUE))
include_names <- metadata$Name[metadata$Type == "include"]
include_colors <- metadata$Color[metadata$Type == "include"]
include_units <- metadata$Unit[metadata$Type == "include"]
include_visible <- metadata$Visible[metadata$Type == "include"]
include_provenance <- metadata$Provenance[metadata$Type == "include"]
include_legend <- metadata$Legend[metadata$Type == "include"]
include_labels <- metadata$Labels[metadata$Type == "include"]
include_hidden <- metadata$Hidden[metadata$Type == "include"]

## Prepare exclude inputs ----
exclude_data <- raster_data[[which(metadata$Type == "exclude")]]
if (length(exclude_data) > 0) {
  exclude_data <- raster::reclassify(exclude_data, matrix(c(-Inf,0.5,0, 0.5,Inf,1), ncol = 3, byrow = TRUE))
  exclude_names <- metadata$Name[metadata$Type == "exclude"]
  exclude_colors <- metadata$Color[metadata$Type == "exclude"]
  exclude_units <- metadata$Unit[metadata$Type == "exclude"]
  exclude_visible <- metadata$Visible[metadata$Type == "exclude"]
  exclude_provenance <- metadata$Provenance[metadata$Type == "exclude"]
  exclude_legend <- metadata$Legend[metadata$Type == "exclude"]
  exclude_labels <- metadata$Labels[metadata$Type == "exclude"]
  exclude_hidden <- metadata$Hidden[metadata$Type == "exclude"]
}


# 5.0 Build wheretowork objects ------------------------------------------------

## Create data set ----
dataset <- new_dataset_from_auto(
  raster::stack(theme_data, weight_data, include_data, exclude_data)
)

## Create themes ----

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
  
  #### create list of features (j) associated with group
  curr_features <- lapply(seq_along(curr_theme_names), function(j) {
    
    #### create variable (if manual legend)
    if (identical(curr_theme_legend[j], "manual")) {
      v <- new_variable(
        dataset = dataset,
        index = curr_theme_data_names[j],
        units = curr_theme_units[j],
        total = raster::cellStats(curr_theme_data[[j]], "sum"),
        legend = new_manual_legend(
          values = c(as.numeric(trimws(unlist(strsplit(curr_theme_values[j], ","))))),
          colors = c(trimws(unlist(strsplit(curr_theme_colors[j], ",")))),
          labels = c(trimws(unlist(strsplit(curr_theme_labels[j], ","))))
        ),
        provenance = new_provenance_from_source(curr_theme_provenance[j])
      )
      
      #### create variable (if continuous legend)    
    } else if (identical(curr_theme_legend[j], "continuous")) {
      v <-  new_variable_from_auto(
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
      v <- new_variable(
        dataset = dataset,
        index = curr_theme_data_names[j],
        units = " ",
        total = raster::cellStats(curr_theme_data[[j]], "sum"),
        legend = new_null_legend(),
        provenance = new_provenance_from_source("missing")
      )
    }
    
    #### create new feature
    new_feature(
      name = curr_theme_names[j],
      goal = curr_theme_goals[j],
      current = 0,
      limit_goal = 0,
      visible = curr_theme_visible[j],
      hidden = curr_theme_hidden[j],
      variable = v
    )    
  })
  
  #### create theme from list of features
  curr_theme <- new_theme(curr_theme_groups,curr_features)
  
  #### return theme
  curr_theme
})

## Create includes ----

### loop over each raster in include_data
includes <- lapply(seq_len(raster::nlayers(include_data)), function(i) {
  
  ### build legend
  if (identical(include_legend[i], "null")) {
    legend <- new_null_legend()
  } else {
    legend <- new_manual_legend(
      values = c(0, 1),
      colors = trimws(unlist(strsplit(include_colors[i], ","))),
      labels = unlist(strsplit(include_labels[i], ","))
    )
  }
  
  ### build include
  new_include(
    name = include_names[i],
    visible = include_visible[i],
    hidden = include_hidden[i],
    variable = new_variable(
      dataset = dataset,
      index = names(include_data)[i],
      units = " ",
      total = raster::cellStats(include_data[[i]], "sum"),
      legend = legend,
      provenance = new_provenance_from_source(include_provenance[i])
    )
  )
})

## Create excludes ----

## Create excludes ----
### loop over each raster in exclude_data
excludes <- lapply(seq_len(raster::nlayers(exclude_data)), function(i) {
  
  ### build legend
  if (identical(exclude_legend[i], "null")) {
    legend <- new_null_legend()
  } else {
    legend <- new_manual_legend(
      values = c(0, 1),
      colors = trimws(unlist(strsplit(exclude_colors[i], ","))),
      labels = unlist(strsplit(exclude_labels[i], ","))
    )
  }
  
  ### build exclude
  new_exclude(
    name = exclude_names[i],
    visible = exclude_visible[i],
    hidden = exclude_hidden[i],
    variable = new_variable(
      dataset = dataset,
      index = names(exclude_data)[i],
      units = " ",
      total = raster::cellStats(exclude_data[[i]], "sum"),
      legend = legend,
      provenance = new_provenance_from_source(exclude_provenance[i])
    )
  )
})

## Create weights ---- 

### loop over each raster in weight_data
weights <- lapply(seq_len(raster::nlayers(weight_data)), function(i) {
  
  #### prepare variable (if manual legend)
  if (identical(weight_legend[i], "manual")) {
    v <- new_variable_from_auto(
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
    v <- new_variable(
      dataset = dataset,
      index = names(weight_data)[i],
      units = " ",
      total = raster::cellStats(weight_data[[i]], "sum"),
      legend = new_null_legend(),
      provenance = new_provenance_from_source("missing")
    )
    
    ### prepare variable (if continuous legend)    
  } else if (identical(weight_legend[i], "continuous")) { 
    v <- new_variable_from_auto(
      dataset = dataset,
      index = names(weight_data)[i],
      units = weight_units[i],
      type = "continuous",
      colors = weight_colors[i],
      provenance = weight_provenance[i]
    )
  }
  
  #### create weight
  new_weight(name = weight_names[i], variable = v, visible = weight_visible[i],
             hidden = weight_hidden[i])
})


# 6.0  Export Where To Work objects --------------------------------------------

## Save project to disk ---- <--- CHANGE FOR NEW PROJECT
write_project(
  x = append(append(themes, append(includes, weights)), excludes),
  dataset = dataset,
  name = prj_name, 
  path = paste0("WTW/", prj_file_name, ".yaml"),
  spatial_path = paste0("WTW/", prj_file_name, ".tif"),
  attribute_path = paste0("WTW/", prj_file_name, "_attribute.csv.gz"), 
  boundary_path = paste0("WTW/", prj_file_name, "_boundary.csv.gz"),
  mode = "advanced",
  author_name = author_name, 
  author_email = author_email 
)


# 7.0 Clear R environment ------------------------------------------------------ 

## End timer
end_time <- Sys.time()
end_time - start_time

## Comment these lines below to keep all the objects in the R session
rm(list=ls())
gc()