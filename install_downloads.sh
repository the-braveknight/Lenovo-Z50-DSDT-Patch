#!/bin/bash

# Note: This script assumes macOS 10.11 or higher. It is not expected to work with earlier versions of macOS.

os_version=$(./os_version.sh)
trackpad_version=$(./trackpad_version.sh)

if [ $os_version -lt 11 ]; then
    echo Unsupported macOS version! Exiting...
    exit 1
fi

exceptions="Sensors|FakePCIID_BCM57XX|FakePCIID_Intel_GbX|FakePCIID_Intel_HDMI|FakePCIID_XHCIMux|FakePCIID_AR9280_as_AR946x|BrcmFirmwareData|PatchRAM.kext|VoodooPS2Controller|Lilu|IntelGraphicsFixup"

function install
{
    fileName=$(basename $1)
    echo Installing $fileName to $2
    sudo rm -Rf $2/$fileName
    sudo cp -Rf $1 $2
}

function installKext
{
    install $1 /Library/Extensions
}

function installApp
{
    install $1 /Applications
}

function installBinary {
    install $1 /usr/bin
}

function extract
{
    filePath=${1/.zip/}
    rm -Rf $filePath
    unzip -q $1 -d $filePath
}

function checkDirectory
{
    for x in $1; do
        if [ -e $x ]; then
            return 1
        else
            return 0
        fi
    done
}

# Install downloaded apps & tools
checkDirectory ./downloads/tools
if [ $? -ne 0 ]; then
    cd ./downloads/tools

    checkDirectory *.zip
    if [ $? -ne 0 ]; then
        for zip in *.zip; do
            extract $zip
        done
    fi

    checkDirectory */*.app
    if [ $? -ne 0 ]; then
        for app in */*.app; do
            installApp $app
        done
    fi


    checkDirectory $(find . -perm +111 -type f -maxdepth 2)
    if [ $? -ne 0 ]; then
        for binary in $(find . -perm +111 -type f -maxdepth 2); do
            installBinary $binary
        done
    fi

    cd ../..
fi

# Install downloaded kexts
checkDirectory ./downloads/kexts
if [ $? -ne 0 ]; then
    cd ./downloads/kexts

    checkDirectory *.zip
    if [ $? -ne 0 ]; then
        for zip in *.zip; do
            extract $zip
        done
    fi

    checkDirectory */Release/*.kext
    if [ $? -ne 0 ]; then
        for kext in */Release/*.kext; do
            if [[ $(echo $(basename $kext) | grep -vE $exceptions) != "" ]]; then
                installKext $kext
            fi
        done
    fi

    checkDirectory */*.kext
    if [ $? -ne 0 ]; then
        for kext in */*.kext; do
            if [[ $(echo $(basename $kext) | grep -vE $exceptions) != "" ]]; then
                installKext $kext
            fi
        done
    fi

    # macOS 10.12 and higher requires Lilu.kext & IntelGraphicsFixup.kext
    if [[ $os_version -ge 12 ]]; then
        installKext RehabMan-Lilu*/Release/Lilu.kext
        installKext RehabMan-IntelGraphicsFixup*/Release/IntelGraphicsFixup.kext
    fi

    # If trackpad is Synaptics, install RehabMan's VoodooPS2Controller.kext
    if [[ $trackpad_version == "SYN"* ]]; then
        sudo rm -Rf /Library/Extensions/ApplePS2SmartTouchPad.kext
        installKext RehabMan-Voodoo*/Release/VoodooPS2Controller.kext
        install RehabMan-Voodoo-*/Release/VoodooPS2Daemon /usr/bin
        install RehabMan-Voodoo*/org.rehabman.voodoo.driver.Daemon.plist /Library/LaunchDaemons
    # Otherwise, install EMlyDinEsH's ApplePS2SmartTouchPad.kext
    else
        sudo rm -Rf /Library/Extensions/VoodooPS2Controller.kext
        installKext ../../kexts/ApplePS2SmartTouchPad.kext
    fi

    cd ../..
fi

# Create & install AppleHDA injector kext for CX20751
HDA=CX20751
./patch_hda.sh $HDA
installKext AppleHDA_$HDA.kext

# Create & install AppleBacklight injector kext
./patch_backlight.sh
installKext AppleBacklightInjector.kext

# Repair permissions
sudo kextcache -i /
