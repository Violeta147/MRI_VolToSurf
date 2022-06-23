Work_dir=/media/BabyBrain/preterm
FWHM="6"
while IFS=$", " read -r Subject Ses
do
 echo " "
 echo "##################### ${Subject}, ${Ses} ######################"
 bash fMRI_Vol2Cifti.sh "${Subject}" "${Ses}" "${Work_dir}" "${FWHM}"
done < /home/vsanchez/Documents/subject-session
