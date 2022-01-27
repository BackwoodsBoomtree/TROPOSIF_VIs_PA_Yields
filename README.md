# Compute_VIs_TROPOMI
Compute VIs at the sounding level

This script computes NDVI, NIRv, and NIRv Radiance at the sounding level from the L2 TROPOMI ESA SIF files and then adds them to the existing files.

Note that NIRv Radiance does not use the same 781 band as NIRv, as TOA Radiance is provided as an average at 743-758.

The use of this simple R script is very fast and more efficient than trying to add this calculation to the Julia gridding script. 
