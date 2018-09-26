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
	if [ ! -d $android_build ]; then
		mkdir $android_build
	fi
	cd $android_build
elif [ $# == 2 ]; then
	manifests_source=$2_apk
	if [ ! -d $android_build ]; then
		mkdir $android_build
		cd $android_build
		../extract_apks.sh $2
	else
		cd $android_build
		if [ ! -d $manifests_source ]; then
			../extract_apks.sh $2
		fi
	fi
else
	echo "Usage: tool -a|-s android_build [manifests_source]"
	exit 1
fi

# Step 1
# ------
# Find all the AndroidManifest.xml in the source code tree

# extract list of installed packages
if [ ! -f "packages.txt" ]; then
	echo -en "Reading list of installed packages.."
	$adb shell pm list packages > tmp
	file="tmp"
	while IFS= read -r line
	do	
		echo $line | cut -c 9- >> packages.txt
	done < $file
	rm tmp
	echo " done."
fi

if [ ! -f "manifest_files.txt" ]; then
	echo -en "Searching all $manifest_name files in $manifests_source.. "
	find $manifests_source -name $manifest_name > manifest_files.txt
	echo -en "done.\n"
fi

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
		adb_command_i="$adb shell am start -a"
		adb_command_e="$adb shell am start -n"
		;;
	-s)
		# Search for exposed services
		echo -en "Searching for exposed services..\n\n"
		python3 ../services.py
		intents_i="test_services_i.txt"
		intents_e="test_services_e.txt"
		adb_command_i="$adb shell am startservice -a"
		adb_command_e="$adb shell am startservice -n"
		;;
	*)
		cd ..
		rm -r $2
		echo "Usage: tool -a|-s android_build [manifests_source]"
		exit 1
esac

echo -en "\nDo you want to test the exposed components on the connected device? [y|n] "
read answer
if [ $answer != 'y' ]; then
	exit 1
fi
echo -en '\n'

# Step 3
# ------
# Test exposed components
echo "Testing exposed components with implicit intents.."
echo "##################################################"
echo "Logcat crash channell #" > crash_report_i.txt
echo -en "#######################\n\n" >> crash_report_i.txt
echo "Adb activity manager output #" > log.txt
echo -en "#############################\n\n" >> log.txt
while read -r action;
do
	echo "Intent action: $action"
	# Click home button
	$adb shell input tap 540 1855 < /dev/null
	sleep 2
	# Clear logcat crash channel
	$adb logcat -b crash -c < /dev/null
	# Start the activity
	$adb_command_i "$action" < /dev/null >> log.txt
	sleep 4
	# Print logcat crash channel
	tmp=$($adb logcat -b crash -d < /dev/null)
	if [ "$tmp" != "" ]; then
		echo "################################" >> crash_report_i.txt 
		echo "$tmp" >> crash_report_i.txt
		echo "################################" >> crash_report_i.txt
		echo -en '\n' >> crash_report_i.txt
	fi
done < $intents_i

echo "Testing exposed components with explicit intents.."
echo "##################################################"
echo "Logcat crash channell #" > crash_report_i.txt
echo -en "#######################\n\n" >> crash_report_i.txt
while read -r action;
do
	echo "Intent: $action"
	# Click home button
	$adb shell input tap 540 1855 < /dev/null
	sleep 2
	# Clear logcat crash channel
	$adb logcat -b crash -c < /dev/null
	# Start the activity
	$adb_command_e "$action" < /dev/null >> log.txt
	sleep 4
	# Print logcat crash channel
	tmp=$($adb logcat -b crash -d < /dev/null)
	if [ "$tmp" != "" ]; then
		echo "################################" >> crash_report.txt 
		echo "$tmp" >> crash_report.txt
		echo "################################" >> crash_report.txt
		echo -en '\n' >> crash_report.txt
	fi
done < $intents_e