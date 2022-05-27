#!/bin/bash

ANAT_FOLDER=/media/BabyCake/dhcp_anat_pipeline
DWI_FOLDER=/media/BabyCake/processing/dHCP-diff-template/FA_metrics

id=sub-CC00418BN14
ses=ses-125300
#for id in $(ls "${DWI_FOLDER}")
#do
 
 #ses=$(ls /media/BabyCake/processing/dHCP-func-surf/"${id}")
 
 for dat in ad rd fa cl first_autovector
 do

  if [[ "${dat}" == *first_autovector* ]]; then
   mod=func
  else
   mod=shape
  fi

  #echo wb_command -volume-to-surface-mapping "${DWI_FOLDER}"/"${id}"/"${dat}".nii.gz "${ANAT_FOLDER}"/"${id}"/"${ses}"/anat/"${id}"_"${ses}"_hemi-L_space-T2w_midthickness.surf.gii "${DWI_FOLDER}"/"${id}"/"${id}"_"${ses}"_hemi-L_"${dat}"."${mod}".gii -ribbon-constrained  "${ANAT_FOLDER}"/"${id}"/"${ses}"/anat/"${id}"_"${ses}"_hemi-L_space-T2w_wm.surf.gii "${ANAT_FOLDER}"/"${id}"/"${ses}"/anat/"${id}"_"${ses}"_hemi-L_space-T2w_pial.surf.gii

  wb_command -volume-to-surface-mapping "${DWI_FOLDER}"/"${id}"/"${dat}".nii.gz "${ANAT_FOLDER}"/"${id}"/"${ses}"/anat/"${id}"_"${ses}"_hemi-L_space-T2w_midthickness.surf.gii "${DWI_FOLDER}"/"${id}"/"${id}"_"${ses}"_hemi-L_"${dat}"."${mod}".gii -ribbon-constrained  "${ANAT_FOLDER}"/"${id}"/"${ses}"/anat/"${id}"_"${ses}"_hemi-L_space-T2w_wm.surf.gii "${ANAT_FOLDER}"/"${id}"/"${ses}"/anat/"${id}"_"${ses}"_hemi-L_space-T2w_pial.surf.gii
  wb_command -volume-to-surface-mapping "${DWI_FOLDER}"/"${id}"/"${dat}".nii.gz "${ANAT_FOLDER}"/"${id}"/"${ses}"/anat/"${id}"_"${ses}"_hemi-R_space-T2w_midthickness.surf.gii "${DWI_FOLDER}"/"${id}"/"${id}"_"${ses}"_hemi-R_"${dat}"."${mod}".gii -ribbon-constrained  "${ANAT_FOLDER}"/"${id}"/"${ses}"/anat/"${id}"_"${ses}"_hemi-R_space-T2w_wm.surf.gii "${ANAT_FOLDER}"/"${id}"/"${ses}"/anat/"${id}"_"${ses}"_hemi-R_space-T2w_pial.surf.gii

 done
#done
