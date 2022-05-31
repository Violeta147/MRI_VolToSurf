#!/bin/bash


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

cd /home/lmarcos/Escritorio/Pipeline_Vol2Surf/ || exit

# Create temporal folder

mkdir "${Work_dir}"/"${Subject}"/tmp

# Compute mean fMRI
if ! [ -f "${Work_dir}"/"${Subject}"/tmp/mean.nii.gz ]; then
 fslmaths "${Work_dir}"/"${Subject}"/preproc_rest.nii.gz -Tmean "${Work_dir}"/"${Subject}"/tmp/mean.nii.gz -odt float
fi


if [[ $useRefImg -eq 1 ]]; then

 # Check FMRI and SBref shape
 ShapeFMRI=$(mrinfo -size "${Work_dir}"/"${Subject}"/tmp/mean.nii.gz)
 IFS=' ' read -r -a ShapeFMRI <<< "$ShapeFMRI"
 ShapeSBRef=$(mrinfo -size "${RefImg}")
 IFS=' ' read -r -a ShapeSBRef <<< "$ShapeSBRef"
 DIFF=$(echo "${ShapeFMRI[@]}" "${ShapeSBRef[@]}" | tr ' ' '\n' | sort | uniq -u)

 if [ -n "$DIFF" ];then
  echo 'SBRef and fMRI images have different dimensions, computing linear registration'
  flirt -in "${RefImg}" -ref "${Work_dir}"/"${Subject}"/tmp/mean.nii.gz -omat "${Work_dir}"/"${Subject}"/tmp/SBRef2fMRI.mat -out "${Work_dir}"/"${Subject}"/tmp/SBRef_fMRI.nii.gz
  RefImg="${Work_dir}"/"${Subject}"/tmp/SBRef_fMRI.nii.gz
 fi

else
 
 RefImg="${Work_dir}"/"${Subject}"/tmp/mean.nii.gz

fi


# Check if anat2func transformation matrix exist or compute it otherwise
if ! [ -f "${Work_dir}"/"${Subject}"/anat2func.mat ] ; then
 echo "Dame la inversa papá"
 convert_xfm -omat "${Work_dir}"/"${Subject}"/anat2func.mat -inverse "${Work_dir}"/"${Subject}"/func2anat.mat
fi


# Transform freesurfer surfaces to gifti


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

if ! [ -f  "${Work_dir}"/"${Subject}"/tmp/ribbon_only.nii.gz ]; then
 echo "Computing Ribbon Image"
 
 if [[ "${useFreesurfer}" -eq 1 ]] ; then
  for hemi in left right;
  do

   if [ $hemi = "left" ] ; then
     GreyRibbonValue=${LeftGreyRibbonValue}
   elif [ $hemi = "right" ] ; then
     GreyRibbonValue=${RightGreyRibbonValue}
   fi
   
   bash ComputeRibbon.sh "${Work_dir}"/"${Subject}" "${Work_dir}"/"${Subject}"/tmp "${RefImg}" "${hemi}" "${GreyRibbonValue}"

  done

 else
 
  # Transform freesurfer ribbon to nifti and remove wm
  mri_convert "${FS_DIR}"/"${Subject}"/mri/ribbon.mgz "${Work_dir}"/"${Subject}"/tmp/ribbon.nii.gz
  fslreorient2std "${Work_dir}"/"${Subject}"/tmp/ribbon.nii.gz "${Work_dir}"/"${Subject}"/tmp/ribbon.nii.gz
  fslmaths "${Work_dir}"/"${Subject}"/tmp/ribbon.nii.gz -uthr 3 -thr 3 -bin "${Work_dir}"/"${Subject}"/tmp/left.ribbon.nii.gz
  fslmaths "${Work_dir}"/"${Subject}"/tmp/ribbon.nii.gz -uthr 42 -thr 42 -bin "${Work_dir}"/"${Subject}"/tmp/right.ribbon.nii.gz
 fi

 # Merge Ribbon Hemispheres
 fslmaths "${Work_dir}"/"${Subject}"/tmp/left.ribbon.nii.gz -add "${Work_dir}"/"${Subject}"/tmp/right.ribbon.nii.gz "${Work_dir}"/"${Subject}"/tmp/ribbon_only.nii.gz
 rm "${Work_dir}"/"${Subject}"/tmp/left.ribbon.nii.gz "${Work_dir}"/"${Subject}"/tmp/right.ribbon.nii.gz

else

 echo "Ribbon image already computed"

fi



# Create mask of voxels with good signal

if ! [ -f "${Work_dir}"/"${Subject}"/tmp/goodvoxels.nii.gz ]; then
 echo "Computing goodvoxels image"
 bash ComputeGoodvoxels.sh "${Work_dir}"/"${Subject}" "${Work_dir}"/"${Subject}"/tmp ${NeighborhoodSmoothing}
else
 echo "Goodvoxels image already computed"
fi 



# Mapping cortical maps to surface

for hemi in left right ; do

 if [ ${normalize} -eq 1 ]; then

  if ! [ -f "${Work_dir}"/"${Subject}"/tmp/"${hemi}".preproc_rest.dhcpSym40_32k.func.gii ]; then
   echo "Mapping ${hemi} cortical maps to surface and resampling to template surface"
   bash fMRI2Surf.sh "${Work_dir}"/"${Subject}" "${Work_dir}"/"${Subject}"/tmp "${hemi}" -n "${SurfTemp_dir}"
  else
   echo "Normalized ${hemi} cortical surface maps already computed and normalized"
  fi

 else

  if ! [ -f "${Work_dir}"/"${Subject}"/preproc_rest."${hemi}".native.func.gii ]; then
   echo "Mapping ${hemi} cortical maps to surface"
   bash fMRI2Surf.sh "${Work_dir}"/"${Subject}" "${Work_dir}"/"${Subject}"/tmp "${hemi}"
  else
   echo "${hemi} cortical surface maps already computed"
  fi 

 fi

done



### SURFACE SMOOTHING

if ! [ -f "${Work_dir}"/"${Subject}"/preproc_rest_s"${FWHM}".atlasroi."${hemi}".native.func.gii ]; then
 echo "Smoothing fMRI cortical surface"

 Sigma=$(echo "$FWHM / ( 2 * ( sqrt ( 2 * l ( 2 ) ) ) )" | bc -l)

 for hemi in left right ; do
  wb_command -metric-smoothing "${Work_dir}"/"${Subject}"/hemi-"${hemi}"_midthickness.surf.gii\
	"${Work_dir}"/"${Subject}"/preproc_rest."${hemi}".native.func.gii\
	"${Sigma}" "${Work_dir}"/"${Subject}"/preproc_rest_s"${FWHM}".atlasroi."${hemi}".native.func.gii\
	-roi "${Work_dir}"/"${Subject}"/hemi-"${hemi}"_medialwall.shape.gii
   #rm Cosas
 done

else

 echo "Smoothed fMRI gifti already computed"

fi



### SUBCORTICAL PROCESSING

if [ ${normalize} -eq 1 ]; then

 if ! [ -f "${Work_dir}"/"${Subject}"/tmp/subcortical_space-extdhcp40wk.nii.gz ]; then

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
 
 if ! [ -f "${Work_dir}/${Subject}/tmp/subcortical_fmri.nii.gz" ]; then

 echo "Creating Subcortical Cifti"

  if [ ${useSubc} -eq 1 ]; then
   bash ComputeSubcorticalCifti.sh "${Work_dir}"/"${Subject}" "${Work_dir}"/"${Subject}"/tmp -s "${Subc}"
  elif [ ${useFreesurfer} -eq 1 ]; then
   bash ComputeSubcorticalCifti.sh "${Work_dir}"/"${Subject}" "${Work_dir}"/"${Subject}"/tmp -f "${FS_DIR}"
  else
   bash ComputeSubcorticalCifti.sh "${Work_dir}"/"${Subject}" "${Work_dir}"/"${Subject}"/tmp
  fi

 else
 
  echo "Subcortical Cifti already created"

 fi

fi



### CREATE DENSE TIMESERIES
echo "Creating Complete Cifti"

TR_vol=$(fslval "${Work_dir}"/"${Subject}"/preproc_rest.nii.gz pixdim4 | cut -d " " -f 1)

if [ ${normalize} -eq 1 ]; then
 bash CreateCompleteCifti.sh "${Work_dir}"/"${Subject}" "${Work_dir}"/"${Subject}"/tmp "${TR_vol}" "${FWHM}" -n "${SurfTemp_dir}"
else
 bash CreateCompleteCifti.sh "${Work_dir}"/"${Subject}" "${Work_dir}/${Subject}/tmp" "${TR_vol}" "${FWHM}"
fi


rm -r "${Work_dir}"/"${Subject}"/tmp

goodvoxels