library(ncdf4)

file_dir <- "G:/TROPOMI/esa/original"

file_list <- list.files(file_dir, recursive = TRUE, full.names = TRUE, pattern = "*.nc")

add_VIs <- function(tropomi_file){
  
  myfile <- nc_open(tropomi_file)
  
  # Get TOA radiance at 743-758
  rad <- ncvar_get(myfile, varid = "PRODUCT/SUPPORT_DATA/DETAILED_RESULTS/Mean_TOA_RAD_743")
  
  # Get reflectances
  ref_665 <- ncvar_get(myfile, varid = "PRODUCT/SUPPORT_DATA/DETAILED_RESULTS/TOA_RFL")[1,]
  ref_781 <- ncvar_get(myfile, varid = "PRODUCT/SUPPORT_DATA/DETAILED_RESULTS/TOA_RFL")[7,]
  
  # Calculate VIs (can return NaN when dividing by 0, so we need to do this recursively)
  ndvi     <- c()
  nirv     <- c()
  nirv_rad <- c()
  
  for (i in 1:length(ref_665)) {
    if (ref_665[i] != 0 && ref_781[i] != 0){
      ndvi[i]  <- (ref_781[i] - ref_665[i]) / (ref_781[i] + ref_665[i])
      nirv[i]  <- ndvi[i] * ref_781[i]
      nirv_rad[i] <- ndvi[i] * rad[i]
    } else {
      ndvi[i]     <- 0
      nirv[i]     <- 0
      nirv_rad[i] <- 0
    }
  }
  
  # Close then open for writing
  nc_close(myfile)
  myfile <- nc_open(tropomi_file, write = TRUE)
  
  elem_dim <- myfile$dim[['n_elem']]

  # Define variables that will be added to nc file
  ndvi_var     <- ncvar_def("PRODUCT/NDVI", units ="-", dim = elem_dim, longname = "Normalized Difference Vegetation Index",
                    pre = "float", compression = 4, missval = -9999)
  nirv_var     <- ncvar_def("PRODUCT/NIRv", units ="-", dim = elem_dim, longname = "NIR Reflectance of Vegetation",
                    pre = "float", compression = 4, missval = -9999)
  nirv_rad_var <- ncvar_def("PRODUCT/NIRv_RAD", units ="mW/m2/sr/nm", dim = elem_dim, longname = "NIRv Radiance",
                    pre = "float", compression = 4, missval = -9999)

  # Add the variables to the file
  ncvar_add(myfile, ndvi_var)
  ncvar_add(myfile, nirv_var)
  ncvar_add(myfile, nirv_rad_var)

  # Close then open for writing
  nc_close(myfile)
  myfile <- nc_open(tropomi_file, write = TRUE)

  # Write data
  ncvar_put(myfile, ndvi_var, ndvi)
  ncvar_put(myfile, nirv_var, nirv)
  ncvar_put(myfile, nirv_rad_var, nirv_rad)
  
  # Close
  nc_close(myfile)
  
  print(paste0("Done with ", basename(tropomi_file)))
  
}

for (i in file_list) {
  add_VIs(i)
}
