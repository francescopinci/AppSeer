#!/bin/bash

# Decompile APK files from APKs directory, using apktool
dir="APKs"
if [ ! -d $dir ]; then
	echo -en "No APKs folder"
fi

cd $dir
find . -name '*.apk' > ../tmp

# decompile apks
file="../tmp"
while IFS= read -r line
do	
	apk_file=$(echo $line | cut -c 3-)
	apk_folder=$(basename -s ".apk" $apk_file)
	echo "Decompiling $apk_folder"
	apktool d -f $apk_file > /dev/null 2>&1
	#rm -r $apk_folder/original/ > /dev/null 2>&1
	#rm -r $apk_folder/res/ > /dev/null 2>&1
done < $file
rm $file
cd ..