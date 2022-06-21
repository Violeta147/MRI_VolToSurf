#!/bin/bash

### This script computes a cifti (or two if normalizing) containing the time series of the subcortical voxels.
### Mandatory input positional arguments are:
### 	- DataFolder: Directory where the surfaces are stored
### 	- OutFolder: Directory where the resulting images are to be stored
### Optional flags and their input arguments are:
###	-f --freesurfer-dir <FS_DIR> : Full path to the subject's freesurfer directory
###	-s --subcortical-mask <subc> : Full path to subcortical mask in native anatomical space
###	-n --normalize <Temp_dir> : Full path to the directory where the template files (anatomical image and subcortical mask) are stored

AnatFolder=$1
fmriFolder=$2
OutFolder=$3
Subject=$4
Ses=$5

AnatFolder=/media/BabyBrain/preterm/dhcp_anat_pipeline/"${Subject}"/"${Ses}"/anat
fmriFolder=/media/BabyBrain/preterm/rel3_dhcp_fmri_pipeline/"${Subject}"/"${Ses}"/func
OutFolder=/media/BabyBrain/preterm/fMRI_Vol2Cifti/"${Subject}"_"${Ses}"

# Check data:
echo "AnatFolder:" "${AnatFolder}"
echo "fmriFolder:" "${fmriFolder}"
echo "OutFolder:" "${OutFolder}"

useFreesurfer=0

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
    -s|--subcortical-mask)
      if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
        Subc=$2
        shift 2
      else
        echo "Error: Argument for $1 is missing" >&2
        exit 1
      fi
      ;;
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


## Check if variable Subc is set (it can be set as input of this function) and set it otherwise. If it is set as input check file existence.
if [ -z ${Subc+x} ];then
 Subc="${AnatFolder}"/"${Subject}"_"${Ses}"_desc-drawem9_space-T2w_dseg.nii.gz
else
 if ! [ -f "${Subc}" ]; then
  echo "Input Subcortical image does not exist"
  return 
 fi
fi

: '
if ! [ -f "${Subc}" ]; then
  
 echo "Creating subcortical mask"
 if [[ ${useFreesurfer} -eq 1 ]]; then
  bash Tools/BIDS/CreateSubcortical.sh "${DataFolder}" "${OutFolder}" -f "${FS_DIR}"
 else
  bash Tools/BIDS/CreateSubcortical.sh "${AnatFolder}" "${OutFolder}" "${Subject}" "${Ses}"
 fi

fi
'


# Register Subcortical mask to fMRI space

#Subc="${AnatFolder}"/"${Subject}"_"${Ses}"_desc-drawem9_space-T2w_dseg.nii.gz

fslmaths "${Subc}" -thr 7 -uthr 7 -bin "${OutFolder}"/"${Subject}"_"${Ses}"_subcortical_mask.nii.gz

flirt -in "${OutFolder}"/"${Subject}"_"${Ses}"_subcortical_mask.nii.gz -ref "${OutFolder}"/"${Subject}"_"${Ses}"_mean.nii.gz -applyxfm -init "${OutFolder}"/"${Subject}"_"${Ses}"_from-T2w_to-bold_mode-image.mat -interp nearestneighbour -o "${OutFolder}"/"${Subject}"_"${Ses}"_subc_fmri.nii.gz

# Create subcortical-structures.txt file
printf "%s\n" OTHER >> "${OutFolder}"/"${Subject}"_"${Ses}"_subcortical-structures.txt
printf "%s\n" "1 255 0 0 255" >> "${OutFolder}"/"${Subject}"_"${Ses}"_subcortical-structures.txt

# Create Label file
wb_command -volume-label-import "${OutFolder}"/"${Subject}"_"${Ses}"_subc_fmri.nii.gz "${OutFolder}"/"${Subject}"_"${Ses}"_subcortical-structures.txt "${OutFolder}"/"${Subject}"_"${Ses}"_subc_fmri.nii.gz -discard-others -drop-unused-labels


if [[ $(echo 3 == 3 | bc -l | cut -f1 -d.) == "1" ]]
then
    echo "Creating subject-roi subcortical cifti at same resolution as output"
    wb_command -cifti-create-dense-timeseries "${OutFolder}"/"${Subject}"_"${Ses}"_func_temp_subject.dtseries.nii -volume "${fmriFolder}"/"${Subject}"_"${Ses}"_task-rest_desc-preproc_bold.nii.gz "${OutFolder}"/"${Subject}"_"${Ses}"_subc_fmri.nii.gz
else
    echo "Creating subject-roi subcortical cifti at differing fMRI resolution"
    wb_command -volume-affine-resample tmp/subc_fmri.nii.gz "${FS_DIR}"/etc/flirtsch/ident.mat "${DataFolder}"/preproc_rest.nii.gz ENCLOSING_VOXEL "${ResultsFolder}"/ROIs."${FinalfMRIResolution}".nii.gz
    wb_command -cifti-create-dense-timeseries "${ResultsFolder}"/func_temp_subject.dtseries.nii -volume "${DataFolder}"/preproc_rest.nii.gz "${ResultsFolder}"/ROIs."${FinalfMRIResolution}".nii.gz
    rm -f "${ResultsFolder}"/ROIs."${FinalfMRIResolution}".nii.gz
fi

echo "Dilating out zeros"
#dilate out any exact zeros in the input data, for instance if the brain mask is wrong. Note that the CIFTI space cannot contain zeros to produce a valid CIFTI file (dilation also occurs below).
wb_command -cifti-dilate "${OutFolder}"/"${Subject}"_"${Ses}"_func_temp_subject.dtseries.nii COLUMN 0 30 "${OutFolder}"/"${Subject}"_"${Ses}"_func_temp_subject_dilate.dtseries.nii
# write output volume
wb_command -cifti-separate "${OutFolder}"/"${Subject}"_"${Ses}"_func_temp_subject_dilate.dtseries.nii COLUMN -volume-all "${OutFolder}"/"${Subject}"_"${Ses}"_subcortical_fmri.nii.gz
#rm -f ${ResultsFolder}/func_temp_subject.dtseries.nii

: '
##### NOT IMPLEMENTED
if [[ ${normalize} -eq 1 ]]; then   
 echo "Generate atlas subcortical template cifti"
 wb_command -cifti-create-label "${OutFolder}"/subcortical_mask.dlabel.nii -volume "${Temp_dir}"/subcortical_mask.nii.gz "${Temp_dir}"/subcortical_mask.nii.gz

 if ! [ -f "${DataFolder}"/func2temp.nii.gz ]; then
  echo "Estimating normalization warp"
  flirt -in "${DataFolder}"/T1.nii.gz -ref "${Temp_dir}"/Template.nii.gz -omat "${DataFolder}"/anat2temp.mat
  fnirt --in="${DataFolder}"/T1.nii.gz --ref="${Temp_dir}"/Template.nii.gz --aff="${DataFolder}"/anat2temp.mat --cout="${DataFolder}"/anat2temp.nii.gz
  convert_xfm -omat "${DataFolder}"/func2temp.mat -concat "${DataFolder}"/func2anat.mat "${DataFolder}"/anat2temp.mat
  echo "resample dense-time-series from func -> template space"
  wb_command -cifti-resample "${OutFolder}"/func_space-func.dtseries.nii COLUMN "${OutFolder}"/subcortical_mask.dlabel.nii COLUMN ADAP_BARY_AREA CUBIC "${OutFolder}"/func_space-extdhcp40wk.dtseries.nii -volume-predilate 10 -warpfield "${DataFolder}"/func2temp.nii.gz -fnirt "${DataFolder}"/Template.nii.gz -affine "${DataFolder}"/func2temp.mat -flirt "${OutFolder}"/mean.nii.gz "${Temp_dir}"/Template.nii.gz
 else
  echo "resample dense-time-series from func -> template space"
  wb_command -cifti-resample "${OutFolder}"/func_space-func.dtseries.nii COLUMN "${OutFolder}"/subcortical_mask.dlabel.nii COLUMN ADAP_BARY_AREA CUBIC "${OutFolder}"/func_space-extdhcp40wk.dtseries.nii -volume-predilate 10 -warpfield "${DataFolder}"/func2temp.nii.gz -fnirt "${DataFolder}"/Template.nii.gz
 fi

#delete common temporaries
#rm -f ${ResultsFolder}/${NameOffMRI}_temp_subject_dilate.dtseries.nii
#rm -f ${ResultsFolder}/${NameOffMRI}_temp_template.dlabel.nii

 wb_command -cifti-dilate "${OutFolder}"/func_space-extdhcp40wk.dtseries.nii COLUMN 0 30 "${OutFolder}"/func_space-extdhcp40wk.dtseries.nii
 wb_command -cifti-separate "${OutFolder}"/func_space-extdhcp40wk.dtseries.nii COLUMN -volume-all "${OutFolder}"/subcortical_space-extdhcp40wk.nii.gz

#rm -f ${func_space_dir}/func_space-func.dtseries.nii
#rm -f ${template_space_dir}/func_space-extdhcp40wk.dtseries.nii
fi
##### END OF NOT IMPLEMENTED
'
