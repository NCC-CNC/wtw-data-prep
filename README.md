# Where To Work data prep

This repo assists in formatting your data into the four mandatory files (described below) required for import into **Where To Work** (WTW) when using the *upload project data* method.

These scripts can be used when planning units are grid cells that can be passed to WTW as raster layers where each raster cell is a unique planning unit. For non-grid planning units, a different workflow is required ([#9](https://github.com/NCC-CNC/wtw-data-prep/issues/9)).

When starting a new project, we recommend copying the scripts, functions, and data from this repo into your project folder. You can then edit the scripts and run them from your project folder.

> **Note** Basic coding skills in R (and possibly Python) are required to use these scripts.

## Objective

The objective of these scripts is to get the source data into a standardized set of raster files where the raster grid cells represent the planning units. The source data is also used to prepare a meta data csv table that defines the WTW parameters for each raster. The `05_wtw_formatting.R` script can then package the data into the WTW format so it can be loaded into WTW.

![image](https://user-images.githubusercontent.com/10728298/235223843-5ea67e67-f564-436c-8af9-c9270f239ec9.png)


## Workflows

1. The most common workflow is to use NCC's standard 1km grid as the planning units, and the standard set of [national datasets](#national-datasets) that have been pre-prepped into the 1km grid. This workflow simply extracts the 1km planning units and the pre-prepped data for all planning units covering the AOI.

![image](https://user-images.githubusercontent.com/10728298/235223330-bdb782d5-83a5-4a9e-a61b-068a7d5681d1.png)

2. Some users may wish to add some additional datasets to workflow 1, to replace the standard national datasets with their own regional data, and/or to use a different sized planning unit grid. This requires the user to prepare thier own raster datasets to supplement the standard set of national data. This typically involves intersecting the data to the planning unit grid and summarizing the data values per planning unit. See the [regional_example](https://github.com/NCC-CNC/wtw-data-prep/tree/main/regional_example) folder for scripts to do this.

![image](https://user-images.githubusercontent.com/10728298/236043222-32bacd22-e097-4a51-b378-d39ce2f36093.png)

<br/>

3. Some users may wish to use a non-grided set of planning units. This involves intersecting the data to the planning units and providing shapefile instead of raster inputs to Where to Work. See the [shapefile_example](https://github.com/NCC-CNC/wtw-data-prep/tree/main/shapefile_example) folder for scripts to do this.

> **Note** Users using custom planning units who want to add the standard national datasets will need to access the original raster or vector versions of these datasets and apply them in workflow 2 or 3. The pre-prepped [national datasets](#national-datasets) can only be used with the standard NCC 1km grid.


## Definitions

**NCC grid** - the NCC 1km that covers all of Canada.

**AOI** - area of interest, usually a polygon defining the study region for a WTW project.

**Planning units (PU)** - the 'building blocks' used in WTW to construct solutions. In workflow 1 the PU's are the NCC grid cells that intersect with the AOI. In other workflows PU's could be a different sized grid, or any collection of non-overlapping polygons. The goal of the data prep workflow is to summarise each input dataset within each planning unit.

**Input datasets** - The data representing Themes, Weights, Includes and Excludes to be used in WTW. Each inut dataset needs to described by a single value in every planning unit.


## Where to Work data formats

There are three main formats that Where to Work will accept for loading data:

1. The four WTW input files desribed [below](#wtw_formatting.R), where the spatial input file is a raster and each planning unit is a cell in the raster grid.
This is the preferred input format because it's the fastest to prepare and load into WTW.

2. The four WTW input files desribed [below](#wtw_formatting.R), where the spatial input file is a shapefile and each planning unit is a polygon defined in the shapefile.
This is the preferred input format when non-grid planning units are required (i.e. the planning units cannot be represented in a raster grid).

3. A single shapefile where each polygon represents a planning unit and each column in the attribute table represents a Theme, Includes, Excludes or Weight. This format is
not recommended because it's slower to load, and requires all WTW parameters to be set manually in the app instead of being defined in the input data. See the
[shapefile_example](https://github.com/NCC-CNC/wtw-data-prep/tree/main/shapefile_example) for more details.

## National data

The following scripts in this repo are used to prepare the standard [national datasets](#national-datasets) using the NCC 1km planning units (i.e. workflow 1 described above). More details on each script are provided in the [scripts](#script) section. We recommend making an empty project folder and using RStudio to start a new RSudio project in that folder. Copy the `scripts` folder from this repo into the project folder:

-   `01_initiate_project.R` - sets up folder structure, saves AOI.shp
-   `02_aoi_to_1km_grid.R` - extracts the NCC 1km grid cells intersecting the AOI. Saves the grid in vector and raster formats.
-   `03_natdata_to_1km_pu_grid.R` - extracts the pre-prepped national data to the 1km PU grid and saves as rasters in the **National** folder.
-   `04_populate_nat_metadata.R` - copies the required rasters to the **Tiffs** folder and uses them to prepare the metadata csv file.
-   `05_wtw_formatting.R` - Uses the **Tiffs** rasters and the metadata csv file to create the four WTW input files.
-   `functions` - folder containing functions needed by various scripts.
-   `data` - folder containing the NCC 1km raster template required by `02_aoi_to_1km_grid.R`.


## Regional data

Any user provided datasets that are not part of the standard [national datasets](#national-datasets) are referred to as **Regional data**. These are typically vector or raster layers that need to be summarized per planning unit. An example workflow for this is provided in the [regional_example](https://github.com/NCC-CNC/wtw-data-prep/tree/main/regional_example) folder.


## Data formats

WTW runs prioritizations using the values assigned to each planning unit from the input data. It's important that users of WTW understand what their data represent, especially for users adding their own data into the tool.

- **Area**, **length** or **count**: Many datasets simply represent the area, length or count of a given feature in each planning unit. Examples include species range data, the density of rivers or roads, or the count of specific sites.

- **Simple summaries** - Some data have their own units that are carried though to WTW. Examples include carbon storage which can be expressed as tonnes of C per planning unit. In this case the source data are raster values that can be summed within each planning unit.

- **Complex summaries** - Some data may require more complex summaries to get meaningful values per planning unit. An example could be the weighted average stream order for a user looking to prioritize headwaters.


## Projections

- Projects using the NCC national grid project all datasets into a WGS84 version of Canada Albers.
- Projects using a custom grid will use the projection of the provided AOI shapefile. Any user-provided data should be projected to match the planning units.


## Scripts

### `01_initiate_project.R`

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
      

### `02_aoi_to_1km_grid.R`

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


### `03_natdata_to_1km_pu_grid.R`

_Used in conjunction with aoi_to_1km_grid.R to extract pre-prepped 1km NATIONAL data to the planning units._

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

> **Warning** Data needed to run this script is not packaged in this repo.

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


### `04_populate_nat_metadata.R`

_Automates the creation of a metadata .csv table that is used in `05_wtw_formatting.R`._
_Once created, the metadata csv table should be manually QC'd before proceeding to  `05_wtw_formatting.R`._

> **Note** If using REGIONAL data, the metadata table must be created manually (or edited manually if using both NATIONAL and REGIONAL data).

Inputs

- The prepared 1km x 1km raster NATIONAL raster layers created by `03_natdata_to_1km_pu_grid.R`.

Outputs

- All rasters are copied into the Tiffs folder
- The metadata csv table to be QC'd and passed to `05_wtw_formatting.R`

#### Metadata table columns
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


### `05_wtw_formatting.R`

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
> **Note** The spatial file can also be a shapefile where each planning unit is a different polygon. 

3. **attribute.csv.gz:** <br>
The attribute file defines the cell values of each theme, weight, include and exclude in tabular form. Each column in the .csv is a variable. 

4. **boundary.csv.gz:** <br>
The boundary file defines the adjacency table of each theme, weight, include and exclude. It stores information on the perimeter and shared boundary lengths of the planning units. This is needed to run optimizations for spatial clustering.

<br/>
<br/>
<br/>

# 
<div style="font-size:12px">Icons made by <a target="_blank" rel="noopener noreferrer" href="https://www.freepik.com" title="Freepik">Freepik</a> from <a target="_blank" rel="noopener noreferrer" href="https://www.flaticon.com/" title="Flaticon">www.flaticon.com</a>
      </div>
