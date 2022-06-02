#!/bin/bash

### This script computes an image of voxels with good signal based on the temporal mean and standard deviation of each of them.
### The greater the standard deviation with respect to the mean the more they are likely to be non-BOLD signal voxels.
### Mandatory input positional arguments are:
### 	- DataFolder: Directory where the fmri image is stored
### 	- OutFolder: Directory where the output files are to be stored
###	    - NeighborhoodSmoothing: Sigma of the kernel for smoothing the cov image

DataFolder=$1
OutFolder=$2
NeighborhoodSmoothing=$3

# Compute standard deviation and cov (mean/std ratio) volumes
fslmaths"${DataFolder}"/preproc_rest.nii.gz -Tstd "${OutFolder}"/std.nii.gz -odt float
fslmaths "${OutFolder}"/std.nii.gz -div "${OutFolder}"/mean.nii.gz "${OutFolder}"/cov.nii.gz

fslmaths "${OutFolder}"/cov.nii.gz -mas "${OutFolder}"/ribbon_only.nii.gz "${OutFolder}"/cov_ribbon.nii.gz

# Preprocess cov image
fslmaths "${OutFolder}"/cov_ribbon.nii.gz -div "$(fslstats "${OutFolder}"/cov_ribbon.nii.gz -M)" "${OutFolder}"/cov_ribbon_norm.nii.gz
fslmaths "${OutFolder}"/cov_ribbon_norm.nii.gz -bin -s "$NeighborhoodSmoothing" "${OutFolder}"/SmoothNorm.nii.gz
fslmaths "${OutFolder}"/cov_ribbon_norm.nii.gz -s "$NeighborhoodSmoothing" -div "${OutFolder}"/SmoothNorm.nii.gz -dilD "${OutFolder}"/cov_ribbon_norm_s"${NeighborhoodSmoothing}"
fslmaths "${OutFolder}"/cov -div "$(fslstats "${OutFolder}"/cov_ribbon -M)" -div "${OutFolder}"/cov_ribbon_norm_s"${NeighborhoodSmoothing}" "${OutFolder}"/cov_norm_modulate
fslmaths "${OutFolder}"/cov_norm_modulate -mas "${OutFolder}"/ribbon_only.nii.gz "${OutFolder}"/cov_norm_modulate_ribbon

# Print stats
STD=$(fslstats "${OutFolder}"/cov_norm_modulate_ribbon.nii.gz -S)
echo "$STD"
MEAN=$(fslstats "${OutFolder}"/cov_norm_modulate_ribbon.nii.gz -M)
echo "$MEAN"
Lower=$(echo "$MEAN - ($STD * 0.5)" | bc -l)
echo "$Lower"
Upper=$(echo "$MEAN + ($STD * 0.5)" | bc -l)
echo "$Upper"

fslmaths "${OutFolder}"/mean.nii.gz -bin "${OutFolder}"/mask.nii.gz
fslmaths "${OutFolder}"/cov_norm_modulate.nii.gz -thr "$Upper" -bin -sub "${OutFolder}"/mask.nii.gz -mul -1 "${OutFolder}"/goodvoxels.nii.gz
