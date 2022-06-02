#!/bin/bash


for Map in mean cov ; do

 if ! [ -f "${Work_dir}"/"${Subject}"/tmp/"${hemi}"."${Map}"_all.native.func.gii ]; then

  wb_command -volume-to-surface-mapping "${Work_dir}"/"${Subject}"/tmp/"${Map}".nii.gz\
	"${Work_dir}"/"${Subject}"/hemi-"${hemi}"_midthickness.surf.gii "${Work_dir}"/"${Subject}"/tmp/"${hemi}"."${Map}".native.func.gii\
	-ribbon-constrained "${Work_dir}"/"${Subject}"/hemi-"${hemi}"_white.surf.gii "${Work_dir}"/"${Subject}"/hemi-"${hemi}"_pial.surf.gii\
	-volume-roi "${Work_dir}"/"${Subject}"/tmp/goodvoxels.nii.gz

  wb_command -metric-dilate "${Work_dir}"/"${Subject}"/tmp/"${hemi}"."${Map}".native.func.gii\
	"${Work_dir}"/"${Subject}"/hemi-"${hemi}"_midthickness.surf.gii 10 "${Work_dir}"/"${Subject}"/tmp/"${hemi}"."${Map}".native.func.gii -nearest

  wb_command -metric-mask "${Work_dir}"/"${Subject}"/tmp/"${hemi}"."${Map}".native.func.gii\
	"${Work_dir}"/"${Subject}"/hemi-"${hemi}"_roi.shape.gii "${Work_dir}"/"${Subject}"/tmp/"${hemi}"."${Map}".native.func.gii

  wb_command -volume-to-surface-mapping "${Work_dir}"/"${Subject}"/tmp/"${Map}".nii.gz 
	"${Work_dir}"/"${Subject}"/hemi-"${hemi}"_midthickness.surf.gii "${Work_dir}"/"${Subject}"/tmp/"${hemi}"."${Map}"_all.native.func.gii\
	-ribbon-constrained "${Work_dir}"/"${Subject}"/hemi-"${hemi}"_white.surf.gii "${Work_dir}"/"${Subject}"/hemi-"${hemi}"_pial.surf.gii

  wb_command -metric-mask "${Work_dir}"/"${Subject}"/tmp/"${hemi}"."${Map}"_all.native.func.gii\
	"${Work_dir}"/"${Subject}"/hemi-"${hemi}"_roi.shape.gii "${Work_dir}"/"${Subject}"/tmp/"${hemi}"."${Map}"_all.native.func.gii

 fi

    #wb_command -metric-resample tmp/"$hemi"."$Map".native.func.gii"$Subject"."$hemi".sphere.${RegName}.native.surf.gii "$DownsampleFolder"/"$Subject"."$hemi".sphere."$LowResMesh"k_fs_LR.surf.gii ADAP_BARY_AREA tmp/"$hemi"."$Map"."$LowResMesh"k_fs_LR.func.gii -area-surfs "$Subject"."$hemi"_midthickness.native.surf.gii "$DownsampleFolder"/"$Subject"."$hemi"_midthickness."$LowResMesh"k_fs_LR.surf.gii -current-roi "$Subject"."$hemi"_roi.native.shape.gii
    #wb_command -metric-mask tmp/"$hemi"."$Map"."$LowResMesh"k_fs_LR.func.gii "$DownsampleFolder"/"$Subject"."$hemi".atlasroi."$LowResMesh"k_fs_LR.shape.gii tmp/"$hemi"."$Map"."$LowResMesh"k_fs_LR.func.gii
    #wb_command -metric-resample tmp/"$hemi"."$Map"_all.native.func.gii "$Subject"."$hemi".sphere.${RegName}.native.surf.gii "$DownsampleFolder"/"$Subject"."$hemi".sphere."$LowResMesh"k_fs_LR.surf.gii ADAP_BARY_AREA tmp/"$hemi"."$Map"_all."$LowResMesh"k_fs_LR.func.gii -area-surfs "$Subject"."$hemi"_midthickness.native.surf.gii "$DownsampleFolder"/"$Subject"."$hemi"_midthickness."$LowResMesh"k_fs_LR.surf.gii -current-roi "$Subject"."$hemi"_roi.native.shape.gii
    #wb_command -metric-mask tmp/"$hemi"."$Map"_all."$LowResMesh"k_fs_LR.func.gii "$DownsampleFolder"/"$Subject"."$hemi".atlasroi."$LowResMesh"k_fs_LR.shape.gii tmp/"$hemi"."$Map"_all."$LowResMesh"k_fs_LR.func.gii

   
done
