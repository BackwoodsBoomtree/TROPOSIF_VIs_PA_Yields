library(ncdf4)
library(parallel)

file_dir <- "/mnt/g/TROPOMI/new"

file_list <- list.files(file_dir, recursive = TRUE, full.names = TRUE, pattern = "*.nc")

cosd <- function(degrees) {
  radians <- cos(degrees * pi / 180)
  return(radians)
}
sind <- function(degrees) {
  radians <- sin(degrees * pi / 180)
  return(radians)
}

add_vis_pa_yields <- function(tropomi_file){
  
  t_start <- Sys.time()
  
  print(paste0("Adding variables to: ", tropomi_file))
  
  myfile <- nc_open(tropomi_file)
  
  # Get variables for calculation
  ref_665 <- ncvar_get(myfile, varid = "PRODUCT/SUPPORT_DATA/DETAILED_RESULTS/TOA_RFL")[1,]
  ref_781 <- ncvar_get(myfile, varid = "PRODUCT/SUPPORT_DATA/DETAILED_RESULTS/TOA_RFL")[7,]
  rad     <- ncvar_get(myfile, varid = "PRODUCT/SUPPORT_DATA/DETAILED_RESULTS/Mean_TOA_RAD_743")
  vza     <- ncvar_get(myfile, varid = "PRODUCT/SUPPORT_DATA/GEOLOCATIONS/viewing_zenith_angle")
  sza     <- ncvar_get(myfile, varid = "PRODUCT/SUPPORT_DATA/GEOLOCATIONS/solar_zenith_angle")
  raa     <- ncvar_get(myfile, varid = "PRODUCT/SUPPORT_DATA/GEOLOCATIONS/relative_azimuth_angle")
  sif     <- ncvar_get(myfile, varid = "PRODUCT/SIF_743")
  
  # Close file
  nc_close(myfile)
  
  # Calc PA
  pa  <- acos(cosd(sza) * cosd(vza) + sind(vza) * sind(sza) * cosd(raa)) * 180. / pi
  
  # Change NaN, NA, Inf, -Inf to -9999 for nc fillvalue
  pa[!is.finite(pa)]               <- -9999

  # Write to file
  myfile   <- nc_open(tropomi_file, write = TRUE)
  elem_dim <- myfile$dim[['n_elem']]
  
  # If variables already exist overwrite. Else create and write.
  
  if ("PRODUCT/SUPPORT_DATA/GEOLOCATIONS/phase_angle" %in% names(myfile$var)) {
    
    ncvar_put(myfile, "PRODUCT/SUPPORT_DATA/GEOLOCATIONS/phase_angle", pa)
    
  } else {
    pa_var <- ncvar_def("PRODUCT/SUPPORT_DATA/GEOLOCATIONS/phase_angle", units ="degrees", dim = elem_dim, longname = "Phase Angle",
                            pre = "float", compression = 4, missval = -9999)
    ncvar_add(myfile, pa_var)
    nc_close(myfile)
    myfile <- nc_open(tropomi_file, write = TRUE)
    ncvar_put(myfile, pa_var, pa)
  }
  
  nc_close(myfile)

  t_end <- Sys.time()
  
  print(paste0("Done with ", basename(tropomi_file), ". ", (t_end - t_start)))
  
}

mclapply(file_list, add_vis_pa_yields, mc.cores = 10, mc.preschedule = FALSE)