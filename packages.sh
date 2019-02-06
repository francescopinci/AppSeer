#!/bin/bash
# extract installed packages list from connected device
adb="platform-tools/adb"

echo -en "Reading list of installed packages.."
$adb shell pm list packages > tmp
file="tmp"
while IFS= read -r line
do	
	echo $line | cut -c 9- >> packages.txt
done < $file
rm tmp
echo " done."
