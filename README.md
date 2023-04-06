# Where To Work data prep

This repo assists in formatting your raster data into the four mandatory files (described below) required for import into **Where To Work** when using the *upload project data* method.
When starting a new project, we recommend copying the scripts, functions, and data needed for your workflow (described below), from this repo into your project file. 
You can then edit the scripts and run them from your project file.


# Introduction

The following scripts are stored in this repo, each is described in more detail below:

-   `initiate_project.R` - sets up folder structure, saves AOI_polygon.shp
-   `aoi_to_1km_grid.R` - extracts the NCC 1km grid cells intersecting the AOI. Saves the grid in vector and raster formats.
-   `aoi_to_custom_grid.R` - creates a custom sized grid intersecting the AOI. Saves the grid in vector and raster formats.
-   `natdata_to_aoi_1km_grid.R` - extracts the pre-prepped national data to the AOI 1km grid and saves as rasters in the National folder.
    -   Note: extracting regional data and/or using a custom grid requires users to add additional scripts or use manual steps to create the raster datasets.
-   `populate_nat_metadata.R` - copies the required rasters to the Tiffs folder and uses them to prepare the metadata csv file.
-   `wtw_formatting.R` - Uses the Tiffs rasters and the metadata csv file to create the four WTW input files.
-   `functions` - folder containing functions needed by various scripts.
-   `data` - folder containing the NCC 1km raster template required by `aoi_to_1km_grid.R`.

## Workflows

Different combinations of scripts can be used to prepare WTW data depending on the source of the input data and the planning units required in WTW.
The ultimate objective is to get all input data into a standardized raster format (matching extents, cell size, projection etc.) in the Tiffs folder, with a completed metadata csv table. 
The wtw_formatting.R script can then package the data into the WTW format.

-   **Data**: Projects can use NATIONAL or REGIONAL data. NATIONAL data are the standard set of WTW datasets pre-prepped to a lkm grid. REGIONAL data are any other datasets provided by the user.
-   **Planning units**: Projects can use the standard NCC 1km planning unit grid, or a custom set of planning units such as a custom grid (or a non-grid set of planning units).

The following workflows are possible based on the combination of data and planning units:

-   **NATIONAL DATA + 1KM GRID** (recommended workflow):
    -   Input: AOI shapefile, pre-prepped national data in national 1km grid, NCC 1km grid template
    -   Scripts to use:
        -   initiate_project.R
        -   aoi_to_1km_grid.R
        -   natdata_to_aoi_1km_grid.R
        -   populate_nat_metadata.R
        -   wtw_formatting.R
-   **REGIONAL DATA + 1km GRID**:
    -   Input: AOI shapefile, regional datasets, NCC 1km grid template
    -   Scripts to use:
        -   initiate_project.R
        -   aoi_to_1km_grid.R
        -   PROJECT SPECIFIC SCRIPTS: custom python and/or R scripts to extract the regional datasets into the AOI 1km grid and convert to rasters in the Tiffs folder
        -   MANUALLY CREATE metadata csv
        -   wtw_formatting.R
    -   Note that this workflow can be combined with NATIONAL DATA + 1KM GRID in cases where users want to use both NATIONAL and REGIONAL data.
    -   Note that the metadata table needs to be created manually for regional data (or manually appended to the NATIONAL metadata if using both NATIONAL and REGIONAL data)
-   **REGIONAL DATA + CUSTOM GRID**:
    -   Input: AOI shapefile, regional datasets, grid cell size
    -   Scripts to use:
        -   initiate_project.R
        -   aoi_to_custom_grid.R
        -   PROJECT SPECIFIC SCRIPTS: custom python and/or R scripts are used to extract the regional datasets into the custom grid and convert to rasters in the Tiffs folder
        -   wtw_formatting.R
    -   Note that the metadata table needs to be created manually for regional data
-   **NATIONAL DATA + CUSTOM GRID**: (note we have not encountered this workflow yet)
    -   Input: AOI shapefile, grid cell size, raw national data (not-prepped into 1km grid)
    -   Scripts to use:
        -   initiate_project.R
        -   aoi_to_custom_grid.R
        -   PROJECT SPECIFIC SCRIPTS: custom python and/or R scripts are used to extract the raw national datasets into the custom grid and convert to rasters in the Tiffs folder
        -   populate_nat_metadata.R
        -   wtw_formatting.R

## Projections

- Projects using the NCC national grid project all datasets into a WGS84 version of Canada Albers.
- Projects using a custom grid will use the projection of the provided AOI shapefile. Any regional data should also use this projection.

# Initiate a new project

`initiate_project.R`

_Sets up the folder structure and copies the AOI shapefile into the AOI folder._

Inputs

-   Shapefile polygon defining AOI
-   User defines whether the project uses NATIONAL or REGIONAL data (or BOTH).

Outputs

-   Creates the following folder structure and copies the AOI polygon into the AOI folder:
    <br>
    |--- AOI <br>
    |&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|--- AOI_polygon.shp <br>
    |--- scripts <br>
    |--- Tiffs <br>
    |--- WTW <br>
    |&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|--- metadata <br>
    |--- National (_if requested_) <br>
    |--- Regional (_if requested_) <br>
      


# Extract the NCC 1km grid covering the AOI

`aoi_to_1km_grid.R`

_Creates the AOI grid using all NCC 1km grid cells that intersect the AOI._

Inputs

- The AOI polygon (AOI/AOI_polygon.shp)
- NCC 1km grid (Constant_1KM_IDX.tif)

Outputs

- Extracts all 1km grid cells intersecting the AOI and saves them as:
  - AOI/AOI.shp
  - AOI/AOI.tif (raster of 1's)
  - AOI/AOI0.tif (raster of 0's)
  
**Takes a polygon shapefile (AOI) ...**
![](https://user-images.githubusercontent.com/29556279/227652386-62c9ed2f-8923-428d-ad8c-8a17a867af04.png)

**and generates a NCC 1km vector grid.**
![](https://user-images.githubusercontent.com/29556279/227652391-f45eca44-71f5-4cc5-9ed9-3ff69b4ce1d2.png)


# Create a custom grid

`aoi_to_custom_grid.R`

_This is used when a coarser (e.g. 10 km) or finer (e.g. 10 ha) grid of planning units is required in WTW._

Inputs

- The AOI polygon (AOI/AOI_polygon.shp)
- The required grid cell size (in units matching the AOI projection)

Outputs

- Creates the grid and saves as:
  - AOI/AOI.shp
  - AOI/AOI.tif (raster of 1's)
  - AOI/AOI0.tif (raster of 0's)
  

# Extract national data to the AOI 1km grid

`natdata_to_aoi_1km_grid.R`

_Used in conjunction with aoi_to_1km_grid.R to prepare NATIONAL data for the AOI._

Inputs

- The prepared AOI 1km grid (AOI/AOI.tif)
- Pre-prepped national data folder

Outputs

- a 1km x 1km raster layer for each NATIONAL dataset that intersects with the aoi, saved in folders:
  - National/Themes
  - National/Weights
  - National/Includes
  - National/Excludes
- a csv that lists the species intersecting the aoi (saved in National/Themes/SPECIES.csv)

:warning: **Data needed to run this script is not packaged in this repo.**

## National Data:
### Themes

* Environment and Climate Change Canada Critical Habitat (ECCC_CH)
* Environment and Climate Change Canada Species at Risk (ECCC_SAR)
* International Union for Conservation of Nature Amphibians (IUCN_AMPH)
* International Union for Conservation of Nature Birds (IUCN_BIRD)
* International Union for Conservation of Nature Mammals (IUCN_MAMM)
* International Union for Conservation of Nature Reptiles (IUCN_REPT)
* Nature Serve Canada Species at Risk (NSC_SAR)
* Nature Serve Canada Endemics (NSC_END)
* Nature Serve Canada Common Species (NSC_SPP)
* Forest Land Cover
* Forest Land Use
* Wetlands
* Grasslands
* Lakes
* Rivers
* Shoreline

### Weights

* Carbon storage
* Carbon potential
* Climate forward velocity
* Climate refugia
* Climate extremes
* Connectivity
* Human Footprint Index
* Key Biodiversity Areas
* Recreation
* Freshwater

### Includes

* Existing Conservation (CPCAD)


# Create metadata table

`populate_nat_metadata.R`

_Automates the creation of a metadata .csv table that is used in `wtw_formatting.R`._
_Once created, the metadata csv table should be manually QC'd before proceding to  `wtw_formatting.R`._

:note: If using REGIONAL data, the metadata table must be created manually (or edited manually if using both NATIONAL and REGIONAL data).

Inputs

- The prepared 1km x 1km raster NATIONAL raster layers created by `natdata_to_aoi_1km_grid.R`.

Outputs

- All rasters are copied into the Tiffs folder
- The metadata csv table to be QC'd and passed to `wtw_formatting.R`

### metadata table columns
(you can view a QC'd version [here.](https://github.com/NCC-CNC/wheretowork-input-formatting/blob/main/WTW/metadata/sw-on-metadata-NEEDS-QC.csv)):

- **Type** <br>
Available choices: theme, weight, include or exclude.

- **Theme** <br>
If Type is theme, provide a name for the grouping. <br>
Example: Species at Risk (ECCC)

- **File** <br>
Provide the file name with extension of the layer. <br>
Example: T_ECCC_SAR_Agalinis_gattingeri.tif

- **Name** <br>
Provide a name for the layer. <br>
Example: Existing conservation

- **Legend** <br>
Provide a legend type based off the data type (manual legend == categorical data). <br>
Available choices: manual, continuous or null

- **Values** <br>
If legend is manual, provide the categorical values. <br>
Example: 0, 1

- **Color** <br>
If legend is **manual**, provide the hex colors. This must be the same length as values. <br>
Example: #00000000, #b3de69 <br>
If legend is **continuous**, provide a colors ramp from [wheretowork::color_palette()](https://ncc-cnc.github.io/wheretowork/reference/color_palette.html) <br>
Example: magma

- **Labels** <br>
If legend is manual, provide the labels for each value. This must be the same length as values. <br>
Example: absence, presence

- **Unit** <br>
Provide a unit for the layer <br>
Example: km2

- **Provenance** <br>
Define if the layer is regional or national data. <br>
Available choices: regional, national or missing

- **Order** <br>
Optional; define the order of the layers when `wheretowork`is initialized. <br>

- **Visible** <br>
Define if the layer will be visible when `wheretowork`is initialized. <br>
Available choices: TRUE or FALSE

- **Hidden** <br>
Define if the layer will be hidden from `wheretowork` (recommended for large projects). <br>
Available choices: TRUE or FALSE

- **Goal** <br>
If Type is theme, provide a goal for the layer when `wheretowork` is initialized. <br>
Available choices: a number between 0 and 1


# Format data for Where To Work

`wtw_formatting.R`

_Creates the four files required by WTW._

Inputs

- The prepared rasters in the Tiffs folder (all with matching extents, cell size, projectison etc.)
- The QC'd metadata csv file describing the properties for each raster when added to WTW

Outputs

- The 4 files which can then be loaded into WTW using the **upload project data** method:

1. **configuration.yaml:** <br>
The configuration file defines project attributes, legend elements / map display in the left side bar 'Table of contents' and initial goals in the 'New solution' right side bar.
 
2. **spatial.tif:** <br>
The spatial tiff file defines the spatial properties of the planning units, 
such as cell size, extent, number of rows, number of columns and coordinate reference system. It acts as the template to build rasters from columns within the attribute.csv.gz.

3. **attribute.csv.gz:** <br>
The attribute file defines the cell values of each theme, weight, include and exclude in tabular form. Each column in the .csv is a variable. 

4. **boundary.csv.gz:** <br>
The boundary file defines the adjacency table of each theme, weight, include and exclude. It stores information on the perimeter and shared boundary lengths of the planning units. This is needed to run optimizations for spatial clustering.

