#!/bin/bash

### This script computes transforms an atlas from fs_LR32k template space to Baby subject-specific space
### Mandatory input positional arguments are:
### 	- fs_LR32k_dir: Directory where the fs_LR32k template data is stored
### 	- Work_dir: Directory where the Subjects are stored
### 	- Temp_dir: Directory where the template is stored (with volume and surface template directories inside)
### 	- Subject: Subject ID
### 	- Ses: Scan session
### 	- Week: Week of total age of the Subject
### Optional flags and their input arguments are:
###	    -a --atlas <Atlas_name> : Name of the atlas you want to transform. Options are Desikan (default), AAL, Yeo_JNeurophysiol11_7Networks, 
###     Baldassano, Destrieux and Fan_2016

Atlas=Desikan
Overwrite=0

PARAMS=""
while (( "$#" )) ; do
  case "$1" in
    -a|--atlas)
      if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
        Atlas=$2
        shift 2
      else
        echo "Error: Argument for $1 is missing" >&2
        exit 1
      fi
      ;;
    -o|--overwrite)
      if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
        Overwrite=$2
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

fs_LR32k_dir=$1
Work_dir=$2
Temp_dir=$3
Subject=$4
Ses=$5
Week=$6

Transf_dir="${Temp_dir}"/Transforms_fs_LR32k
Atlas_dir="${Temp_dir}"/Atlas_Template
Out_dir=/media/BabyCake/processing/dHCP-anat-atlas

if [ "${Overwrite}" -eq 0 ]; then

 if [ -f "${Out_dir}"/"${Subject}"/"${Ses}"/"${Subject}"_"${Ses}"_"${Atlas}".32k.R.label.gii ]; then

  echo "Atlas of session ${Ses} of subject ${Subject} already precomputed, change --overwrite option to 1 if you want to do it again"

  exit 0

 fi

fi

if ! [ -d "${Work_dir}"/"${Subject}"/"${Ses}"/tmp ]; then

 mkdir "${Work_dir}"/"${Subject}"/"${Ses}"/tmp

fi


if ! [ -d "${Out_dir}"/"${Subject}" ]; then

  mkdir "${Out_dir}"/"${Subject}"

fi

if ! [ -d "${Out_dir}"/"${Subject}"/"${Ses}" ]; then

  mkdir "${Out_dir}"/"${Subject}"/"${Ses}"

fi


#### Estimate fs_LR32k transformation to 40 week template

for hemi in left right
do

 if [[ "${hemi}" == "left" ]]; then
  hemi2=L
 else
  hemi2=R
 fi

 if ! [ -f "${Transf_dir}"/week-40_"${hemi2}".sphere.reg.surf.gii ]; then 
  
  echo "Estimating surface registration from fs_LR32k to 40 week template"

  msm_ubuntu_v3 --conf="${fs_LR32k_dir}"/../Utils/conf.txt \
      --inmesh="${fs_LR32k_dir}"/fs_LR.32k."${hemi2}".sphere.surf.gii \
      --indata="${fs_LR32k_dir}"/fs_LR.32k."${hemi2}"_sulc.shape.gii \
      --refmesh="${Temp_dir}"/SurfaceTemplate/week-40_hemi-"${hemi}"_space-dhcpSym_dens-32k_sphere.surf.gii \
      --refdata="${Temp_dir}"/SurfaceTemplate/week-40_hemi-"${hemi}"_space-dhcpSym_dens-32k_sulc.shape.gii \
      --out="${Transf_dir}"/week-40_"${hemi2}".

 else

  echo "Surface registration from fs_LR32k to 40 week template already computed"

 fi

done


#### Apply transformation to atlas

for hemi in left right
do

 if [[ "${hemi}" == "left" ]]; then
  hemi2=L
 else
  hemi2=R
 fi

 if ! [ -f "${Atlas_dir}"/Baby_"${Atlas}"_week-40.32k."${hemi2}".label.gii ]; then

  echo "Applying surface fs_LR32k-to-40-week-template registration to ${Atlas} atlas"

  wb_command -label-resample "${fs_LR32k_dir}"/"${Atlas}".32k."${hemi2}".label.gii \
      "${Transf_dir}"/week-40_"${hemi2}".sphere.reg.surf.gii \
      "${Temp_dir}"/SurfaceTemplate/week-40_hemi-"${hemi}"_space-dhcpSym_dens-32k_sphere.surf.gii \
      ADAP_BARY_AREA "${Atlas_dir}"/Baby_"${Atlas}"_week-40.32k."${hemi2}".label.gii \
      -area-surfs "${fs_LR32k_dir}"/fs_LR.32k."${hemi2}".midthickness.surf.gii \
      "${Temp_dir}"/SurfaceTemplate/week-40_hemi-"${hemi}"_space-dhcpSym_dens-32k_midthickness.surf.gii

 else

  echo "40 week ${Atlas} atlas already exists"

 fi

  
 if ! [ "${Week}" -eq 40 ]; then
   
  if ! [ -f "${Atlas_dir}"/Baby_"${Atlas}"_week-"${Week}".32k."${hemi2}".label.gii ]; then

    echo "Applying surface registration transform from 40 to ${Week} week template to ${Atlas} atlas"

    #python3.6 -c "from inv_surf_warp_init import inv_surf_warp_init; inv_surf_warp_init('${Temp_dir}/SurfaceTemplate/week-to-40-registrations/${hemi}.${Week}-to-40/${hemi}.${Week}-to-40sphere.reg.surf.gii', \
    #    '${Work_dir}/${Subject}/${Ses}/tmp/40-to-${Week}_${hemi2}.sphere.surf.gii')"

    msm_ubuntu_v3 --conf="${fs_LR32k_dir}"/../Utils/conf.txt \
        --inmesh="${Temp_dir}"/SurfaceTemplate/week-40_hemi-"${hemi}"_space-dhcpSym_dens-32k_sphere.surf.gii \
        --indata="${Temp_dir}"/SurfaceTemplate/week-40_hemi-"${hemi}"_space-dhcpSym_dens-32k_sulc.shape.gii \
        --refmesh="${Temp_dir}"/SurfaceTemplate/week-"${Week}"_hemi-"${hemi}"_space-dhcpSym_dens-32k_sphere.surf.gii \
        --refdata="${Temp_dir}"/SurfaceTemplate/week-"${Week}"_hemi-"${hemi}"_space-dhcpSym_dens-32k_sulc.shape.gii \
        --out="${Temp_dir}"/Transforms_fs_LR32k/40-to-"${Week}"_"${hemi2}".
        #--trans="${Work_dir}"/"${Subject}"/"${Ses}"/tmp/40-to-"${Week}"_"${hemi2}".sphere.surf.gii \
        #--out="${Temp_dir}"/Transforms_fs_LR32k/40-to-"${Week}"_"${hemi2}".

    wb_command -label-resample "${Atlas_dir}"/Baby_"${Atlas}"_week-40.32k."${hemi2}".label.gii \
        "${Temp_dir}"/Transforms_fs_LR32k/40-to-"${Week}"_"${hemi2}".sphere.reg.surf.gii \
        "${Temp_dir}"/SurfaceTemplate/week-"${Week}"_hemi-"${hemi}"_space-dhcpSym_dens-32k_sphere.surf.gii \
        ADAP_BARY_AREA "${Atlas_dir}"/Baby_"${Atlas}"_week-"${Week}".32k."${hemi2}".label.gii \
        -area-surfs "${Temp_dir}"/SurfaceTemplate/week-40_hemi-"${hemi}"_space-dhcpSym_dens-32k_midthickness.surf.gii \
        "${Temp_dir}"/SurfaceTemplate/week-"${Week}"_hemi-"${hemi}"_space-dhcpSym_dens-32k_midthickness.surf.gii


  else

   echo "${Week} week ${Atlas} atlas already exists"

  fi

 fi

done


#### Estimate transformation from Template space to Subject space

echo "Performing volumetric registration from template space to native space"

mirtk register "${Temp_dir}"/Template_cifti_pipeline/Template.nii.gz "${Work_dir}"/"${Subject}"/"${Ses}"/anat/"${Subject}"_"${Ses}"_desc-restore_T2w.nii.gz \
  -model Rigid -sim NMI -bins 64 -dofout "${Work_dir}"/"${Subject}"/"${Ses}"/tmp/volume_dof.dof

mirtk convert-dof "${Work_dir}"/"${Subject}"/"${Ses}"/tmp/volume_dof.dof "${Work_dir}"/"${Subject}"/"${Ses}"/tmp/volume_dof.mat \
  -target "${Temp_dir}"/Template_cifti_pipeline/Template.nii.gz -source "${Work_dir}"/"${Subject}"/"${Ses}"/anat/"${Subject}"_"${Ses}"_desc-restore_T2w.nii.gz \
  -output-format flirt

#flirt -in "${Temp_dir}"/Template_cifti_pipeline/Template.nii.gz \
#    -ref "${Work_dir}"/"${Subject}"/"${Ses}"/anat/"${Subject}"_"${Ses}"_desc-restore_T2w.nii.gz \
#    -cost normmi -dof 6 -omat "${Work_dir}"/"${Subject}"/"${Ses}"/tmp/volume_dof.mat


for hemi in left right
do

 if [[ "${hemi}" == "left" ]]; then
  hemi2=L
 else
  hemi2=R
 fi

 
 ### Apply volumetric transform and pre-rotation to template sphere
 
 wb_command -surface-apply-affine "${Work_dir}"/"${Subject}"/"${Ses}"/anat/"${Subject}"_"${Ses}"_hemi-"${hemi2}"_space-T2w_sphere.surf.gii \
    "${Work_dir}"/"${Subject}"/"${Ses}"/tmp/volume_dof.mat "${Work_dir}"/"${Subject}"/"${Ses}"/tmp/rot_intermediate_"${hemi2}".sphere.surf.gii

 wb_command -surface-modify-sphere "${Work_dir}"/"${Subject}"/"${Ses}"/tmp/rot_intermediate_"${hemi2}".sphere.surf.gii 100 \
    "${Work_dir}"/"${Subject}"/"${Ses}"/tmp/rot_intermediate_"${hemi2}".sphere.surf.gii -recenter

 wb_command -surface-apply-affine "${Work_dir}"/"${Subject}"/"${Ses}"/tmp/rot_intermediate_"${hemi2}".sphere.surf.gii \
    "${fs_LR32k_dir}"/../Utils/week40_toFS_LR_rot."${hemi2}".txt "${Work_dir}"/"${Subject}"/"${Ses}"/tmp/rot_"${hemi2}".sphere.surf.gii

 wb_command -surface-modify-sphere "${Work_dir}"/"${Subject}"/"${Ses}"/tmp/rot_"${hemi2}".sphere.surf.gii 100 \
   "${Work_dir}"/"${Subject}"/"${Ses}"/tmp/rot_"${hemi2}".sphere.surf.gii -recenter


 ### Estimate and apply surface registration from template to subject meshes

 echo "Performing surface registration from ${Week} week template space to ${Subject} native space"

 msm_ubuntu_v3 --conf="${fs_LR32k_dir}"/../Utils/conf.txt \
    --inmesh="${Work_dir}"/"${Subject}"/"${Ses}"/tmp/rot_"${hemi2}".sphere.surf.gii  \
    --indata="${Work_dir}"/"${Subject}"/"${Ses}"/anat/"${Subject}"_"${Ses}"_hemi-"${hemi2}"_space-T2w_sulc.shape.gii \
    --refmesh="${Temp_dir}"/SurfaceTemplate/week-"${Week}"_hemi-"${hemi}"_space-dhcpSym_dens-32k_sphere.surf.gii \
    --refdata="${Temp_dir}"/SurfaceTemplate/week-"${Week}"_hemi-"${hemi}"_space-dhcpSym_dens-32k_sulc.shape.gii \
    --out="${Out_dir}"/"${Subject}"/"${Ses}"/"${Subject}"_"${Ses}"_hemi-"${hemi2}"_from-template_week-"${Week}".


 wb_command -surface-sphere-project-unproject "${Temp_dir}"/SurfaceTemplate/week-"${Week}"_hemi-"${hemi}"_space-dhcpSym_dens-32k_sphere.surf.gii \
    "${Out_dir}"/"${Subject}"/"${Ses}"/"${Subject}"_"${Ses}"_hemi-"${hemi2}"_from-template_week-"${Week}".sphere.reg.surf.gii \
    "${Work_dir}"/"${Subject}"/"${Ses}"/anat/"${Subject}"_"${Ses}"_hemi-"${hemi2}"_space-T2w_sphere.surf.gii \
    "${Out_dir}"/"${Subject}"/"${Ses}"/"${Subject}"_"${Ses}"_hemi-"${hemi2}"_to-template_week-"${Week}".sphere.surf.gii


 wb_command -label-resample "${Atlas_dir}"/Baby_"${Atlas}"_week-"${Week}".32k."${hemi2}".label.gii \
    "${Out_dir}"/"${Subject}"/"${Ses}"/"${Subject}"_"${Ses}"_hemi-"${hemi2}"_to-template_week-"${Week}".sphere.surf.gii \
    "${Work_dir}"/"${Subject}"/"${Ses}"/anat/"${Subject}"_"${Ses}"_hemi-"${hemi2}"_space-T2w_sphere.surf.gii \
    ADAP_BARY_AREA \
    "${Out_dir}"/"${Subject}"/"${Ses}"/"${Subject}"_"${Ses}"_"${Atlas}".32k."${hemi2}".label.gii \
    -area-surfs "${Temp_dir}"/SurfaceTemplate/week-"${Week}"_hemi-"${hemi}"_space-dhcpSym_dens-32k_midthickness.surf.gii \
    "${Work_dir}"/"${Subject}"/"${Ses}"/anat/"${Subject}"_"${Ses}"_hemi-"${hemi2}"_space-T2w_midthickness.surf.gii

done

rm -r "${Work_dir}"/"${Subject}"/"${Ses}"/tmp
rm -r "${Out_dir}"/"${Subject}"/"${Ses}"/*logdir*
rm "${Out_dir}"/"${Subject}"/"${Ses}"/*LR*
rm "${Out_dir}"/"${Subject}"/"${Ses}"/*reprojected*

