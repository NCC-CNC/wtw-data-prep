# Where To Work data prep

This repo assists in formatting your data into the four mandatory files (described below) required for import into **Where To Work** (WTW) when using the *upload project data* method.

These scripts can be used when planning units are grid cells that can be passed to WTW as raster layers where each raster cell is a unique planning unit. For non-grid planning units, a different workflow is required ([#9](https://github.com/NCC-CNC/wtw-data-prep/issues/9)).

When starting a new project, we recommend copying the scripts, functions, and data needed for your workflow (described below), from this repo into your project file. You can then edit the scripts and run them from your project file.


## Objective

The objective of these scripts is to get the WTW data into a standardized set of raster files representing the planning units covering the AOI, and to prepare a meta data csv table that defines the WTW parameters for each raster. The `05_wtw_formatting.R` script can then package the data into the WTW format.


## Workflows

1. The most common workflow is to use NCC's standard 1km grid as the planning units, and the standard set of [national datasets](#national-datasets) that have been pre-prepped into the 1km grid. This workflow simply extracts the 1km planning units and the pre-prepped data for all planning units covering the AOI.

2. Some users may wish to add some additional datasets to workflow 1. This requires the user to prepare thier own raster datasets to supplement the standard set of national data. This typically involves intersecting the data to the planning unit grid and summarizing the data values per planning unit. See the [regional_example](https://github.com/NCC-CNC/wtw-data-prep/tree/main/regional_example) folder for scripts to do this.

3. Some users may wish to use only their own datasets in which case they need to prepare all the input data using the 1km national grid, or an alternate custom grid. See the [regional_example](https://github.com/NCC-CNC/wtw-data-prep/tree/main/regional_example) folder for scripts to do this.

Note: users using a custom grid for planning units who want to add the standard national datasets will need to access the original raster or vector versions of these datasets and apply them in workflow 3. The pre-prepped [national datasets](#national-datasets) can only be used with the standard NCC 1km grid.


## National data

The following scripts in this repo are used to prepare the standard [national datasets](#national-datasets) using the NCC 1km planning units (i.e. workflow 1 described above). More details on each script are provided in the [scripts](#script) section:

-   `01_initiate_project.R` - sets up folder structure, saves AOI.shp
-   `02_aoi_to_1km_grid.R` - extracts the NCC 1km grid cells intersecting the AOI. Saves the grid in vector and raster formats.
-   `03_natdata_to_1km_pu_grid.R` - extracts the pre-prepped national data to the 1km PU grid and saves as rasters in the National folder.
-   `04_populate_nat_metadata.R` - copies the required rasters to the Tiffs folder and uses them to prepare the metadata csv file.
-   `05_wtw_formatting.R` - Uses the Tiffs rasters and the metadata csv file to create the four WTW input files.
-   `functions` - folder containing functions needed by various scripts.
-   `data` - folder containing the NCC 1km raster template required by `02_aoi_to_1km_grid.R`.


## Regional data

Any user provided datasets that are not part of the standard [national datasets](#national-datasets) are referred to as **Regional data**. These are typically vector or raster layers that need to be summarized per planning unit. An example workflow for this is provided in the [regional_example](https://github.com/NCC-CNC/wtw-data-prep/tree/main/regional_example) folder.


## Data formats

WTW runs prioritizations using the values assigned to each planning unit from the input data. It's important that users of WTW understand what their data represent, especially for users adding their own data into the tool.

- **area**, **length** or **count**: Many datasets simply represent the area, length or count of a given feature in each planning unit. Examples include species range data, the density of rivers or roads, or the count of specific sites.

- **Simple summaries** - Some data have their own units that are carried though to WTW. Examples include carbon storage which can be expressed as tonnes of C per planning unit. In this case the source data are raster values that can be summed within each planning unit.

- **Complex summaries** - Some data may require more complex summaries to get meaningful values per planning unit. An example could be the weighted average stream order for a user looking to prioritize headwaters.


## Projections

- Projects using the NCC national grid project all datasets into a WGS84 version of Canada Albers.
- Projects using a custom grid will use the projection of the provided AOI shapefile. Any user-provided data should be projected to match the planning units.

## Scripts

### Initiate a new project

`01_initiate_project.R`

_Sets up the folder structure and copies the AOI shapefile into the PU folder._

Inputs

-   Shapefile polygon defining AOI
-   User defines whether the project uses NATIONAL or REGIONAL data (or BOTH).

Outputs

-   Creates the following folder structure and copies the AOI polygon into the PU folder:
    <br>
    |--- PU <br>
    |&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|--- AOI.shp <br>
    |--- scripts <br>
    |--- Tiffs <br>
    |--- WTW <br>
    |&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|--- metadata <br>
    |--- National (_if requested_) <br>
    |--- Regional (_if requested_) <br>
      

### Extract the NCC 1km grid covering the AOI

`aoi_to_1km_grid.R`

_Creates the planning unit grid using all NCC 1km grid cells that intersect the AOI._

Inputs

- The AOI polygon (PU/AOI.shp)
- NCC 1km grid (Constant_1KM_IDX.tif)

Outputs

- Extracts all 1km grid cells intersecting the AOI and saves them as:
  - PU/PU.shp
  - PU/PU.tif (raster of 1's)
  - PU/PU0.tif (raster of 0's)
  
**Takes a polygon shapefile (AOI) ...**
![](https://user-images.githubusercontent.com/29556279/227652386-62c9ed2f-8923-428d-ad8c-8a17a867af04.png)

**and generates a NCC 1km vector grid.**
![](https://user-images.githubusercontent.com/29556279/227652391-f45eca44-71f5-4cc5-9ed9-3ff69b4ce1d2.png)


### Extract national data to the 1km PU grid

`natdata_to_1km_pu_grid.R`

_Used in conjunction with aoi_to_1km_grid.R to prepare NATIONAL data for the AOI._

Inputs

- The prepared 1km PU grid (PU/PU.tif)
- Pre-prepped national data folder

Outputs

- a 1km x 1km raster layer for each NATIONAL dataset that intersects with the aoi, saved in folders:
  - National/Themes
  - National/Weights
  - National/Includes
  - National/Excludes
- a csv that lists the species intersecting the aoi (saved in National/Themes/SPECIES.csv)

:warning: **Data needed to run this script is not packaged in this repo.**

#### National Datasets
##### Themes

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

##### Weights

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

##### Includes

* Existing Conservation (CPCAD)


### Create metadata table

`populate_nat_metadata.R`

_Automates the creation of a metadata .csv table that is used in `wtw_formatting.R`._
_Once created, the metadata csv table should be manually QC'd before proceeding to  `wtw_formatting.R`._

:note: If using REGIONAL data, the metadata table must be created manually (or edited manually if using both NATIONAL and REGIONAL data).

Inputs

- The prepared 1km x 1km raster NATIONAL raster layers created by `natdata_to_1km_pu_grid.R`.

Outputs

- All rasters are copied into the Tiffs folder
- The metadata csv table to be QC'd and passed to `wtw_formatting.R`

##### metadata table columns
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


### Format data for Where To Work

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

