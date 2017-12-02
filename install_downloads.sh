#!/bin/bash

# Note: This script assumes macOS 10.11 or higher. It is not expected to work with earlier versions of macOS.

os_version=$(./os_version.sh)
trackpad_model=$(./trackpad_model.sh)

if [ $os_version -lt 11 ]; then
    echo Unsupported macOS version! Exiting...
    exit 1
fi

exceptions="Sensors|FakePCIID_BCM57XX|FakePCIID_Intel_GbX|FakePCIID_Intel_HDMI|FakePCIID_XHCIMux|FakePCIID_AR9280_as_AR946x|BrcmFirmwareData|PatchRAM.kext|VoodooPS2Controller|Lilu|IntelGraphicsFixup"

function checkDirectory() {
    for x in $1; do
        if [ -e $x ]; then
            return 1
        else
            return 0
        fi
    done
}

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
    find $1 -path */$2 -prune -not -path */Debug/*
}

function filterKext() {
    if [[ $(echo $(basename $1) | grep -vE $exceptions) != "" ]]; then
        installKext $1
    fi
}

function installKext() {
    install $1 /Library/Extensions
}

function installApp() {
    install $1 /Applications
}

function installBinary() {
    install $1 /usr/bin
}

function installDaemon() {
    install $1 /Library/LaunchDaemons
}

function extractAll() {
    for zip in $(find $1 -name *.zip); do
        extract $zip
    done
}

function installApps() {
    for app in $(find $1 -name *.app); do
        installApp $app
    done
}

function installKexts() {
    for kext in $(findKext $1 *.kext); do
        filterKext $kext
    done
}

checkDirectory ./downloads
if [ $? -ne 0 ]; then
    cd ./downloads

    # Extract all zip files within ./downloads
    extractAll ./

    # Install all apps (*.app) within ./downloads
    installApps ./

    # Install iasl
    installBinary $(find . -type f -name iasl)
    # Install patchmatic
    installBinary $(find . -type f -name patchmatic)

    # Install all the kexts within ./downloads that are not in the 'exceptions'
    installKexts ./

    # Intel HD 4400 needs Lilu.kext+IntelGraphicsFixup.kext on macOS 10.12
    if [[ $os_version -ge 12 ]]; then
        installKext $(findKext ./ Lilu.kext)
        installKext $(findKext ./ IntelGraphicsFixup.kext)
    fi

    # If trackpad is Synaptics, install RehabMan's VoodooPS2Controller.kext
    if [[ $trackpad_model == "SYN"* ]]; then
        sudo rm -Rf /Library/Extensions/ApplePS2SmartTouchPad.kext
        installKext $(findKext ./ VoodooPS2Controller.kext)
        installBinary $(find ./ -path */Release/VoodooPS2Daemon -prune)
        installDaemon $(find ./ -name org.rehabman.voodoo.driver.Daemon.plist)
    # Otherwise, install EMlyDinEsH's ApplePS2SmartTouchPad.kext
    else
        sudo rm -Rf /Library/Extensions/VoodooPS2Controller.kext
        installKext $(findKext ../ ApplePS2SmartTouchPad.kext)
    fi

    cd ..
fi

# Create & install AppleHDA injector kext for CX20751
HDA=CX20751
./patch_hda.sh $HDA
installKext AppleHDA_$HDA.kext

# Create & install AppleBacklight injector kext
./patch_backlight.sh
installKext AppleBacklightInjector.kext

# Repair permissions & update kernel cahce
echo Updating kernel cahce...
sudo kextcache -i / 2>/dev/null
