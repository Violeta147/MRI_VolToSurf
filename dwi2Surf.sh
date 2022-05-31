#!/bin/bash

ANAT_FOLDER=/media/BabyCake/preterm/dhcp_anat_pipeline
DWI_FOLDER=/home/lmarcos/Escritorio

id=sub-CC00063AN06
ses=ses-15102
#for id in $(ls "${DWI_FOLDER}")
#do
 
 #ses=$(ls /media/BabyCake/processing/dHCP-func-surf/"${id}")
 mkdir -p "${DWI_FOLDER}"/"${id}"/tmp
 
 for dat in ad rd fa cl first_autovector
 do

  if [[ "${dat}" == *first_autovector* ]]; then
   mod=func
  else
   mod=shape
  fi

  #echo wb_command -volume-to-surface-mapping "${DWI_FOLDER}"/"${id}"/"${dat}".nii.gz "${ANAT_FOLDER}"/"${id}"/"${ses}"/anat/"${id}"_"${ses}"_hemi-L_space-T2w_midthickness.surf.gii "${DWI_FOLDER}"/"${id}"/"${id}"_"${ses}"_hemi-L_"${dat}"."${mod}".gii -ribbon-constrained  "${ANAT_FOLDER}"/"${id}"/"${ses}"/anat/"${id}"_"${ses}"_hemi-L_space-T2w_wm.surf.gii "${ANAT_FOLDER}"/"${id}"/"${ses}"/anat/"${id}"_"${ses}"_hemi-L_space-T2w_pial.surf.gii

  bash /home/lmarcos/Escritorio/Pipeline_Vol2Surf/Tools/ComputeRibbon.sh "${ANAT_FOLDER}"/"${id}"/"${ses}"/anat "${DWI_FOLDER}"/"${id}"/tmp "${DWI_FOLDER}"/"${id}"/"${dat}".nii.gz "L" 1

  wb_command -volume-to-surface-mapping "${DWI_FOLDER}"/"${id}"/"${dat}".nii.gz \
    "${ANAT_FOLDER}"/"${id}"/"${ses}"/anat/"${id}"_"${ses}"_hemi-L_space-T2w_midthickness.surf.gii \
    "${DWI_FOLDER}"/"${id}"/"${id}"_"${ses}"_hemi-L_"${dat}"."${mod}".gii \
    -ribbon-constrained \
    "${ANAT_FOLDER}"/"${id}"/"${ses}"/anat/"${id}"_"${ses}"_hemi-L_space-T2w_wm.surf.gii \
    "${ANAT_FOLDER}"/"${id}"/"${ses}"/anat/"${id}"_"${ses}"_hemi-L_space-T2w_pial.surf.gii -volume-roi "${DWI_FOLDER}"/"${id}"/tmp/goodvoxels.nii.gz \

  wb_command -metric-dilate "${DWI_FOLDER}"/"${id}"/"${id}"_"${ses}"_hemi-L_"${dat}"."${mod}".gii \
    "${ANAT_FOLDER}"/"${id}"/"${ses}"/anat/"${id}"_"${ses}"_hemi-L_space-T2w_pial.surf.gii 10 \
    "${DWI_FOLDER}"/"${id}"/"${id}"_"${ses}"_hemi-L_"${dat}"."${mod}".gii -nearest


    bash /home/lmarcos/Escritorio/Pipeline_Vol2Surf/Tools/ComputeRibbon.sh "${ANAT_FOLDER}"/"${id}"/"${ses}"/anat "${DWI_FOLDER}"/"${id}"/tmp "${DWI_FOLDER}"/"${id}"/"${dat}".nii.gz "R" 1

  wb_command -volume-to-surface-mapping "${DWI_FOLDER}"/"${id}"/"${dat}".nii.gz \
    "${ANAT_FOLDER}"/"${id}"/"${ses}"/anat/"${id}"_"${ses}"_hemi-R_space-T2w_midthickness.surf.gii \
    "${DWI_FOLDER}"/"${id}"/"${id}"_"${ses}"_hemi-R_"${dat}"."${mod}".gii \
    -ribbon-constrained  \
    "${ANAT_FOLDER}"/"${id}"/"${ses}"/anat/"${id}"_"${ses}"_hemi-R_space-T2w_wm.surf.gii \
    "${ANAT_FOLDER}"/"${id}"/"${ses}"/anat/"${id}"_"${ses}"_hemi-R_space-T2w_pial.surf.gii -volume-roi "${DWI_FOLDER}"/"${id}"/tmp/goodvoxels.nii.gz
  wb_command -metric-dilate "${DWI_FOLDER}"/"${id}"/"${id}"_"${ses}"_hemi-R_"${dat}"."${mod}".gii \
    "${ANAT_FOLDER}"/"${id}"/"${ses}"/anat/"${id}"_"${ses}"_hemi-R_space-T2w_pial.surf.gii 10 \
    "${DWI_FOLDER}"/"${id}"/"${id}"_"${ses}"_hemi-R_"${dat}"."${mod}".gii -nearest

 done
#done
