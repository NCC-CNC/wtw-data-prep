# Shapefile data prep example

The preferred input format for Where to Work is to use raster data where each raster cell is a different planning unit and
the raster cell values represent the amount of each feature in each planning unit. 
This workflow is described in the main [readMe](https://github.com/NCC-CNC/wtw-data-prep) of this repo.
In some cases a user may want planning units that are not square grid cells and cannot be represented as a raster. For these
cases, Where to Work can accept planning unit input data as shapefiles in the following two formats:

**1. Four standard WTW input files, with shapefile planning units:** The four WTW input files described in the 
[readMe](https://github.com/NCC-CNC/wtw-data-prep), where the spatial input file is a shapefile and each planning unit is a 
polygon defined in the shapefile. The other three input files are the same as the standard raster workflow. This is the preferred 
input format when non-grid  planning units are required (i.e. the planning units cannot be represented in a raster grid).

![image](https://user-images.githubusercontent.com/10728298/236540944-baa83277-74de-4d87-aa29-03d57a9c5d61.png)

The scripts to run this workflow are similar to those in the [regional_example]([https://github.com/NCC-CNC/wtw-data-prep/regional_example)](https://github.com/NCC-CNC/wtw-data-prep/tree/main/regional_example)) 
folder. The main changes are that instead of creating raster planning units we use a shapefile of polygons. The other change is to the 
`wtw_formatting.R` script which has some edits to deal with the vector data planning units.

**2. Single shapefile containing all input values:** A single shapefile where each polygon represents a planning unit and each column in 
the attribute table represents values for a Theme, Includes, Excludes or Weight. The shapefile can be loaded into Where to Work using 
the **upload shapefile** option. Once loaded, some dropdown options will appear where the user can assign each input column to a Theme, 
Weight, Include or Exclude.

Due to the processing required for Where to Work to load and interpret the data (and select color schemes and legends for each feature), 
the number of columns in the shapefile should be limited to approximately 10. This input format is generally not recommended because 
it's slower to load, and requires all WTW parameters to be set manually in the app instead of being defined in the input data. It also
offers the user less control over the colors and legends, and it cannot process as many input datasets.

![image](https://user-images.githubusercontent.com/10728298/236546666-d2c237ee-eede-4d74-ab1e-722b8acb0c99.png)

The input shapefile for this workflow is the same shapefile passed to `07_wtw_formatting.R` in the scripts described below.
It is the result of intersecting and extracting all input data into the planning unit shapefile. The only reason to use this format
is for users who do not have access to these scripts and need to prepare the shapefile manually in a GIS software.


## Example workflow scripts

See the [regional_example](https://github.com/NCC-CNC/wtw-data-prep/regional_example) readMe for details on how to prepare the
input data.

#### 01_initiate_project.R

- This is the standard script to initiate a project folder using a user provided
AOI shapefile.

#### 02_aoi_to_hex.R

- This script creates some example hexagons covering the AOI. In a real project,
any shapefile of polygons could be used here. The polygons do not have to be touching
and do not have to cover the entire AOI.

#### 03_initialize_metadata.R

- This scripts creates the meta data table and attempts to fill it using the
datasets stored in the `Regional` folder.
- All data must in .gdb and .tif formats for this script to work. If other
formats are required, contact marc.edwards@natureconservancy.ca.

#### 04a_check_vectors.py

- This is an optional script to check for overlaps and duplicates in vector
datasets.
- A warning message is displayed for each dataset containing overlaps.
- All geodatabase feature classes in the Themes, Includes, Excludes and Weights
folders are checked.

#### 04b_intersect_regional_vectors.py

- This script intersects all vector data with the planning units using the
ArcGIS Intersect tool. No dissolving is done so input data need to be clean
before running the script (i.e. no overlaps).
- All geodatabase feature classes in the Themes, Includes, Excludes and Weights
folders are processed.

#### 05a_vector_variables_to_grid.R

- Uses the intersected vector data to summarise data into the planning units.
- This scripts only calculates area per planning unit for polygon data, length
per planning unit for line data, and the count per planning unit for point data.
- Any other data summaries need to be done with a separate script.
- Data values are summed per planning unit and added to the planning unit vector
file. The planning unit file contains one column per input dataset and one row
per planning unit. Columns are named using the Unique_id value specified in
the meta data table which links the column to its corresponding input dataset.

#### 05c_raster_variables_to_grid.R

- This scripts sums raster values into the planning units.
- Rasters are grouped into those representing areas as 1's and 0's and those
representing non-areal values.
- The area rasters are converted into the area covering each planning unit.
- The non-area rasters are simply summed within each planning unit.
- If other summary calculations are needed, an additional custom script would
be required.

> **Note** At this stage, the shapefile of planning units containing the summarised
input values can be loaded into Where to Work using the **uplod shapefile**
option. The recommended workflow however is to pass this shapefile into 
`07_wtw_formatting.R`.

#### 07_wtw_formatting_shp.R

- This script prepares the Where to Work input files. It uses the
meta data table and the planning unit shapefile to create the four Where to Work 
input files. This script is an adapted version of 
[wtw-data-prep/scripts/05_wtw_formatting.R](https://github.com/NCC-CNC/wtw-data-prep/blob/main/scripts/05_wtw_formatting.R)
which creates shapefile instead of raster planning units.
