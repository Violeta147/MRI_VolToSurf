#!/bin/bash

### This script computes a one-hemisphere ribbon volume from white and pial surfaces and a reference image (mean fMRI or SBRef).
### Mandatory input positional arguments are:
### 	- DataFolder: Directory where the surfaces are stored
### 	- OutFolder: Directory where the resulting images are to be stored
###     - Subject ID
###     - Session ID
###	    - RefImg: Complete path to the reference image
###	    - hemi: The hemisphere to be computed as spelled in the surface files
###	    - GreyRibbonValue: The value of the grey ribbon voxels in the output image

DataFolder=$1
OutFolder=$2
Subject=$3
Session=$4
RefImg=$5
hemi=$6
GreyRibbonValue=$7

# Compute shortest distance from each voxel to surfaces
wb_command -create-signed-distance-volume "${DataFolder}"/"${Subject}"_"${Session}"_hemi-"${hemi}"_space-T2w_wm.surf.gii \
    "${RefImg}" "${OutFolder}"/"${Subject}"_"${Session}"_hemi-"${hemi}".white.native.nii.gz
wb_command -create-signed-distance-volume "${DataFolder}"/"${Subject}"_"${Session}"_hemi-"${hemi}"_space-T2w_pial.surf.gii \
    "${RefImg}" "${OutFolder}"/"${Subject}"_"${Session}"_hemi-"${hemi}".pial.native.nii.gz
 
# Get voxels out of WM surface
fslmaths "${OutFolder}"/"${Subject}"_"${Session}"_hemi-"${hemi}".white.native.nii.gz -add 1 -thr 0 -bin -mul 255 \
    "${OutFolder}"/"${Subject}"_"${Session}"_hemi-"${hemi}".white_thr0.native.nii.gz
fslmaths "${OutFolder}"/"${Subject}"_"${Session}"_hemi-"${hemi}".white_thr0.native.nii.gz -bin \
    "${OutFolder}"/"${Subject}"_"${Session}"_hemi-"${hemi}".white_thr0.native.nii.gz

# Get voxels into Pial surface
fslmaths "${OutFolder}"/"${Subject}"_"${Session}"_hemi-"${hemi}".pial.native.nii.gz -uthr 0 -abs -bin -mul 255 \
    "${OutFolder}"/"${Subject}"_"${Session}"_hemi-"${hemi}".pial_uthr0.native.nii.gz
fslmaths "${OutFolder}"/"${Subject}"_"${Session}"_hemi-"${hemi}".pial_uthr0.native.nii.gz -bin \
    "${OutFolder}"/"${Subject}"_"${Session}"_hemi-"${hemi}".pial_uthr0.native.nii.gz

# Get intersecting voxels between two masks
fslmaths "${OutFolder}"/"${Subject}"_"${Session}"_hemi-"${hemi}".pial_uthr0.native.nii.gz -mas \
    "${OutFolder}"/"${Subject}"_"${Session}"_hemi-"${hemi}".white_thr0.native.nii.gz -mul 255 \
    "${OutFolder}"/"${Subject}"_"${Session}"_hemi-"${hemi}".ribbon.nii.gz
fslmaths "${OutFolder}"/"${Subject}"_"${Session}"_hemi-"${hemi}".ribbon.nii.gz -bin -mul \
    "${GreyRibbonValue}" "${OutFolder}"/"${Subject}"_"${Session}"_hemi-"${hemi}".ribbon.nii.gz
