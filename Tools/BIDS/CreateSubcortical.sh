#!/bin/bash

### This script computes a subcortical mask from a freesurfer output or an anatomical image (** to be implemented)
### Mandatory input positional arguments are:
### 	- DataFolder: Directory where the surfaces are stored
### 	- OutFolder: Directory where the resulting images are to be stored
### Optional flags and their input arguments are:
###	-f --freesurfer-dir <FS_DIR> : Full path to the subject's freesurfer directory

AnatFolder=/media/BabyBrain/preterm/dhcp_anat_pipeline/"${Subject}"/"${Ses}"/anat
OutFolder=/media/BabyBrain/preterm/fMRI_Vol2Cifti/"${Subject}"_"${Ses}"/tmp
AnatFolder=$1
OutFolder=$2
Subject=$3
Ses=$4

# Check data:
echo "AnatFolder:" "${AnatFolder}"
echo "OutFolder:" "${OutFolder}"


PARAMS=""
while (( "$#" )) ; do
  case "$1" in
    -f|--freesurfer-dir)
      if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
        useFreesurfer=1
        FS_DIR=$2
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


if [[ ${useFreesurfer} -eq 1 ]]; then
  
 echo "Extract subcortical mask from aseg"
 # Get subcortical voxels from Freesurfer's aseg file
 mri_convert "${FS_DIR}"/mri/aseg.mgz "${OutFolder}"/aseg.nii.gz
 fslreorient2std "${OutFolder}"/aseg.nii.gz "${OutFolder}"/aseg.nii.gz
 fslmaths "${OutFolder}"/aseg.nii.gz -thr 9 -uthr 13 -bin "${OutFolder}"/left_subc.nii.gz
 fslmaths "${OutFolder}"/aseg.nii.gz -thr 48 -uthr 52 -bin "${OutFolder}"/right_subc.nii.gz
 fslmaths "${OutFolder}"/left_subc.nii.gz -add "${OutFolder}"/right_subc.nii.gz "${DataFolder}"/subc.nii.gz

else
  
 echo "Extract Subcortical voxels from T1"
 # Extract subcortical voxels (to be implemented)
 #T1=${AnatFolder}/"${Subject}"_"${Ses}"_desc-restore_space-T2w_T1w.nii.gz
 T1=${AnatFolder}/T1.nii.gz
 run_first_all -i "${T1}" -o "${OutFolder}"/"${Subject}"_"${Ses}"_subc.nii.gz

fi
