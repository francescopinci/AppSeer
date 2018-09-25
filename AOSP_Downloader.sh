#!/bin/bash

# Give the AOSP build name as input parameter
# Build name can be found at https://source.android.com/setup/start/build-numbers.html#source-code-tags-and-builds

build=$1

mkdir $build
cd $build

git config --global user.name "Francesco"
git config --global user.email "fpinci2@uic.edu"

repo init -u https://android.googlesource.com/platform/manifest -b $build

repo sync
