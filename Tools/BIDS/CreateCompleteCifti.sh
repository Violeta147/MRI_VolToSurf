#!/bin/bash

### This script computes a cifti (or two if normalizing) containing the time series of both the corical surfaces and the subcortical voxels.
### Mandatory input positional arguments are:
### 	- DataFolder: Directory where the surfaces and the subcortical cifti are stored
### 	- OutFolder: Directory where the temporal files are to be stored
### Optional flags and their input arguments are:
###	-n --normalize <Temp_dir> : Full path to the directory where the template files (anatomical image and subcortical mask)

AnatFolder=$1
OutFolder=$2
Subject=$3
Ses=$4
TR_vol=$5
FWHM=$6

AnatFolder=/media/BabyBrain/preterm/dhcp_anat_pipeline/"${Subject}"/"${Ses}"/anat
OutFolder=/media/BabyBrain/preterm/fMRI_Vol2Cifti/"${Subject}"_"${Ses}"

wb_command -cifti-create-dense-timeseries \
	"${OutFolder}"/"${Subject}"_"${Ses}"_Grayordinates.dtseries.nii \
	-volume "${OutFolder}"/"${Subject}"_"${Ses}"_subcortical_fmri.nii.gz "${OutFolder}"/"${Subject}"_"${Ses}"_subc_fmri.nii.gz \
	-left-metric "${OutFolder}"/"${Subject}"_"${Ses}"_preproc_rest_s"${FWHM}".atlasroi.L.native.func.gii -roi-left "${AnatFolder}"/"${Subject}"_"${Ses}"_hemi-L_desc-medialwall_mask.shape.gii \
	-right-metric "${OutFolder}"/"${Subject}"_"${Ses}"_preproc_rest_s"${FWHM}".atlasroi.R.native.func.gii -roi-right "${AnatFolder}"/"${Subject}"_"${Ses}"_hemi-R_desc-medialwall_mask.shape.gii \
	-timestep "${TR_vol}"

wb_command -cifti-reduce "${OutFolder}"/"${Subject}"_"${Ses}"_Grayordinates.dtseries.nii MEAN "${OutFolder}"/"${Subject}"_"${Ses}"_Grayordinates.mean.dscalar.nii

wb_command -cifti-reduce "${OutFolder}"/"${Subject}"_"${Ses}"_Grayordinates.dtseries.nii STDEV "${OutFolder}"/"${Subject}"_"${Ses}"_Grayordinates.stdev.dscalar.nii

Nnonzero=$(wb_command -cifti-stats "${OutFolder}"/"${Subject}"_"${Ses}"_Grayordinates.stdev.dscalar.nii -reduce COUNT_NONZERO)
Ngrayordinates=$(wb_command -file-information "${OutFolder}"/"${Subject}"_"${Ses}"_Grayordinates.stdev.dscalar.nii | grep "Number of Rows" | awk '{print $4}')
PctCoverage=$(echo "scale=4; 100 * ${Nnonzero} / ${Ngrayordinates}" | bc -l)

echo "PctCoverage, Nnonzero, Ngrayordinates" >| "${OutFolder}"/"${Subject}"_"${Ses}"_Grayordinates_nonzero.stats.txt
echo "${PctCoverage}, ${Nnonzero}, ${Ngrayordinates}" >> "${OutFolder}"/"${Subject}"_"${Ses}"_Grayordinates_nonzero.stats.txt
# If we don't have full grayordinate coverage, save out a mask to identify those locations
if [ "${Nnonzero}" -ne "${Ngrayordinates}" ]; then
	wb_command -cifti-math 'x > 0' "${OutFolder}"/"${Subject}"_"${Ses}"_Grayordinates_nonzero.dscalar.nii -var x "${OutFolder}"/"${Subject}"_"${Ses}"_Grayordinates.stdev.dscalar.nii
fi


if [ ${normalize} -eq 1 ]; then
 wb_command -cifti-create-dense-timeseries \
	"${DataFolder}"/Grayordinates.dhcpSym40_32k.dtseries.nii \
	-volume "${OutFolder}"/subcortical_fmri.nii.gz "${OutFolder}"/subc_fmri.nii.gz \
	-left-metric "${OutFolder}"/left.preproc_rest.dhcpSym40_32k.func.gii -roi-left "${Temp_dir}"/week-40_hemi-left_space-dhcpSym_dens-32k_desc-medialwall_mask.shape.gii \
	-right-metric "${OutFolder}"/right.preproc_rest.dhcpSym40_32k.func.gii -roi-right "${Temp_dir}"/week-40_hemi-right_space-dhcpSym_dens-32k_desc-medialwall_mask.shape.gii \
	-timestep "${TR_vol}"
 
 wb_command -cifti-reduce "${DataFolder}"/Grayordinates.dhcpSym40_32k.dtseries.nii MEAN "${OutFolder}"/Grayordinates.dhcpSym40_32k.mean.dscalar.nii

 wb_command -cifti-reduce "${DataFolder}"/Grayordinates.dhcpSym40_32k.dtseries.nii STDEV "${OutFolder}"/Grayordinates.dhcpSym40_32k.stdev.dscalar.nii
 Nnonzero=$(wb_command -cifti-stats "${OutFolder}"/Grayordinates.dhcpSym40_32k.stdev.dscalar.nii -reduce COUNT_NONZERO)
 Ngrayordinates=$(wb_command -file-information "${OutFolder}"/Grayordinates.dhcpSym40_32k.stdev.dscalar.nii | grep "Number of Rows" | awk '{print $4}')
 PctCoverage=$(echo "scale=4; 100 * ${Nnonzero} / ${Ngrayordinates}" | bc -l)

 echo "PctCoverage, Nnonzero, Ngrayordinates" >| "${DataFolder}"/Grayordinates_nonzero.dhcpSym40_32k.stats.txt
 echo "${PctCoverage}, ${Nnonzero}, ${Ngrayordinates}" >> "${DataFolder}"/Grayordinates_nonzero.dhcpSym40_32k.stats.txt
 # If we don't have full grayordinate coverage, save out a mask to identify those locations
 if [ "$Nnonzero" -ne "$Ngrayordinates" ]; then
	wb_command -cifti-math 'x > 0' "${OutFolder}"/Grayordinates_nonzero.dhcpSym40_32k.dscalar.nii -var x "${OutFolder}"/Grayordinates.dhcpSym40_32k.stdev.dscalar.nii
 fi
fi

