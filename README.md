# TROPOSIF_VIs_PA_Yields

This script computes NDVI, NIRv, NIRv Radiance, phase angle, relative SIF, and one proxy of SIFyield (SIF / NIRv Radiance) at the sounding level for the L2 TROPOMI ESA SIF files and then adds them back into the existing files.

## Workflow

All calculations are now in a single script. It checks if the variable is already defined in the ncfile, and if so overwrites what is there. If not, it creates the variable and adds it to the file. This is done so that variables can be recalculated if needed for whatever reason.

## Notes

NIRv Radiance does not use the same 781 band as NIRv, as TOA Radiance is provided as an average at 743-758.

The use of this simple R script is very fast and more efficient than trying to add this calculation to the Julia gridding script. 
