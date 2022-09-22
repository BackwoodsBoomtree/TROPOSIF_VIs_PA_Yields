library(ncdf4)
library(parallel)

file_dir <- "/mnt/g/OCO2/B11/test"

file_list <- list.files(file_dir, recursive = TRUE, full.names = TRUE, pattern = "*.nc")

cosd <- function(degrees) {
  radians <- cos(degrees * pi / 180)
  return(radians)
}
sind <- function(degrees) {
  radians <- sin(degrees * pi / 180)
  return(radians)
}

add_pa <- function(oco_file){
  
  t_start <- Sys.time()
  
  message(paste0("Adding variables to: ", oco_file))
  
  myfile <- nc_open(oco_file)
  
  # Get variables for calculation
  vza     <- ncvar_get(myfile, varid = "VZA")
  sza     <- ncvar_get(myfile, varid = "SZA")
  saz     <- ncvar_get(myfile, varid = "SAz")
  vaz     <- ncvar_get(myfile, varid = "VAz")
  
  # Close file
  nc_close(myfile)
  
  # Calc PA
  raa <- abs(saz - vaz - 180)
  pa  <- acos(cosd(sza) * cosd(vza) + sind(vza) * sind(sza) * cosd(raa)) * 180. / pi
  
  # Change NaN, NA, Inf, -Inf to -9999 for nc fillvalue
  pa[!is.finite(pa)]               <- -9999
  
  # Write to file
  myfile   <- nc_open(oco_file, write = TRUE)
  elem_dim <- myfile$dim[['sounding_dim']]
  
  # If variables already exist overwrite. Else create and write.

  
  if ("PA" %in% names(myfile$var)) {
    
    ncvar_put(myfile, "PA", pa)
    
  } else {
    pa_var <- ncvar_def("PA", units ="degrees", dim = elem_dim, longname = "Phase Angle",
                        pre = "float", compression = 4, missval = -9999)
    ncvar_add(myfile, pa_var)
    nc_close(myfile)
    myfile <- nc_open(oco_file, write = TRUE)
    ncvar_put(myfile, pa_var, pa)
  }
  
  
  nc_close(myfile)
  
  t_end <- Sys.time()
  
  message(paste0("Done with ", basename(oco_file), ". ", (t_end - t_start)))
  
}

# for (i in 1:length(file_list)) {
#   add_pa(file_list[i])
# }

mclapply(file_list, add_pa, mc.cores = 10, mc.preschedule = FALSE)