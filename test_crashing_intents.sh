#!/bin/bash

adb="./platform-tools/adb"
input=actions

while read -r action;
do
	read -p "Start next intent?" </dev/tty
	$adb shell am start -a $action < /dev/null
done < $input
