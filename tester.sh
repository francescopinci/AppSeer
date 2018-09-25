#!/bin/bash

# Francesco Pinci - pinci.francesco@gmail.com
# This tool test exposed activities or services on the connected device

# Step 3
# ------
# Test extracted intents one by one
# For each line of the file
# while read -r intent;
# do
# 	echo "Intent: $intent"
# 	# Click home button
# 	$adb shell input tap 540 1855 < /dev/null
# 	sleep 2
# 	# Clear logcat crash channel
# 	$adb logcat -b crash -c < /dev/null
# 	# Start the activity
# 	$adb shell am start -a "$intent" < /dev/null
# 	sleep 4
# 	# Print logcat crash channel
# 	$adb logcat -b crash -d -m 1 < /dev/null > report
# done < $intents_i