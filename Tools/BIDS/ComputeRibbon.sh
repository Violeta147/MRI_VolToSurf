#!/bin/bash

### This script computes a one-hemisphere ribbon volume from white and pial surfaces and a reference image (mean fMRI or SBRef).
### Mandatory input positional arguments are:
### 	- DataFolder: Directory where the surfaces are stored
### 	- OutFolder: Directory where the resulting images are to be stored
###	- RefImg: Complete path to the reference image
###	- hemi: The hemisphere to be computed as spelled in the surface files
###	- GreyRibbonValue: The value of the grey ribbon voxels in the output image



AnatFolder=$1
OutFolder=$2
Subject=$3
Ses=$4
RefImg=$5
hemi=$6
GreyRibbonValue=$7

AnatFolder=/media/BabyBrain/preterm/dhcp_anat_pipeline/"${Subject}"/"${Ses}"/anat
OutFolder=/media/BabyBrain/preterm/fMRI_Vol2Cifti/"${Subject}"_"${Ses}"

# Check data:
echo "AnatFolder:" "${AnatFolder}"
echo "OutFolder:" "${OutFolder}"
echo "RefImg:" "${RefImg}"
echo "GreyRibbonValue:" "${GreyRibbonValue}"

# Compute shortest distance from each voxel to surfaces
wb_command -create-signed-distance-volume "${AnatFolder}"/"${Subject}"_"${Ses}"_hemi-"${hemi}"_space-T2w_wm.surf.gii "${RefImg}" "${OutFolder}"/"${Subject}"_"${Ses}"_"${hemi}".white.native.nii.gz
wb_command -create-signed-distance-volume "${AnatFolder}"/"${Subject}"_"${Ses}"_hemi-"${hemi}"_space-T2w_pial.surf.gii "${RefImg}" "${OutFolder}"/"${Subject}"_"${Ses}"_"${hemi}".pial.native.nii.gz
 
# Get voxels out of WM surface
fslmaths "${OutFolder}"/"${Subject}"_"${Ses}"_"${hemi}".white.native.nii.gz -thr 0 -bin -mul 255 "${OutFolder}"/"${Subject}"_"${Ses}"_"${hemi}".white_thr0.native.nii.gz
fslmaths "${OutFolder}"/"${Subject}"_"${Ses}"_"${hemi}".white_thr0.native.nii.gz -bin "${OutFolder}"/"${Subject}"_"${Ses}"_"${hemi}".white_thr0.native.nii.gz

# Get voxels into Pial surface
fslmaths "${OutFolder}"/"${Subject}"_"${Ses}"_"${hemi}".pial.native.nii.gz -uthr 0 -abs -bin -mul 255 "${OutFolder}"/"${Subject}"_"${Ses}"_"${hemi}".pial_uthr0.native.nii.gz
fslmaths "${OutFolder}"/"${Subject}"_"${Ses}"_"${hemi}".pial_uthr0.native.nii.gz -bin "${OutFolder}"/"${Subject}"_"${Ses}"_"${hemi}".pial_uthr0.native.nii.gz

# Get intersecting voxels between two masks
fslmaths "${OutFolder}"/"${Subject}"_"${Ses}"_"${hemi}".pial_uthr0.native.nii.gz -mas "${OutFolder}"/"${Subject}"_"${Ses}"_"${hemi}".white_thr0.native.nii.gz -mul 255 "${OutFolder}"/"${Subject}"_"${Ses}"_"${hemi}".ribbon.nii.gz

fslmaths "${OutFolder}"/"${Subject}"_"${Ses}"_"${hemi}".ribbon.nii.gz -bin -mul "${GreyRibbonValue}" "${OutFolder}"/"${Subject}"_"${Ses}"_"${hemi}".ribbon.nii.gz
