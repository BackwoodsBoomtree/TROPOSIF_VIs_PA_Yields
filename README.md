# TROPOSIF_VIs_PA_Yields

This script computes NDVI, NIRv, NIRv Radiance, phase angle, relative SIF, and one proxy of SIFyield (SIF / NIRv Radiance) at the sounding level for the L2 TROPOMI ESA SIF files and then adds them back into the existing files.

I have added a second script that will add majority LC and majority percentage land cover from MCD12C1 for gridcell in which sounding falls. Should first reproject the MCD12C1 data using the reproject_mcd12.R script, otherwise reprojecting on the fly will take a LONG time.

## Workflow

TROPOMI files can be downloaded with a client in FTP mode and Anonymous login at ftp.sron.nl.

All calculations are now in a single script, with LC in a second script. They check if the variable is already defined in the ncfile, and if so overwrites what is there. If not, it creates the variable and adds it to the file. This is done so that variables can be recalculated if needed for whatever reason.

## Notes

Convert HDF data into GeoTiffs in WGS84 and save to disc so that the script does not need to reproject on the fly (MCD12 is 1866 Clarke), which is very time consuming.

SIF_735 is not good. Don not use it.

If the process is killed while operating, it will likely corrupt the open nc file and the originals will have to be downloaded again.

NIRv Radiance does not use the same 781 band as NIRv, as TOA Radiance is provided as an average at 743-758. Likewise for relative SIF.

The use of this simple R script is very fast and more efficient than trying to add this calculation to the Julia gridding script. 
