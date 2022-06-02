#!/bin/bash

ANAT_FOLDER=/media/BabyBrain/preterm/dhcp_anat_pipeline
TENSOR_FOLDER=/home/vsanchez/Documents/Workflow/Workflow_Outs
DWI_FOLDER=/media/BabyBrain/preterm/rel3_dhcp_dmri_shard_pipeline

while IFS=$', ' read -r id ses age
do

 echo "${age}" > /dev/null
 
 mkdir -p /home/lmarcos/tmp
 mkdir -p /home/lmarcos/Results/"${id}"
 
bash /home/lmarcos/ComputeRibbon_BIDS.sh "${ANAT_FOLDER}"/"${id}"/"${ses}"/anat \
 /home/lmarcos/tmp "${id}" "${ses}" "${ANAT_FOLDER}"/"${id}"/"${ses}"/anat/"${id}"_"${ses}"_desc-restore_T2w.nii.gz "L" 1

bash /home/lmarcos/ComputeRibbon_BIDS.sh "${ANAT_FOLDER}"/"${id}"/"${ses}"/anat \
  /home/lmarcos/tmp "${id}" "${ses}" "${ANAT_FOLDER}"/"${id}"/"${ses}"/anat/"${id}"_"${ses}"_desc-restore_T2w.nii.gz "R" 1


dwiextract "${DWI_FOLDER}"/"${id}"/"${ses}"/dwi/"${id}"_"${ses}"_desc-preproc_dwi.nii.gz -bzero \
  -fslgrad "${DWI_FOLDER}"/"${id}"/"${ses}"/dwi/"${id}"_"${ses}"_desc-preproc_dwi.bvec \
  "${DWI_FOLDER}"/"${id}"/"${ses}"/dwi/"${id}"_"${ses}"_desc-preproc_dwi.bval - | mrmath - mean /home/lmarcos/tmp/b0.nii.gz -axis 3

fslmaths "${ANAT_FOLDER}"/"${id}"/"${ses}"/anat/"${id}"_"${ses}"_desc-restore_T2w.nii.gz -mas \
  "${ANAT_FOLDER}"/"${id}"/"${ses}"/anat/"${id}"_"${ses}"_desc-bet_space-T2w_brainmask.nii.gz /home/lmarcos/tmp/T2_brain.nii.gz


flirt -in /home/lmarcos/tmp/T2_brain.nii.gz -ref /home/lmarcos/tmp/b0.nii.gz -cost normmi \
  -omat /home/lmarcos/tmp/struct_to_dwi.mat

flirt -in /home/lmarcos/tmp/"${id}"_"${ses}"_hemi-L.ribbon.nii.gz -ref /home/lmarcos/tmp/b0.nii.gz \
  -applyxfm -init /home/lmarcos/tmp/struct_to_dwi.mat -out /home/lmarcos/tmp/"${id}"_"${ses}"_hemi-L.ribbon.nii.gz \
  -interp nearestneighbour

flirt -in /home/lmarcos/tmp/"${id}"_"${ses}"_hemi-R.ribbon.nii.gz -ref /home/lmarcos/tmp/b0.nii.gz \
  -applyxfm -init /home/lmarcos/tmp/struct_to_dwi.mat -out /home/lmarcos/tmp/"${id}"_"${ses}"_hemi-R.ribbon.nii.gz \
  -interp nearestneighbour


 for dat in FA MD V1 L1 L2 L3
 do

  if [[ "${dat}" == *V1* ]]; then
   mod=func
  else
   mod=shape
  fi


  wb_command -volume-to-surface-mapping "${TENSOR_FOLDER}"/"${id}"/"${id}"_"${dat}".nii.gz \
    "${ANAT_FOLDER}"/"${id}"/"${ses}"/anat/"${id}"_"${ses}"_hemi-L_space-T2w_midthickness.surf.gii \
    /home/lmarcos/Results/"${id}"/"${id}"_"${ses}"_hemi-L_"${dat}"."${mod}".gii \
    -ribbon-constrained \
    "${ANAT_FOLDER}"/"${id}"/"${ses}"/anat/"${id}"_"${ses}"_hemi-L_space-T2w_wm.surf.gii \
    "${ANAT_FOLDER}"/"${id}"/"${ses}"/anat/"${id}"_"${ses}"_hemi-L_space-T2w_pial.surf.gii \
    -volume-roi /home/lmarcos/tmp/"${id}"_"${ses}"_hemi-L.ribbon.nii.gz

  wb_command -metric-dilate /home/lmarcos/Results/"${id}"/"${id}"_"${ses}"_hemi-L_"${dat}"."${mod}".gii \
    "${ANAT_FOLDER}"/"${id}"/"${ses}"/anat/"${id}"_"${ses}"_hemi-L_space-T2w_pial.surf.gii 10 \
    /home/lmarcos/Results/"${id}"/"${id}"_"${ses}"_hemi-L_"${dat}"."${mod}".gii -nearest


  wb_command -volume-to-surface-mapping "${TENSOR_FOLDER}"/"${id}"/"${id}"_"${dat}".nii.gz \
    "${ANAT_FOLDER}"/"${id}"/"${ses}"/anat/"${id}"_"${ses}"_hemi-R_space-T2w_midthickness.surf.gii \
    /home/lmarcos/Results/"${id}"/"${id}"_"${ses}"_hemi-R_"${dat}"."${mod}".gii \
    -ribbon-constrained  \
    "${ANAT_FOLDER}"/"${id}"/"${ses}"/anat/"${id}"_"${ses}"_hemi-R_space-T2w_wm.surf.gii \
    "${ANAT_FOLDER}"/"${id}"/"${ses}"/anat/"${id}"_"${ses}"_hemi-R_space-T2w_pial.surf.gii \
    -volume-roi /home/lmarcos/tmp/"${id}"_"${ses}"_hemi-R.ribbon.nii.gz
  
  wb_command -metric-dilate /home/lmarcos/Results/"${id}"/"${id}"_"${ses}"_hemi-R_"${dat}"."${mod}".gii \
    "${ANAT_FOLDER}"/"${id}"/"${ses}"/anat/"${id}"_"${ses}"_hemi-R_space-T2w_pial.surf.gii 10 \
    /home/lmarcos/Results/"${id}"/"${id}"_"${ses}"_hemi-R_"${dat}"."${mod}".gii -nearest


 done

 rm -r /home/lmarcos/tmp

done < /home/lmarcos/subject-session-age
