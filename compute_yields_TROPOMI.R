library(ncdf4)
library(parallel)

file_dir <- "mnt/g/TROPOMI/esa/original"

file_list <- list.files(file_dir, recursive = TRUE, full.names = TRUE, pattern = "*.nc")


add_yields <- function(tropomi_file){
  
  t_start <- Sys.time()
  
  myfile <- nc_open(tropomi_file)
  
  # Get angles
  sif   <- ncvar_get(myfile, varid = "PRODUCT/SIF_743")
  nirvr <- ncvar_get(myfile, varid = "PRODUCT/NIRv_RAD")
  rad   <- ncvar_get(myfile, varid = "PRODUCT/SUPPORT_DATA/DETAILED_RESULTS/Mean_TOA_RAD_743")
  
  # Calculate PA (can return NaN when dividing by 0, so we need to do this recursively)
  sif_rel   <- c()
  sif_nirvr <- c()
  
  for (i in 1:length(sif)) {
    sif_rel[i]  <- sif[i] / rad[i]
    sif_nirvr   <- sif[i] / nirvr[i]
  }
  
  # Close then open for writing
  nc_close(myfile)
  myfile <- nc_open(tropomi_file, write = TRUE)
  
  elem_dim <- myfile$dim[['n_elem']]
  
  # Define variables that will be added to nc file
  sif_rel_var   <- ncvar_def("PRODUCT/SIF_Rel", units ="mW/m2/sr/nm", dim = elem_dim, longname = "SIF Relative (SIF_743 / Mean_TOA_RAD_743",
                          pre = "float", compression = 4, missval = -9999)
  sif_nirvr_var <- ncvar_def("PRODUCT/SIF_NIRv_RAD", units ="mW/m2/sr/nm", dim = elem_dim, longname = "SIF_743 / NIRv_RAD",
                               pre = "float", compression = 4, missval = -9999)
  
  # Add the variables to the file
  ncvar_add(myfile, sif_rel_var)
  ncvar_add(myfile, sif_nirvr_var)
  
  # Close then open for writing
  nc_close(myfile)
  myfile <- nc_open(tropomi_file, write = TRUE)
  
  # Write data
  ncvar_put(myfile, sif_rel_var, sif_rel)
  ncvar_put(myfile, sif_nirvr_var, sif_nirvr)
  
  # Close
  nc_close(myfile)
  
  t_end <- Sys.time()
  
  print(paste0("Done with ", basename(tropomi_file), ". ", t_end - t_start))
  
}


mclapply(file_list, add_yields, mc.cores = 3, mc.preschedule = FALSE)