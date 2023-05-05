# Script to intersect vector data with grid
#
# This script will sum areas per planning unit for polygon data, lengths per planning unit for polyline data,
# and counts per planning unit for point data. Any other data types should be calculated separately.
#
# For Themes, all vector data for a given theme must be inside a .gdb in a folder with the Theme name, inside folder Themes
# For Includes, all vector data must be in a .gdb inside a folder named Include
# For Weights, all vector data must be inside a .gdb inside a folder named Weights
# For Excludes, all vector data must be inside a .gdb inside a folder named Excludes

# Example folder structure:
#
# Regional
#  |
#  |-Themes
#  |   |-Species
#  |   |   |-species.gdb
#  |   |-Forest
#  |   |   |-forest.gdb
#  |-Includes
#  |   |-include.gdb
#  |-Weights
#  |   |-weights.gdb

import arcpy, os
arcpy.env.overwriteOutput = True


grid = "../PU/PU.shp" # <--- path to planning units grid
out_gdb = "../Regional/Intersections.gdb" # <--- path to output folder for intersections

themes_dir = "../Regional/Themes" # <--- path to themes data sub-folders
includes_dir = "../Regional/Includes" # <--- path to includes data folder
weights_dir = "../Regional/Weights" # <--- path to weights data folder
excludes_dir = "../Regional/Excludes" # <--- path to excludes data folder


# Functions
#-----------------------------------------------------------------
def get_gdb_layers(search_dir):

    # returns paths to all feature classes inside all .gdbs residing in search_dir
    
    in_gdb_list = []
    layers = []

    for file in os.listdir(search_dir):
        if file.endswith(".gdb"):
            in_gdb_list.append(os.path.join(search_dir, file))
            
    # loop over gdb's in list
    for in_gdb in in_gdb_list:
        #print(in_gdb)
        arcpy.env.workspace = in_gdb

        # get any feature classes directly in the gdb
        fcList = arcpy.ListFeatureClasses()
        #print(fcList)
        for fc in fcList:
                layers.append(os.path.join(in_gdb, fc))

        # get any features classes inside feature datasets inside the gdb
        datasets = arcpy.ListDatasets(feature_type = 'feature')
        #print(datasets)
        for dataset in datasets:
            arcpy.env.workspace = os.path.join(in_gdb, dataset)
            fcList = arcpy.ListFeatureClasses()
            for fc in fcList:
                layers.append(os.path.join(in_gdb, dataset, fc))

    arcpy.env.workspace = os.path.dirname(os.path.realpath(__file__)) # reset arcpy working dir
    return layers


def run_intersect(fc, grid, out_suff, out_gdb):

    # dissolves fc if line or polygon, then intersects with grid

    desc = arcpy.Describe(fc)
    name = desc.name
    print("Intersecting: " + name)
    arcpy.analysis.Intersect([grid, fc], "{}/{}".format(out_gdb, out_suff + name))


#-----------------------------------------------------------------
    
# Create out_gdb
if not arcpy.Exists(out_gdb):
    arcpy.CreateFileGDB_management(os.path.dirname(out_gdb), os.path.basename(out_gdb))

#-----------------------------------------------------------------
        
# THEMES ---------------------------------------------------------
# search for geodatabase feature classes in all sub-folders (Theme groups)

# get all sub-folders in Themes
sub_themes = os.listdir(themes_dir)

# loop over sub-themes
for sub_theme in sub_themes:

    # find all gdb feature classes in folder
    layers = get_gdb_layers(os.path.join(themes_dir, sub_theme))

    # proceed if there are layers
    if len(layers) > 0:

        print("\n\nProcessing Theme: " + sub_theme)

        # dissolve and intersect
        for layer in layers:
            run_intersect(layer, grid, "T_", out_gdb)


# INCLUDES ------------------------------------------------------
# find all gdb feature classes in folder
if os.path.exists(includes_dir):
    layers = get_gdb_layers(includes_dir)

# proceed if there are layers
if len(layers) > 0:

    print("\n\nProcessing Includes")
    
    # dissolve and intersect
    for layer in layers:
        run_intersect(layer, grid, "I_", out_gdb)

# WEIGHTS ------------------------------------------------------
# find all gdb feature classes in folder
if os.path.exists(weights_dir):
    layers = get_gdb_layers(weights_dir)

# proceed if there are layers
if len(layers) > 0:

    print("\n\nProcessing Weights")
    
    # dissolve and intersect
    for layer in layers:
        run_intersect(layer, grid, "W_", out_gdb)

# EXCLUDES ------------------------------------------------------
# find all gdb feature classes in folder
if os.path.exists(excludes_dir):
    layers = get_gdb_layers(excludes_dir)

# proceed if there are layers
if len(layers) > 0:

    print("\n\nProcessing Excludes")
    
    # dissolve and intersect
    for layer in layers:
        run_intersect(layer, grid, "E_", out_gdb)
