#!/bin/bash

### This script computes a one-hemisphere ribbon volume from white and pial surfaces and a reference image (mean fMRI or SBRef).
### Mandatory input positional arguments are:
### 	- DataFolder: Directory where the surfaces are stored
### 	- OutFolder: Directory where the resulting images are to be stored
###	- RefImg: Complete path to the reference image
###	- hemi: The hemisphere to be computed as spelled in the surface files
###	- GreyRibbonValue: The value of the grey ribbon voxels in the output image

DataFolder=$1
OutFolder=$2
RefImg=$3
hemi=$4
GreyRibbonValue=$5

# Compute shortest distance from each voxel to surfaces
wb_command -create-signed-distance-volume "${DataFolder}"/hemi-"${hemi}"_white.surf.gii "${RefImg}" "${OutFolder}"/"${hemi}".white.native.nii.gz
wb_command -create-signed-distance-volume "${DataFolder}"/hemi-"${hemi}"_pial.surf.gii "${RefImg}" "${OutFolder}"/"${hemi}".pial.native.nii.gz
 
# Get voxels out of WM surface
fslmaths "${OutFolder}"/"${hemi}".white.native.nii.gz -thr 0 -bin -mul 255 "${OutFolder}"/"${hemi}".white_thr0.native.nii.gz
fslmaths "${OutFolder}"/"${hemi}".white_thr0.native.nii.gz -bin "${OutFolder}"/"${hemi}".white_thr0.native.nii.gz

# Get voxels into Pial surface
fslmaths "${OutFolder}"/"${hemi}".pial.native.nii.gz -uthr 0 -abs -bin -mul 255 "${OutFolder}"/"${hemi}".pial_uthr0.native.nii.gz
fslmaths "${OutFolder}"/"${hemi}".pial_uthr0.native.nii.gz -bin "${OutFolder}"/"${hemi}".pial_uthr0.native.nii.gz

# Get intersecting voxels between two masks
fslmaths "${OutFolder}"/"${hemi}".pial_uthr0.native.nii.gz -mas "${OutFolder}"/"${hemi}".white_thr0.native.nii.gz -mul 255 "${OutFolder}"/"${hemi}".ribbon.nii.gz
fslmaths "${OutFolder}"/"${hemi}".ribbon.nii.gz -bin -mul "${GreyRibbonValue}" "${OutFolder}"/"${hemi}".ribbon.nii.gz
