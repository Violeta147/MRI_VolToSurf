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

# DataFolder=/media/BabyBrain/preterm
# OutFolder=/media/BabyBrain/preterm/fMRI_Vol2Cifti

# Compute shortest distance from each voxel to surfaces
wb_command -create-signed-distance-volume "${DataFolder}"/dhcp_anat_pipeline/"${Subject}"/"${Ses}"/anat/"${Subject}"_"${Ses}"_hemi-"${hemi}"_space-T2w_wm.surf.gii "${RefImg}" "${OutFolder}"/"${Subject}"_"${Ses}"/tmp/"${Subject}"_"${Ses}"_"${hemi}".white.native.nii.gz
wb_command -create-signed-distance-volume "${DataFolder}"/dhcp_anat_pipeline/"${Subject}"/"${Ses}"/anat/"${Subject}"_"${Ses}"_hemi-"${hemi}"_space-T2w_pial.surf.gii "${RefImg}" "${OutFolder}"/"${Subject}"_"${Ses}"/tmp/"${Subject}"_"${Ses}"_"${hemi}".pial.native.nii.gz
 
# Get voxels out of WM surface
fslmaths "${OutFolder}"/"${Subject}"_"${Ses}"/tmp/"${Subject}"_"${Ses}"_"${hemi}".white.native.nii.gz -thr 0 -bin -mul 255 "${OutFolder}"/"${Subject}"_"${Ses}"/tmp/"${Subject}"_"${Ses}"_"${hemi}".white_thr0.native.nii.gz
fslmaths "${OutFolder}"/"${Subject}"_"${Ses}"/tmp/"${Subject}"_"${Ses}"_"${hemi}".white_thr0.native.nii.gz -bin "${OutFolder}"/"${Subject}"_"${Ses}"/tmp/"${Subject}"_"${Ses}"_"${hemi}".white_thr0.native.nii.gz

# Get voxels into Pial surface
fslmaths "${OutFolder}"/"${Subject}"_"${Ses}"/tmp/"${Subject}"_"${Ses}"_"${hemi}".pial.native.nii.gz -uthr 0 -abs -bin -mul 255 "${OutFolder}"/"${Subject}"_"${Ses}"/tmp/"${Subject}"_"${Ses}"_"${hemi}".pial_uthr0.native.nii.gz
fslmaths "${OutFolder}"/"${Subject}"_"${Ses}"/tmp/"${Subject}"_"${Ses}"_"${hemi}".pial_uthr0.native.nii.gz -bin "${OutFolder}"/"${Subject}"_"${Ses}"/tmp/"${Subject}"_"${Ses}"_"${hemi}".pial_uthr0.native.nii.gz

# Get intersecting voxels between two masks
fslmaths "${OutFolder}"/"${Subject}"_"${Ses}"/tmp/"${Subject}"_"${Ses}"_"${hemi}".pial_uthr0.native.nii.gz -mas "${OutFolder}"/"${Subject}"_"${Ses}"/tmp/"${Subject}"_"${Ses}"_"${hemi}".white_thr0.native.nii.gz -mul 255 "${OutFolder}"/"${Subject}"_"${Ses}"/tmp/"${Subject}"_"${Ses}"_"${hemi}".ribbon.nii.gz

fslmaths "${OutFolder}"/"${Subject}"_"${Ses}"/tmp/"${Subject}"_"${Ses}"_"${hemi}".ribbon.nii.gz -bin -mul "${GreyRibbonValue}" "${OutFolder}"/"${Subject}"_"${Ses}"/tmp/"${Subject}"_"${Ses}"_"${hemi}".ribbon.nii.gz
