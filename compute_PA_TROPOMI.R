library(ncdf4)

file_dir <- "G:/TROPOMI/esa/original"

file_list <- list.files(file_dir, recursive = TRUE, full.names = TRUE, pattern = "*.nc")

cosd <- function(degrees) {
  radians <- cos(degrees * pi / 180)
  return(radians)
}
sind <- function(degrees) {
  radians <- sin(degrees * pi / 180)
  return(radians)
}
add_PA <- function(tropomi_file){
  
  myfile <- nc_open(tropomi_file)
  
  # Get angles
  vza <- ncvar_get(myfile, varid = "PRODUCT/SUPPORT_DATA/GEOLOCATIONS/viewing_zenith_angle")
  sza <- ncvar_get(myfile, varid = "PRODUCT/SUPPORT_DATA/GEOLOCATIONS/solar_zenith_angle")
  raa <- ncvar_get(myfile, varid = "PRODUCT/SUPPORT_DATA/GEOLOCATIONS/relative_azimuth_angle")
  
  # Calculate PA (can return NaN when dividing by 0, so we need to do this recursively)
  pa  <- c()
  
  for (i in 1:length(vza)) {
      pa[i]  <- acos(cosd(sza[i]) * cosd(vza[i]) + sind(vza[i]) * sind(sza[i]) * cosd(raa[i])) * 180. / pi
  }
  
  # Close then open for writing
  nc_close(myfile)
  myfile <- nc_open(tropomi_file, write = TRUE)
  
  elem_dim <- myfile$dim[['n_elem']]
  
  # Define variables that will be added to nc file
  pa_var     <- ncvar_def("PRODUCT/SUPPORT_DATA/GEOLOCATIONS/phase_angle", units ="degrees", dim = elem_dim, longname = "Phase Angle",
                            pre = "float", compression = 4, missval = -9999)

  # Add the variables to the file
  ncvar_add(myfile, pa_var)

  # Close then open for writing
  nc_close(myfile)
  myfile <- nc_open(tropomi_file, write = TRUE)
  
  # Write data
  ncvar_put(myfile, pa_var, pa)

  # Close
  nc_close(myfile)
  
  print(paste0("Done with ", basename(tropomi_file)))
  
}

for (i in file_list) {
  add_PA(i)
}
