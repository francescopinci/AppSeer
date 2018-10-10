#!/bin/bash

# Francesco Pinci - pinci.francesco@gmail.com
# This tool extract exposed activities or services by AOSP and connected devices

adb="../platform-tools/adb"
manifest_name="AndroidManifest.xml"

# Usage ./tool -a|-s android_build
# a : activities
# s : services
build=$2
if [[ $1 == "-a" ]]; then
	build_results=$build'_a'
else
	build_results=$build'_s'
fi

AOSP_manifests_source=../$build
device_manifests_source='./APKs'

flag=false

if [ $# != 2 ]; then
	echo "Usage: tool -a|-s android_build"
	exit 1
else
	if [ ! -d $build_results ]; then
		flag=true
		mkdir $build_results	
	fi
	cd $build_results
fi

# Step 1
# ----------------------------------------------------------------
# Find AOSP and device components

# extract list of installed packages on connected device
if [ $($adb devices | wc -l) -lt 3 ]; then
	if [ ! -d APKs ] || [ ! -f packages.txt ]; then
		echo "Connect a device and enable ADB debugging to run the tool"
		if $flag; then
			rm -r $build_results
		fi
		exit 1
	fi
elif [ ! -f "packages.txt" ]; then
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

# device components
# find AndroidManifest.xml files in the device APKs
if [ ! -d "APKs" ]; then
	../extract_apks.sh
fi

# AOSP components
# find AndroidManifest.xml files in the build source code (AOSP) and in the APKs present on the device
if [ ! -f "manifests.txt" ]; then
	echo -en "Searching all $manifest_name files in $build.. "
	find $AOSP_manifests_source -name $manifest_name > manifests.txt
	echo -en "done.\n"

	echo -en "Searching all $manifest_name files in device APKs.. "
	find $device_manifests_source -name $manifest_name > manifests.txt
	echo -en "done.\n"
fi	


# Step 2
# ----------------------------------------------------------------
# Search for exposed components
echo -en "\nDo you want to search for exposed components? [y|n] "
read answer
if [ $answer != 'y' ]; then
	exit 1
fi
echo -en '\n'

case $1 in
	-a)
		# Search for exposed activities
		#echo -en "Searching for exposed activities..\n\n"
		#python3 ../activities.py
		intents_i="test_activities_i.txt"
		intents_e="test_activities_e.txt"
		adb_command_i="$adb shell am start -a"
		adb_command_e="$adb shell am start -n"
		;;
	-s)
		# Search for exposed services
		#echo -en "Searching for exposed services..\n\n"
		#python3 ../services.py
		intents_i="test_services_i.txt"
		intents_e="test_services_e.txt"
		adb_command_i="$adb shell am startforegroundservice -a"
		adb_command_e="$adb shell am startforegroundservice -n"
		;;
	*)
		cd ..
		if $flag; then
			rm -r $build_results
		fi
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
echo "List of actions crashing processes (implicit intents):" > crash_actions.txt
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
		echo "$action" >> crash_actions.txt
		echo "################################" >> crash_report_i.txt 
		echo "$tmp" >> crash_report_i.txt
		echo "################################" >> crash_report_i.txt
		echo -en '\n' >> crash_report_i.txt
	fi
done < $intents_i

echo "Testing exposed components with explicit intents.."
echo "##################################################"
echo "Logcat crash channell #" > crash_report_e.txt
echo -en "#######################\n\n" >> crash_report_e.txt
echo -en "\n\nList of actions crashing processes (explicit intents):\n" >> crash_actions.txt
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
	sleep 6
	# Print logcat crash channel
	tmp=$($adb logcat -b crash -d < /dev/null)
	if [ "$tmp" != "" ]; then
		echo "$action" >> crash_actions.txt
		echo "################################" >> crash_report_e.txt 
		echo "$tmp" >> crash_report_e.txt
		echo "################################" >> crash_report_e.txt
		echo -en '\n' >> crash_report_e.txt
	fi
done < $intents_e