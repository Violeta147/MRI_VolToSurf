#!/bin/bash

### This script computes a gifti (or two if normalizing) containing the time series of a one-hemisphere cortical surface from an fmri volume.
### Mandatory input positional arguments are:
### 	- DataFolder: Directory where the surfaces and the subcortical cifti are stored
### 	- OutFolder: Directory where the temporal files are to be stored
###	- hemi: The hemisphere to be computed as spelled in the surface files
### Optional flags and their input arguments are:
###	-n --normalize <Temp_dir> : Full path to the directory where the template files (anatomical image and subcortical mask)

normalize=0

PARAMS=""
while (( "$#" )) ; do
  case "$1" in
    -n|--normalize)
      if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
        Temp_dir=$2
	normalize=1
        shift 2
      else
        echo "Error: Argument for $1 is missing" >&2
        exit 1
      fi
      ;;
    -*|--*=) # unsupported flags
      echo "Error: Unsupported flag $1" >&2
      exit 1
      ;;
    *) # preserve positional arguments
      PARAMS="$PARAMS $1"
      shift
      ;;
  esac
done

eval set -- "$PARAMS"

DataFolder=$1
OutFolder=$2
hemi=$3

if ! [ -f "${OutFolder}"/"${hemi}".goodvoxels.native.func.gii ] ; then

 wb_command -volume-to-surface-mapping "${OutFolder}"/goodvoxels.nii.gz\
	"${DataFolder}"/hemi-"${hemi}"_midthickness.surf.gii "${OutFolder}"/"${hemi}".goodvoxels.native.func.gii\
	-ribbon-constrained "${DataFolder}"/hemi-"${hemi}"_white.surf.gii "${DataFolder}"/hemi-"${hemi}"_pial.surf.gii

 wb_command -metric-mask "${OutFolder}"/"${hemi}".goodvoxels.native.func.gii\
	"${DataFolder}"/hemi-"${hemi}"_medialwall.shape.gii "${OutFolder}"/"${hemi}".goodvoxels.native.func.gii

fi

wb_command -volume-to-surface-mapping "${DataFolder}"/preproc_rest.nii.gz\
	"${DataFolder}"/hemi-"${hemi}"_midthickness.surf.gii "${DataFolder}"/preproc_rest."${hemi}".native.func.gii\
	-ribbon-constrained "${DataFolder}"/hemi-"${hemi}"_white.surf.gii "${DataFolder}"/hemi-"${hemi}"_pial.surf.gii\
	-volume-roi "${OutFolder}"/goodvoxels.nii.gz

wb_command -metric-dilate "${DataFolder}"/preproc_rest."${hemi}".native.func.gii\
	"${DataFolder}"/hemi-"${hemi}"_midthickness.surf.gii 10 "${DataFolder}"/preproc_rest."${hemi}".native.func.gii -nearest

wb_command -metric-mask  "${DataFolder}"/preproc_rest."${hemi}".native.func.gii\
	"${DataFolder}"/hemi-"${hemi}"_medialwall.shape.gii  "${DataFolder}"/preproc_rest."${hemi}".native.func.gii


##### NOT IMPLEMENTED
if [ ${normalize} -eq 1 ]; then

 wb_command -metric-resample "${OutFolder}"/"${hemi}".goodvoxels.native.func.gii\
	"${DataFolder}"/hemi-"${hemi}"_from-native_to-dhcpSym40_dens-32k_mode-sphere.surf.gii\
	"${Temp_dir}"/week-40_hemi-"${hemi}"_space-dhcpSym_dens-32k_sphere.surf.gii\
	ADAP_BARY_AREA "${OutFolder}"/"${hemi}".goodvoxels.dhcpSym40_32k.func.gii\
	-area-surfs "${DataFolder}"/hemi-"${hemi}"_midthickness.surf.gii "${Temp_dir}"/week-40_hemi-"${hemi}"_space-dhcpSym_dens-32k_midthickness.surf.gii\
	-current-roi "${DataFolder}"/hemi-"${hemi}"_medialwall.shape.gii

 wb_command -metric-mask "${OutFolder}"/"${hemi}".goodvoxels.dhcpSym40_32k.func.gii\
	"${Temp_dir}"/week-40_hemi-"${hemi}"_space-dhcpSym_dens-32k_desc-medialwall_mask.shape.gii\
	"${OutFolder}"/"${hemi}".goodvoxels.dhcpSym40_32k.func.gii

 wb_command -metric-resample "${DataFolder}"/preproc_rest."${hemi}".native.func.gii\
	"${DataFolder}"/hemi-"${hemi}"_from-native_to-dhcpSym40_dens-32k_mode-sphere.surf.gii\
	"${Temp_dir}"/week-40_hemi-"${hemi}"_space-dhcpSym_dens-32k_sphere.surf.gii\
	ADAP_BARY_AREA "${OutFolder}"/temp."${hemi}".preproc_rest.dhcpSym40_32k.func.gii\
	-area-surfs "${DataFolder}"/hemi-"${hemi}"_midthickness.surf.gii "${Temp_dir}"/week-40_hemi-"${hemi}"_space-dhcpSym_dens-32k_midthickness.surf.gii\
	-current-roi "${DataFolder}"/hemi-"${hemi}"_medialwall.shape.gii

 wb_command -metric-dilate "${OutFolder}"/temp."${hemi}".preproc_rest.dhcpSym40_32k.func.gii\
	"${Temp_dir}"/week-40_hemi-"${hemi}"_space-dhcpSym_dens-32k_midthickness.surf.gii\
	30 "${OutFolder}"/temp."${hemi}".preproc_rest.dhcpSym40_32k.func.gii -nearest

 wb_command -metric-mask "${OutFolder}"/temp."${hemi}".preproc_rest.dhcpSym40_32k.func.gii\
	"${Temp_dir}"/week-40_hemi-"${hemi}"_space-dhcpSym_dens-32k_desc-medialwall_mask.shape.gii\
	"${OutFolder}"/"${hemi}".preproc_rest.dhcpSym40_32k.func.gii

fi
##### END OF NOT IMPLEMENTED
