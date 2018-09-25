#!/bin/bash

# Francesco Pinci - pinci.francesco@gmail.com
# This tool extract exposed activities or services by AOSP and connected devices

adb="../platform-tools/adb"
manifest_name="AndroidManifest.xml"

# Usage ./tool -a|-s android_build [manifests_source]
# a : activities
# s : services
folder=$2
if [[ $1 == "-a" ]]; then
	android_build=$2_a
else
	android_build=$2_s
fi

if [ $# == 3 ]; then
	manifests_source=$3
	mkdir $android_build
	cd $android_build
elif [ $# == 2 ]; then
	manifests_source=$2_apk
	mkdir $android_build
	cd $android_build
	../extract_apks.sh $2
else
	echo "Usage: tool -a|-s android_build [manifests_source]"
	exit 1
fi

# Step 1
# ------
# Find all the AndroidManifest.xml in the source code tree

# extract list of installed packages
echo -en "Reading list of installed packages.."
$adb shell pm list packages > tmp
file="tmp"
while IFS= read -r line
do	
	echo $line | cut -c 9- >> packages
done < $file
rm tmp
echo " done."

echo -en "Searching all $manifest_name files in $manifests_source.. "
find $manifests_source -name $manifest_name > manifest_files.txt
echo -en "done.\n"

# Step 2
# ------
# Detect if activities or services are requested
case $1 in
	-a)
		# Search for exposed activities
		echo -en "Searching for exposed activities..\n\n"
		python3 ../activities.py
		intents_i="test_activities_i.txt"
		intents_e="test_activities_e.txt"
		;;
	-s)
		# Search for exposed services
		echo -en "Searching for exposed services..\n\n"
		python3 ../services.py
		intents_i="test_services_i.txt"
		intents_e="test_services_e.txt"
		;;
	*)
		cd ..
		rm -r $2
		echo "Usage: tool -a|-s android_build [manifests_source]"
		exit 1
esac
