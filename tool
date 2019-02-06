#!/bin/bash

# Francesco Pinci - pinci.francesco@gmail.com
# This tool extract exposed activities or services by AOSP and connected devices

adb="../platform-tools/adb"
manifest_name="AndroidManifest.xml"

# Usage: tool -a|-s [android_build]
# a : activities
# s : services

# choose the name of the folder containing the results ("android_build" if provided, otherwise "third-party"
if [[ $# -eq 2 ]]; then
	build=$2
else
	build="third-party"
fi

# include "_a" or "_s" at the end of the folder containing the results wether we are testing activities or services
if [[ $1 == "-a" ]]; then
	build_results=$build"_a"
elif [[ $1 == "-s" ]]; then
	build_results=$build"_s"
else
	echo "Invalid option (Valid: -a|-s)"
	exit 1
fi

# this variables contains the paths to the source directories/files containing the AndroidManifest.xml files analyzed by the tool
# directory containing the AOSP source code
AOSP_manifests_source=../$build
# the 'device_APKs' folder must contains the apk files extracted from a device
device_manifests_source='device_APKs'
# the user must place the apk files that he wants to analyze inside "third_party_APKs/APKs"
APKs_manifests_source='third_party_APKs/APKs'

# check if a folder containing results for the build already exists
flag=false
if [ ! -d $build_results ]; then
	flag=true
	mkdir $build_results	
fi
cd $build_results

# ----------------------------------------------------------------

# Test if a device is connected and ADB is working
if [ $($adb devices | wc -l) -lt 3 ]; then
	#if [ ! -d APKs ] || [ ! -f packages.txt ]; then
	echo "Connect a device and enable ADB debugging to run the tool"
	if $flag; then
		rm -r $build_results
	fi
	exit 1
	#fi
fi

# extract the list of packages which are actually installed on the device
# (in the AOSP you find a lot of AndroidManifest.xml files of applications not installed on every device, so just test those who are installed on the connceted device)
../packages.sh

# if only one argument was provided, the user wants to test the apks that he has placed in 
if [[ $# -ne 2 ]]; then
	# third-party applications
	# decompile the apk files
	# create a list of the apk files provided by the user
	ls ../third_party_APKs/APKs > ../third_party_APKs/applications.txt
	cd ../third_party_APKs/APKs/
	# decompile each apk
	while IFS= read -r line
	do
		echo "Decompiling $line"
		apk_file=$line
		apk_folder=$(basename -s ".apk" $line)
		mkdir $apk_folder
		mv $apk_file $apk_folder
		cd $apk_folder
		apktool d -f $apk_file > /dev/null 2>&1
		mv $apk_folder"/AndroidManifest.xml" ./
		# uncomment this to avoid keeping all the decompiled data and just store the AndroidManifest.xml
		#rm -r $apk_folder/
		cd ../
		#rm -r $apk_folder/original/ > /dev/null 2>&1
		#rm -r $apk_folder/res/ > /dev/null 2>&1
	done < '../applications.txt'

	# create a list of the manifest files found
	cd "../../"$build_results
	if [ ! -f "manifests.txt" ]; then
	echo -en "Searching all $manifest_name files in third-party APKs.. "
	find $APKs_manifests_source -name $manifest_name > manifests.txt
	echo -en "done.\n"
	fi
else
	# AOSP + device applications
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

	# extract APK files from the connected device
	if [ ! -d "device_APKs" ]; then
		../extract_apks.sh
	fi

	# AOSP components
	# find AndroidManifest.xml files in the build source code (AOSP) and in the APKs present on the device
	if [ ! -f "manifests.txt" ]; then
		echo -en "Searching all $manifest_name files in $build.. "
		find $AOSP_manifests_source -name $manifest_name >> manifests.txt
		echo -en "done.\n"

		echo -en "Searching all $manifest_name files in device APKs.. "
		find $device_manifests_source -name $manifest_name >> manifests.txt
		echo -en "done.\n"
	fi
fi

# Search exposed components
# ----------------------------------------------------------------

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
		# if [ $answer == 'y' ]; then
		# 	if [[ $# -eq 2 ]]; then
		# 		python3 ../activities.py
		# 	else
		# 		python3 ../activities_3rd.py
		# 	fi
		# fi
		intents_i="test_activities_i.txt"
		intents_e="test_activities_e.txt"
		adb_command_i="$adb shell am start -a"
		adb_command_e="$adb shell am start -n"
		;;
	-s)
		# Search for exposed services
		#echo -en "Searching for exposed services..\n\n"
		# if [ $answer == 'y' ]; then
		# 	if [[ $# -eq 2 ]]; then
		# 		python3 ../services.py
		# 	else
		# 		python3 ../services_3rd.py
		# 	fi
		# fi
		intents_i="test_services_i.txt"
		intents_e="test_services_e.txt"
		adb_command_i="$adb shell am startservice -a"
		adb_command_e="$adb shell am startservice -n"
		;;
	*)
		cd ..
		if $flag; then
			rm -r $build_results
		fi
		echo "usage: tool -a | -s [android_build]"
		exit 1
esac

# Test exposed components
# ----------------------------------------------------------------

echo -en "\nDo you want to test the exposed components on the connected device? [y|n] "
read answer
if [ $answer != 'y' ]; then
	exit 1
fi
echo -en '\n'

if [[ $# -eq 2 ]]; then
	echo "Testing exposed components with implicit intents.."
	echo "##################################################"
	echo "Logcat crash channell #" > crash_report_i.txt
	echo -en "#######################\n\n" >> crash_report_i.txt
	echo "Adb activity manager output #" > log.txt
	echo -en "#############################\n\n" >> log.txt
	echo "List of actions crashing processes (implicit intents):" > crash_actions.txt
	counter=0
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
		sleep 6
		# Print logcat crash channel
		tmp=$($adb logcat -b crash -d < /dev/null)
		if [ "$tmp" != "" ]; then
			counter=$(($counter+1))
			echo "$action" >> crash_actions.txt
			echo "################################" >> crash_report_i.txt 
			echo "$tmp" >> crash_report_i.txt
			echo "################################" >> crash_report_i.txt
			echo -en '\n' >> crash_report_i.txt
		fi
	done < $intents_i
	echo "Components causing applications to crash with implicit intents: $counter" >> results.txt

	echo -en "\nTesting exposed components with explicit intents..\n"
	echo "##################################################"
	echo "Logcat crash channell #" > crash_report_e.txt
	echo -en "#######################\n\n" >> crash_report_e.txt
	echo -en "\n\nList of actions crashing processes (explicit intents):\n" >> crash_actions.txt
	counter=0
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
			counter=$(($counter+1))
			echo "$action" >> crash_actions.txt
			echo "################################" >> crash_report_e.txt 
			echo "$tmp" >> crash_report_e.txt
			echo "################################" >> crash_report_e.txt
			echo -en '\n' >> crash_report_e.txt
		fi
	done < $intents_e
	echo "Components causing applications to crash with explicit intents: $counter" >> results.txt
else
	test 3rd party applications here
	echo "Testing exposed components with implicit intents.."
	echo "##################################################"
	echo "Logcat crash channell #" >> crash_report_i.txt
	echo -en "#######################\n\n" >> crash_report_i.txt
	echo "Adb activity manager output #" >> log.txt
	echo -en "#############################\n\n" >> log.txt
	echo "List of actions crashing processes (implicit intents):" >> crash_actions.txt
	first=true
	counter=0
	while read -r action;
	do
		if [ -f $action ]; then
			counted=false
			if [ $first = true ]; then
				first=false
			else
				# uninstall previous application
				echo -en "Uninstalling $previous.. "
				$adb uninstall $previous
			fi
			# install the apk on the device
			previous=${action##*/}
			previous=${previous%.apk}
		 	echo -en "\nInstalling $previous.. "
		 	# -g grant all permissions requested by the app
		 	$adb install -g $action
		 	echo "#################"
		else
			echo "Intent action: $action"
			# Click home button
			$adb shell input tap 540 1855 < /dev/null
			sleep 1
			# Clear logcat crash channel
			$adb logcat -b crash -c < /dev/null
			# Start the activity
			$adb_command_i "$action" < /dev/null >> log.txt
			sleep 6
			# Print logcat crash channel
			tmp=$($adb logcat -b crash -d < /dev/null)
			if [ "$tmp" != "" ]; then
				if [ $counted = false ]; then
					counted=true
					counter=$(($counter+1))
				fi
				echo "$action" >> crash_actions.txt
				echo "################################" >> crash_report_i.txt 
				echo "$tmp" >> crash_report_i.txt
				echo "################################" >> crash_report_i.txt
				echo -en '\n' >> crash_report_i.txt
			fi
		fi
	done < $intents_i
	echo "Applications crashing with implicit intents: $counter" >> results.txt

	echo "Testing exposed components with explicit intents.."
	echo "##################################################"
	echo "Logcat crash channell #" >> crash_report_e.txt
	echo -en "#######################\n\n" >> crash_report_e.txt
	echo -en "\n\nList of actions crashing processes (explicit intents):\n" >> crash_actions.txt
	first=true
	counter=0
	while read -r action;
	do
		if [ -f $action ]; then
			counted=false
			if [ $first = true ]; then
				first=false
			else
				# uninstall previous application
				echo -en "Uninstalling $previous.. "
				$adb uninstall $previous
			fi
			# install the apk on the device
			previous=${action##*/}
			previous=${previous%.apk}
		 	echo -en "\nInstalling $previous.. "
		 	# -g grant all permissions requested by the app
		 	$adb install -g $action
		 	echo "#################"
		else
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
				if [ $counted = false ]; then
					counted=true
					counter=$(($counter+1))
				fi
				echo "$action" >> crash_actions.txt
				echo "################################" >> crash_report_e.txt 
				echo "$tmp" >> crash_report_e.txt
				echo "################################" >> crash_report_e.txt
				echo -en '\n' >> crash_report_e.txt
			fi
		fi
	done < $intents_e
	echo "Applications crashing with explicit intents: $counter" >> results.txt
fi
