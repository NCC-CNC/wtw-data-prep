#' Writes national data rij matrix to raster.
#' 
#' @description
#' The matrix_to_raster function takes the `natdata_intersect` rij matrix and 
#' and converts it back to raster. 
#' 
#' @param ncc_1km_idx a [terra::rast] that has the NCC national grid index as values.
#' 
#' @param natdata_intersect a sparse matrix of class [dgCMatrix]. The 
#' natdata-aoi intersect matrix.
#' 
#' @param pu_1km a 1km [terra::rast]. This is the project planning units and
#'  is used to crop the converted `natdata_intersect` raster to the project
#'  PU extent.
#' 
#' @param output_folder a [character] path to output raster layers.
#' 
#' @param prefix a [character] string to append before the raster name. Helpful
#' for keeping standard naming (ex. `T_NAT_IUCN_BIRD_`, where: T == theme,
#' NAT == national and IUCN_BIRD == source.)
#' 
#' @param datatype a [character] string to define the raster output data type:
#' `LOG1S`, `INT1S`, `INT1U`, `INT2S`, `INT2U`, `INT4S`, `INT4U`, `FLT4S`, 
#' `FLT8S`

matrix_to_raster = function(ncc_1km_idx, 
                            natdata_intersect, 
                            pu_1km, 
                            output_folder, 
                            prefix, 
                            datatype) {
  
  # Set up placeholder raster
  natdata_raster <- ncc_1km_idx

  # Set up counter for print message
  len <-  (nrow(natdata_intersect)-2)
  counter <- 1
  
  if (len > 0) {
    # Loop through matrix, exclude AOI and Idx rows
    for (i in 1:(nrow(natdata_intersect)-2)) {
      natdata_raster[] <- NA # 26,790,000 planning units
      name <- rownames(natdata_intersect)[i]
      print(paste0("... ", counter, " of ", len, ": ",  name))
      natdata_raster[natdata_intersect["Idx",]] <- natdata_intersect[i,]
      names(natdata_raster) <- name
      ## crop raster to AOI
      cropped <- terra::crop(natdata_raster, pu_1km)
      ## write to disk
      writeRaster(cropped, paste0(output_folder, "/", prefix, name,".tif"),
                  overwrite = TRUE, datatype = datatype)
      
      ## advance counter
      counter <- counter + 1
    }
  
    } else {
      print("No pixels from this layer intersect the AOI") 
  }
}  
  

