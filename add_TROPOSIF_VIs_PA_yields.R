library(ncdf4)
library(parallel)

file_dir <- "/mnt/g/TROPOMI/esa/original"

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
  
  # Calc VIs
  ndvi  <- (ref_781 - ref_665) / (ref_781 + ref_665)
  nirv  <- ndvi * ref_781
  nirvr <- ndvi * rad
  
  # Calc PA
  pa  <- acos(cosd(sza) * cosd(vza) + sind(vza) * sind(sza) * cosd(raa)) * 180. / pi
  
  # Calc Yields
  sif_rel   <- sif / rad
  sif_nirvr <- sif / nirvr
  
  # Change NaN, NA, Inf, -Inf to -9999 for nc fillvalue
  ndvi[!is.finite(ndvi)]           <- -9999
  nirv[!is.finite(nirv)]           <- -9999
  nirvr[!is.finite(nirvr)]         <- -9999
  pa[!is.finite(pa)]               <- -9999
  sif_rel[!is.finite(sif_rel)]     <- -9999
  sif_nirvr[!is.finite(sif_nirvr)] <- -9999
  
  # Write to file
  myfile   <- nc_open(tropomi_file, write = TRUE)
  elem_dim <- myfile$dim[['n_elem']]
  
  # If variables already exist overwrite. Else create and write.
  
  if ("PRODUCT/NDVI" %in% names(myfile$var)) {
    
    ncvar_put(myfile, "PRODUCT/NDVI", ndvi)
    
  } else {
    ndvi_var <- ncvar_def("PRODUCT/NDVI", units ="-", dim = elem_dim, longname = "Normalized Difference Vegetation Index",
                              pre = "float", compression = 4, missval = -9999)
    ncvar_add(myfile, ndvi_var)
    nc_close(myfile)
    myfile <- nc_open(tropomi_file, write = TRUE)
    ncvar_put(myfile, ndvi_var, ndvi)
  }
  
  if ("PRODUCT/NIRv" %in% names(myfile$var)) {
    
    ncvar_put(myfile, "PRODUCT/NIRv", nirv)
    
  } else {
    nirv_var <- ncvar_def("PRODUCT/NIRv", units ="-", dim = elem_dim, longname = "NIR Reflectance of Vegetation",
                              pre = "float", compression = 4, missval = -9999)
    ncvar_add(myfile, nirv_var)
    nc_close(myfile)
    myfile <- nc_open(tropomi_file, write = TRUE)
    ncvar_put(myfile, nirv_var, nirv)
  }
  
  if ("PRODUCT/NIRv_RAD" %in% names(myfile$var)) {
    
    ncvar_put(myfile, "PRODUCT/NIRv_RAD", nirvr)
    
  } else {
    nirvr_var <- ncvar_def("PRODUCT/NIRv_RAD", units ="mW/m2/sr/nm", dim = elem_dim, longname = "NIRv Radiance",
                              pre = "float", compression = 4, missval = -9999)
    ncvar_add(myfile, nirvr_var)
    nc_close(myfile)
    myfile <- nc_open(tropomi_file, write = TRUE)
    ncvar_put(myfile, nirvr_var, nirvr)
  }
  
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
  
  if ("PRODUCT/SIF_Rel" %in% names(myfile$var)) {
    
    ncvar_put(myfile, "PRODUCT/SIF_Rel", sif_rel)
    
  } else {
    sif_rel_var   <- ncvar_def("PRODUCT/SIF_Rel", units ="mW/m2/sr/nm", dim = elem_dim, longname = "SIF Relative (SIF_743 / Mean_TOA_RAD_743)",
                               pre = "float", compression = 4, missval = -9999)
    ncvar_add(myfile, sif_rel_var)
    nc_close(myfile)
    myfile <- nc_open(tropomi_file, write = TRUE)
    ncvar_put(myfile, sif_rel_var, sif_rel)
  }
  
  if ("PRODUCT/SIF_NIRv_RAD" %in% names(myfile$var)) {
    
    ncvar_put(myfile, "PRODUCT/SIF_NIRv_RAD", sif_nirvr)
    
  } else {
    sif_nirvr_var <- ncvar_def("PRODUCT/SIF_NIRv_RAD", units ="mW/m2/sr/nm", dim = elem_dim, longname = "SIF_743 / NIRv_RAD",
                               pre = "float", compression = 4, missval = -9999)
    ncvar_add(myfile, sif_nirvr_var)
    nc_close(myfile)
    myfile <- nc_open(tropomi_file, write = TRUE)
    ncvar_put(myfile, sif_nirvr_var, sif_nirvr)
  }

  nc_close(myfile)

  t_end <- Sys.time()
  
  print(paste0("Done with ", basename(tropomi_file), ". ", (t_end - t_start)))
  
}

mclapply(file_list, add_vis_pa_yields, mc.cores = 10, mc.preschedule = FALSE)