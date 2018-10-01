#!/bin/bash

# Usage: ./extract_apks.sh device_build
# Extracts and decompiles all the apks present in the connected device

# set adb folder for correct functioning
adb="../platform-tools/adb"

file="apks"
echo -en "Creating apk files list.."
echo "find system/ -name \"*.apk\"" | $adb shell su > $file
echo " done."

dir="APKs"
mkdir $dir

echo -en "Pulling the apk files from the device.."
while IFS= read -r line
do
	$adb pull $line $dir > /dev/null
done < $file
rm $file
echo -en " done.\n"

cd $dir
find . -name '*.apk' > tmp

# decompile apks
file="tmp"
echo -en "Decompiling apks.."
while IFS= read -r line
do	
	apk_file=$(echo $line | cut -c 3-) 
	apktool d -f $apk_file > /dev/null 2>&1
	apk_folder=$(basename -s ".apk" $apk_file)
	rm -r $apk_folder/original/ > /dev/null 2>&1
done < $file
rm tmp
cd ..
echo -en " done.\n"