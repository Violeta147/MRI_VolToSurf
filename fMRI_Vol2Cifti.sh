#!/bin/bash


### This script performs the transformation of the volumetric fMRI data to a CIFTI file containing the cortex fMRI in surface space and the subcortical data in volumetric space.
### Mandatory input positional arguments are:
### 	- Subject: Subject ID
### 	- Session: SessionID
###	- Working Directory: Directory conatining the input images
###	- FWHM: 
### Optional flags and their input arguments are:
###	-f --freesurfer-dir <FS_DIR> : Full path to the subject's freesurfer directory
###	-s --subcortical-mask <subc> : Full path to subcortical mask in native anatomical space
###	-r --reference-image <RefImg> : 
###	-n --normalize <Temp_dir> : Full path to the directory where the template files (anatomical image and subcortical mask) are stored

### PARSE ARGUMENTS
#
# Positional arguments: SubjectId, Session, Work_dir and FWHM

useRefImg=0
useFreesurfer=0
useSubc=0
normalize=0

PARAMS=""
while (( "$#" )) ; do
  case "$1" in
    -r|--reference-image)
      if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
	useRefImg=1
        RefImg=$2
        shift 2
      else
        echo "Error: Reference image is missing" >&2
        exit 1
      fi
      ;;
    -f|--freesurfer-dir)
      if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
        useFreesurfer=1
        FS_DIR=$2
        shift 2
      else
        echo "Error: Freesurfer directory is missing" >&2
        exit 1
      fi
      ;;
    -s|--subcortical-mask)
      if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
        useSubc=1
        Subc=$2
        shift 2
      else
        echo "Error: Subcortical mask is missing" >&2
        exit 1
      fi
      ;;
    -n|--normalize)
      normalize=1
      if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
	      SurfTemp_dir=$2
      else
        echo "Error: Surface template directory missing" >&2
      fi
      if [ -n "$3" ] && [ "${3:0:1}" != "-" ]; then  # check if there is a 
	      VolTemp_dir=$3
      else
        echo "Error: Volume template directory missing" >&2
      fi
      shift 3
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

Subject=$1
Ses=$2
Work_dir=$3
FWHM=$4

cd /home/vsanchez/Pipeline_Vol2Surf/ || exit

# Create temporal folder (in Preterm)

Work_dir=/media/BabyBrain/preterm
Subject=sub-CC00135BN12
Ses=ses-44704
OutDir=/media/BabyBrain/preterm/fMRI_Vol2Cifti/"${Subject}"_"${Ses}"
echo "Work_dir:" "${Work_dir}"
echo "OutDir:" "${OutDir}"

# 1:
# mkdir "${Work_dir}"/fMRI_Vol2Cifti

# 2:
mkdir "${OutDir}"


# Compute mean fMRI

if ! [ -f "${OutDir}"/"${Subject}"_"${Ses}"_mean.nii.gz ]; then
 fslmaths "${Work_dir}"/rel3_dhcp_fmri_pipeline/"${Subject}"/"${Ses}"/func/"${Subject}"_"${Ses}"_task-rest_desc-preproc_bold.nii.gz -Tmean "${OutDir}"/"${Subject}"_"${Ses}"_mean.nii.gz -odt float

else
 echo "This file already exists"
fi


if [[ $useRefImg -eq 1 ]]; then

 # Check FMRI and SBref shape
 ShapeFMRI=$(mrinfo -size "${OutDir}"/"${Subject}"_"${Ses}"_mean.nii.gz)
 IFS=' ' read -r -a ShapeFMRI <<< "$ShapeFMRI"
 ShapeSBRef=$(mrinfo -size "${RefImg}")
 IFS=' ' read -r -a ShapeSBRef <<< "$ShapeSBRef"
 DIFF=$(echo "${ShapeFMRI[@]}" "${ShapeSBRef[@]}" | tr ' ' '\n' | sort | uniq -u)

 if [ -n "$DIFF" ];then
  echo 'SBRef and fMRI images have different dimensions, computing linear registration'
  flirt -in "${RefImg}" -ref "${OutDir}"/"${Subject}"_"${Ses}"_mean.nii.gz -omat "${OutDir}"/SBRef2fMRI.mat -out "${OutDir}"/SBRef_fMRI.nii.gz
  RefImg="${OutDir}"/SBRef_fMRI.nii.gz
 fi

else
 
 RefImg="${OutDir}"/"${Subject}"_"${Ses}"_mean.nii.gz

fi
echo "${RefImg}"


# Check if anat2func transformation matrix exist or compute it otherwise

if ! [ -f "${OutDir}"/"${Subject}"_"${Ses}"_from-T2w_to-bold_mode-image.mat ] ; then
 echo "Dame la inversa papá"
 flirt -in "${Work_dir}"/dhcp_anat_pipeline/"${Subject}"/"${Ses}"/anat/"${Subject}"_"${Ses}"_desc-restore_T2w.nii.gz -ref "${RefImg}" -cost normmi -omat "${OutDir}"/"${Subject}"_"${Ses}"_from-T2w_to-bold_mode-image.mat

else
 echo "The inverse already exists"
 
fi


# Transform freesurfer surfaces to gifti (NO)

if [[ "${useFreesurfer}" -eq 1 ]] ; then
 for hemi in lh rh;
 do
  if [ $hemi = "lh" ] ; then
   mris_convert "${FS_DIR}"/"${Subject}"/surf/"${hemi}".white "${Work_dir}"/"${Subject}"/hemi-left_white.surf.gii
   mris_convert "${FS_DIR}"/"${Subject}"/surf/"${hemi}".pial "${Work_dir}"/"${Subject}"/hemi-left_pial.surf.gii
   wb_command -surface-average "${Work_dir}"/"${Subject}"/hemi-left_midthickness.surf.gii -surf "${Work_dir}"/"${Subject}"/hemi-left_white.surf.gii "${Work_dir}"/"${Subject}"/hemi-left_pial.surf.gii
  elif [ $hemi = "right" ] ; then
   mris_convert "${FS_DIR}"/"${Subject}"/surf/"${hemi}".white "${Work_dir}"/"${Subject}"/hemi-right_white.surf.gii
   mris_convert "${FS_DIR}"/"${Subject}"/surf/"${hemi}".pial "${Work_dir}"/"${Subject}"/hemi-right_pial.surf.gii
   wb_command -surface-average "${Work_dir}"/"${Subject}"/hemi-right_midthickness.surf.gii -surf "${Work_dir}"/"${Subject}"/hemi-left_white.surf.gii "${Work_dir}"/"${Subject}"/hemi-right_pial.surf.gii
  fi
 done
fi


## Parameters from HCP and dHCP pipelines
NeighborhoodSmoothing="5"
LeftGreyRibbonValue="1"
RightGreyRibbonValue="1"


### CREATE RIBBON ###

if ! [ -f  "${OutDir}"/"${Subject}"_"${Ses}"_ribbon_only.nii.gz ]; then
 echo "Computing Ribbon Image"
 
 if [[ "${useFreesurfer}" -eq 0 ]] ; then
  for hemi in L R;
  do

   if [ $hemi = "L" ] ; then
     GreyRibbonValue=${LeftGreyRibbonValue}
   elif [ $hemi = "R" ] ; then
     GreyRibbonValue=${RightGreyRibbonValue}
   fi
   
   bash Tools/BIDS/ComputeRibbon.sh "${AnatFolder}" "${OutFolder}" "${Subject}" "${Ses}" "${RefImg}" "${hemi}" "${GreyRibbonValue}"

  done

 else
 
  # Transform freesurfer ribbon to nifti and remove wm
  mri_convert "${FS_DIR}"/"${Subject}"/mri/ribbon.mgz "${OutDir}"/ribbon.nii.gz
  fslreorient2std "${OutDir}"/ribbon.nii.gz "${OutDir}"/ribbon.nii.gz
  fslmaths "${OutDir}"/ribbon.nii.gz -uthr 3 -thr 3 -bin "${OutDir}"/left.ribbon.nii.gz
  fslmaths "${OutDir}"/ribbon.nii.gz -uthr 42 -thr 42 -bin "${OutDir}"/right.ribbon.nii.gz
 fi

 # Merge Ribbon Hemispheres
 fslmaths "${OutDir}"/"${Subject}"_"${Ses}"_L.ribbon.nii.gz -add "${OutDir}"/"${Subject}"_"${Ses}"_R.ribbon.nii.gz "${OutDir}"/"${Subject}"_"${Ses}"_ribbon_only.nii.gz
 rm "${OutDir}"/"${Subject}"_"${Ses}"_L.ribbon.nii.gz "${OutDir}"/"${Subject}"_"${Ses}"_R.ribbon.nii.gz

else

 echo "Ribbon image already computed"

fi



# Create mask of voxels with good signal

if ! [ -f "${OutDir}"/"${Subject}"_"${Ses}"_goodvoxels.nii.gz ]; then
 echo "Computing goodvoxels image"
 bash Tools/BIDS/ComputeGoodvoxels.sh "${fmriFolder}" "${OutFolder}" "${Subject}" "${Ses}" "${NeighborhoodSmoothing}"
else
 echo "Goodvoxels image already computed"
fi



# Mapping cortical maps to surface

for hemi in L R ; do

 if [ ${normalize} -eq 1 ]; then

  if ! [ -f "${OutDir}"/"${Subject}"_"${Ses}"_"${hemi}".preproc_rest.dhcpSym40_32k.func.gii ]; then
   echo "Mapping ${hemi} cortical maps to surface and resampling to template surface"
   bash fMRI2Surf.sh "${Work_dir}"/fMRI_Vol2Cifti/"${Subject}"_"${Ses}" "${OutDir}" "${hemi}" -n "${SurfTemp_dir}"
  else
   echo "Normalized ${hemi} cortical surface maps already computed and normalized"
  fi

 else

  if ! [ -f "${OutDir}"/"${Subject}"_"${Ses}"_preproc_rest."${hemi}".native.func.gii ]; then
   echo "Mapping ${hemi} cortical maps to surface"
   bash Tools/BIDS/fMRI2Surf.sh "${AnatFolder}" "${fmriFolder}" "${OutFolder}" "${Subject}" "${Ses}" "${hemi}"
  else
   echo "${hemi} cortical surface maps already computed"
  fi 

 fi

done



### SURFACE SMOOTHING

FWHM="6"

if ! [ -f "${OutDir}"/"${Subject}"_"${Ses}"_preproc_rest_s"${FWHM}".atlasroi."${hemi}".native.func.gii ]; then
 echo "Smoothing fMRI cortical surface"

 Sigma=$(echo "$FWHM / ( 2 * ( sqrt ( 2 * l ( 2 ) ) ) )" | bc -l) # (standard_in) 1: syntax error

 for hemi in L R ; do
  wb_command -metric-smoothing "${Work_dir}"/dhcp_anat_pipeline/"${Subject}"/"${Ses}"/anat/"${Subject}"_"${Ses}"_hemi-"${hemi}"_space-T2w_midthickness.surf.gii "${OutDir}"/"${Subject}"_"${Ses}"_preproc_rest."${hemi}".native.func.gii "${Sigma}" "${OutDir}"/"${Subject}"_"${Ses}"_preproc_rest_s"${FWHM}".atlasroi."${hemi}".native.func.gii -roi "${Work_dir}"/dhcp_anat_pipeline/"${Subject}"/"${Ses}"/anat/"${Subject}"_"${Ses}"_hemi-"${hemi}"_desc-medialwall_mask.shape.gii
 done

else

 echo "Smoothed fMRI gifti already computed"

fi



### SUBCORTICAL PROCESSING


if [ ${normalize} -eq 1 ]; then

 if ! [ -f "${OutDir}"/subcortical_space-extdhcp40wk.nii.gz ]; then

  echo "Creating Subcortical Cifti" 
 
  if [ ${useSubc} -eq 1 ]; then
   bash ComputeSubcorticalCifti.sh "${Work_dir}"/"${Subject}" "${Work_dir}"/"${Subject}"/tmp -s "${Subc}" -n "${VolTemp_dir}"
  elif [ ${useFreesurfer} -eq 1 ]; then
   bash ComputeSubcorticalCifti.sh "${Work_dir}"/"${Subject}" "${Work_dir}"/"${Subject}"/tmp -f "${FS_DIR}" -n "${VolTemp_dir}"
  else
   bash ComputeSubcorticalCifti.sh "${Work_dir}"/"${Subject}" "${Work_dir}"/"${Subject}"/tmp -n "${VolTemp_dir}"
  fi

 else

  echo "Subcortical Cifti already created"

 fi

else
 
 if ! [ -f "${OutDir}"/"${Subject}"_"${Ses}"_subcortical_fmri.nii.gz ]; then

 echo "Creating Subcortical Cifti"

  if [ ${useSubc} -eq 1 ]; then
   bash Tools/BIDS/ComputeSubcorticalCifti.sh "${Work_dir}"/"${Subject}"_"${Ses}" "${OutDir}" -s "${Subc}"
  elif [ ${useFreesurfer} -eq 1 ]; then
   bash ComputeSubcorticalCifti.sh "${Work_dir}"/"${Subject}"_"${Ses}" "${OutDir}" -f "${FS_DIR}"
  else
   bash Tools/BIDS/ComputeSubcorticalCifti.sh "${AnatFolder}" "${fmriFolder}" "${OutFolder}" "${Subject}" "${Ses}"
  fi

 else
 
  echo "Subcortical Cifti already created"

 fi

fi



### CREATE DENSE TIMESERIES
echo "Creating Complete Cifti"

TR_vol=$(fslval "${Work_dir}"/rel3_dhcp_fmri_pipeline/"${Subject}"/"${Ses}"/func/"${Subject}"_"${Ses}"_task-rest_desc-preproc_bold.nii.gz pixdim4 | cut -d " " -f 1)

if [ ${normalize} -eq 1 ]; then
 bash CreateCompleteCifti.sh "${OutDir}" "${TR_vol}" "${FWHM}" -n "${SurfTemp_dir}"
else
 bash Tools/BIDS/CreateCompleteCifti.sh "${AnatFolder}" "${OutFolder}" "${Subject}" "${Ses}" "${TR_vol}" "${FWHM}"
fi
