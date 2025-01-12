#!/bin/bash

### This script computes an image of voxels with good signal based on the temporal mean and standard deviation of each of them.
### The greater the standard deviation with respect to the mean the more they are likely to be non-BOLD signal voxels.
### Mandatory input positional arguments are:
### 	- DataFolder: Directory where the fmri image is stored
### 	- OutFolder: Directory where the output files are to be stored
###	    - NeighborhoodSmoothing: Sigma of the kernel for smoothing the cov image

fmriFolder=$1
OutFolder=$2
Subject=$3
Ses=$4
NeighborhoodSmoothing=$5

fmriFolder=/media/BabyBrain/preterm/rel3_dhcp_fmri_pipeline/"${Subject}"/"${Ses}"/func
OutFolder=/media/BabyBrain/preterm/fMRI_Vol2Cifti/"${Subject}"_"${Ses}"

# Compute standard deviation and cov (mean/std ratio) volumes
fslmaths "${fmriFolder}"/"${Subject}"_"${Ses}"_task-rest_desc-preproc_bold.nii.gz -Tstd "${OutFolder}"/"${Subject}"_"${Ses}"_std.nii.gz -odt float
fslmaths "${OutFolder}"/"${Subject}"_"${Ses}"_std.nii.gz -div "${OutFolder}"/"${Subject}"_"${Ses}"_mean.nii.gz "${OutFolder}"/"${Subject}"_"${Ses}"_cov.nii.gz

fslmaths "${OutFolder}"/"${Subject}"_"${Ses}"_cov.nii.gz -mas "${OutFolder}"/"${Subject}"_"${Ses}"_ribbon_only.nii.gz "${OutFolder}"/"${Subject}"_"${Ses}"_cov_ribbon.nii.gz

# Preprocess cov image
fslmaths "${OutFolder}"/"${Subject}"_"${Ses}"_cov_ribbon.nii.gz -div $(fslstats "${OutFolder}"/"${Subject}"_"${Ses}"_cov_ribbon.nii.gz -M) "${OutFolder}"/"${Subject}"_"${Ses}"_cov_ribbon_norm.nii.gz
fslmaths "${OutFolder}"/"${Subject}"_"${Ses}"_cov_ribbon_norm.nii.gz -bin -s "$NeighborhoodSmoothing" "${OutFolder}"/"${Subject}"_"${Ses}"_SmoothNorm.nii.gz
fslmaths "${OutFolder}"/"${Subject}"_"${Ses}"_cov_ribbon_norm.nii.gz -s "$NeighborhoodSmoothing" -div "${OutFolder}"/"${Subject}"_"${Ses}"_SmoothNorm.nii.gz -dilD "${OutFolder}"/"${Subject}"_"${Ses}"_cov_ribbon_norm_s"${NeighborhoodSmoothing}"
fslmaths "${OutFolder}"/"${Subject}"_"${Ses}"_cov -div $(fslstats "${OutFolder}"/"${Subject}"_"${Ses}"_cov_ribbon -M) -div "${OutFolder}"/"${Subject}"_"${Ses}"_cov_ribbon_norm_s"${NeighborhoodSmoothing}" "${OutFolder}"/"${Subject}"_"${Ses}"_cov_norm_modulate
fslmaths "${OutFolder}"/"${Subject}"_"${Ses}"_cov_norm_modulate -mas "${OutFolder}"/"${Subject}"_"${Ses}"_ribbon_only.nii.gz "${OutFolder}"/"${Subject}"_"${Ses}"_cov_norm_modulate_ribbon

# Print stats
STD=$(fslstats "${OutFolder}"/"${Subject}"_"${Ses}"_cov_norm_modulate_ribbon.nii.gz -S)
echo "std:" "$STD"
MEAN=$(fslstats "${OutFolder}"/"${Subject}"_"${Ses}"_cov_norm_modulate_ribbon.nii.gz -M)
echo "mean:" "$MEAN"
Lower=$(echo "$MEAN - ($STD * 0.5)" | bc -l)
echo "Lower:" "$Lower"
Upper=$(echo "$MEAN + ($STD * 0.5)" | bc -l)
echo "Upper:" "$Upper"

fslmaths "${OutFolder}"/"${Subject}"_"${Ses}"_mean.nii.gz -bin "${OutFolder}"/"${Subject}"_"${Ses}"_mask.nii.gz
fslmaths "${OutFolder}"/"${Subject}"_"${Ses}"_cov_norm_modulate.nii.gz -thr "$Upper" -bin -sub "${OutFolder}"/"${Subject}"_"${Ses}"_mask.nii.gz -mul -1 "${OutFolder}"/"${Subject}"_"${Ses}"_goodvoxels.nii.gz
