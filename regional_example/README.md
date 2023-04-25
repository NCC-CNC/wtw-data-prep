# Regional data prep example

This folder contains an example of prepping regional data into a custom set of
planning units. The inputs are vector and raster datasets that we want to use
in Where to Work. The general workflow is as follows:

1. Create a shapefile of planning units
2. Prepare a meta data table used to process the data
3. Intersect all of the input data into the planning units
4. Convert planning unit values to standardized rasters
5. Use the rasters and meta data to create the Where to Work input files.

This workflow uses some of the standard scripts such as `initiate_project.R`, 
`aoi_to_custom_grid.R` amd `wtw_formatting.R`. It also adds a number of
additional scripts to prepare, check and intersect the vector and raster
data.

:note: These scripts provide a semi-automated workflow to help users prep data.
Users do however need to have a good understanding of their data before
running these scripts. Different data formats can be accommodated and users
need to understand their data in order to select the correct workflows. Users
also need a basic understanding of R to run these scripts.

## Input data
No data are provided with these example scripts. Test data can be requested from
dan.wismer@natureconservancy.ca or marc.edwards@natureconservancy.ca. You can 
also provide your own data as described below.

These scripts use a pre-defined folder structure to automate parts of the
workflow. Users should prep their data by ensuring all input data use the same
projection, and that vector data do not have overlapping polygons which can
lead to double counting of features within planning units. The input data should
be organized into the following folder structure and copied into the `Regional`
folder after initializing the project:

|--- Regional <br>
|&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|--- Themes <br>
|&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|--- Theme-1 <br>
|&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|--- Theme-2 <br>
|&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|--- Theme-3 <br>
|&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|--- Includes <br>
|&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|--- Excludes <br>
|&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|--- Weights <br>
    

All vector data in a given folder should be stored in (one or multiple) file
geodatabses. All raster data should be stored in .tif files. All Theme data should
be stored in sub-folders where the sub-folder name is the Theme name. For 
example a real input data folder might look like this:

|--- Regional <br>
|&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|--- Themes <br>
|&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|--- Forest <br>
|&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|--- forested.gdb <br>
|&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|--- rare_trees <br>
|&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|--- forest_cover.tif <br>
|&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|--- Aquatic <br>
|&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|--- wetlands.gdb <br>
|&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|--- fen_polygons <br>
|&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|--- bog_polygons <br>
|&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|--- marsh_polygons <br>
|&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|--- Species <br>
|&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|--- cosewic_1.tif <br>
|&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|--- cosewic_2.tif <br>
|&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|--- cosewic_3.tif <br>
|&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|--- cosewic_4.tif <br>
|&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|--- cosewic_5.tif <br>
|&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|--- Includes <br>
|&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|--- existing_protected_areas.tif <br>
|&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|--- Excludes <br>
|&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|--- low_intactness.tif <br>
|&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|--- Weights <br>
|&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|--- weights.gdb <br>
|&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|--- roads <br>
|&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|--- climate_refugia <br>

## Data formats
Where to Work prioritizes planning units based on planning unit values for
different data. Users need to understand what their input data represent and how
to summarize that data into the planning units. Some example data formats are
listed below:

**Common formats**

- **Areal coverage of polygons**: in this case we simply want to calculate the area
of the input polygons in each planning unit. For this format it's important to
remove overlaps in polygons to avoid double counting.
- **Length of linear features**: here we want to calculate the length of linear 
features (e.g. roads) in the planning units. Data should be checked for duplicate
features to avoid double counting.
- **Counts of points**: Here we simply count the number of points in each planning
unit.
- **Areal coverage of rasters**: Raster data representing areal coverage of a feature
should be prepped into 1/0 data where cell values of 1 represent feature presence.
We can then calculate the area of the 1's covering each planning unit.

**Unique formats**

- **Non-areal vector data**: some vector data may contain specific values we want to
carry forward to Where to Work. For example, we could summarize a stream dataset
to get the weighted average strahler order for streams in each planning unit.
This would allow us to prioritize higher or lower strahler orders in our
prioritization. An example of this is provided in 
`05b_complex_vector_variables_to_grid.R`.
- **Non-areal raster data**: many rasters have values we want to use in the Where to
Work prioritization. For example a raster of carbon storage may have units of
'tonnes of Carbon'. In this case we need to sum the raster values in each planning
unit to get a measure of tonnes per planning unit.

## Example workflow scripts

#### 01_initiate_project.R

- This is the standard script to initiate a project folder using a user provided
AOI shapefile.

#### 02_aoi_to_custom_grid.R

- This is the standard script to create a custom grid of planning units. The
script is currently set to create a 10 km x 10 km grid of planning units covering
the AOI polygon.

#### 03_initialize_metadata.R

- This scripts creates the meta data table and attempts to fill it using the
datasets stored in the `Regional` folder (using the folder format described in
[Input data](#input-data)).
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

#### 05b_complex_vector_variables_to_grid.R

- An example script for calculating more complex summaries of data into the 
planning units.
- In this example we will calculate the weighted average of stream strahler 
order per planning unit grid cell. We can use this as a weight in Where to Work
to prioritise planning units with higher or lower order streams.
- The goal is to add a new column with the calculated values to the planning units
grid. The column name should link to the layers meta data in the metadata table.
- Once complete, we need to manually complete the new row in the metadata table.

#### 05c_raster_variables_to_grid.R

- This scripts sums raster values into the planning units.
- Rasters are grouped into those representing areas as 1's and 0's and those
representing non-areal values.
- The area rasters are converted into the area covering each planning unit.
- The non-area rasters are simply summed within each planning unit.
- If other summary calculations are needed, an additional custom script would
be required.

#### 06_grid_to_raster.R
- This script converts the columns of values in the planning unit grid into
raster datasets with names defined in the meta data table.
- All rasters have the same extent, cell size and projection which is based on
the planning unit shapefile.

#### 07_wtw_formatting.R

- This is the standard script to prep Where to Work input files. It uses the
meta data table and the rasters to create the four Where to Work input files.
