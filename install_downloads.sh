#!/bin/bash

# Note: This script assumes macOS 10.11 or higher. It is not expected to work with earlier versions of macOS.

os_version=$(./os_version.sh)
trackpad_model=$(./trackpad_model.sh)

if [ $os_version -lt 11 ]; then
    echo Unsupported macOS version! Exiting...
    exit 1
fi

exceptions="Sensors|FakePCIID_BCM57XX|FakePCIID_Intel_GbX|FakePCIID_Intel_HDMI|FakePCIID_XHCIMux|FakePCIID_AR9280_as_AR946x|BrcmFirmwareData|PatchRAM.kext|PS2|Lilu|IntelGraphicsFixup"

function extract() {
    filePath=${1/.zip/}
    rm -Rf $filePath
    unzip -q $1 -d $filePath
    rm -Rf $filePath/__MACOSX
}

function install() {
    if [[ -e $1 && -d $2 ]]; then
        fileName=$(basename $1)
        echo Installing $fileName to $2
        sudo rm -Rf $2/$fileName
        sudo cp -Rf $1 $2
    fi
}

function findKext() {
    if [[ "${@:2}" == "" ]]; then
        find ./ -path \*/$1 -not -path \*/PlugIns/* -not -path \*/Debug/*
    else
        find ${@:2} -path \*/$1 -not -path \*/PlugIns/* -not -path \*/Debug/*
    fi
}

function installKext() {
    if [ -e $1 ]; then
        install $1 /Library/Extensions
    else
        install $(findKext $1) /Library/Extensions
    fi
}

function installBinary() {
    install $1 /usr/bin
}

function installApp() {
    install $1 /Applications
}

function extractAll() {
    for zip in $(find $@ -name *.zip); do
        extract $zip
    done
}

function installApps() {
    for app in $(find $@ -name *.app); do
        installApp $app
    done
}

function installBinaries() {
    for bin in $(find $@ -type f -perm -u+x -not -path \*.kext/* -not -path \*.app/* -not -path \*/Debug/*); do
        if [[ $(echo $(basename $bin) | grep -vE $exceptions) != "" ]]; then
            installBinary $bin
        fi
    done
}

function installKexts() {
    for kext in $(findKext "*.kext" $@); do
        if [[ $(echo $(basename $kext) | grep -vE $exceptions) != "" ]]; then
            installKext $kext
        fi
    done
}

function uninstallKext() {
    sudo rm -Rf $(findKext $1 /System/Library/Extensions /Library/Extensions)
}

# Extract all zip files within ./downloads folder
extractAll ./downloads

# Install all apps (*.app) within ./downloads folder
installApps ./downloads

# Install all binaries within ./downloads folder
installBinaries ./downloads

# Install all the kexts within ./downloads & ./kexts folders that are not in the 'exceptions'
installKexts ./downloads ./kexts

# Intel HD 4400 needs Lilu.kext+IntelGraphicsFixup.kext on macOS 10.12
if [[ $os_version -ge 12 ]]; then
    installKext Lilu.kext
    installKext IntelGraphicsFixup.kext
fi

# If trackpad is Synaptics, install RehabMan's VoodooPS2Controller.kext
if [[ $trackpad_model == "SYN"* ]]; then
    uninstallKext ApplePS2SmartTouchPad.kext
    installKext VoodooPS2Controller.kext
# Otherwise, install EMlyDinEsH's ApplePS2SmartTouchPad.kext
else
    uninstallKext VoodooPS2Controller.kext
    installKext ApplePS2SmartTouchPad.kext
fi

# Create & install AppleHDA injector kext for CX20751
HDA=CX20751
./patch_hda.sh $HDA
installKext AppleHDA_$HDA.kext

# Repair permissions & update kernel cahce
sudo kextcache -i /
