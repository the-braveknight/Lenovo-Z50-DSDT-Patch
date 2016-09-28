#!/bin/bash

# Written by the-braveknight, based on RehabMan's scripts.

# This script simply installs what's necessary to boot the macOS/OS X recovery to
# EFI/CLOVER. It expects download.sh & install_downloads.sh scripts have already
# been run (kexts present in ./download/kexts).

SUDO=sudo
EFI=`$SUDO ./mount_efi.sh /`
CLOVER=$EFI/EFI/CLOVER
KEXTDEST=$CLOVER/kexts/Other
MINOR_VER=$([[ "$(sw_vers -productVersion)" =~ [0-9]+\.([0-9]+) ]] && echo ${BASH_REMATCH[1]})
if [[ $MINOR_VER -ge 11 ]]; then
    HDKEXTDIR=/Library/Extensions
else
    HDKEXTDIR=/System/Library/Extensions
fi

function install_kext
{
    if [ "$1" != "" ]; then
        echo Installing $1 to $KEXTDEST
        rm -Rf $KEXTDEST/`basename $1`
        cp -Rf $1 $KEXTDEST
    fi
}


# Remove Clover/kexts/10.* folders, keep 'Others' only.
rm -Rf $CLOVER/kexts/10.*
# Remove any kext(s) already present in 'Others' folder.
rm -Rf $KEXTDEST/*.kext


# Install kexts already downloaded by download.sh script
cd ./downloads/kexts
install_kext RehabMan-FakeSMC*/FakeSMC.kext
install_kext RehabMan-Realtek-Network-v2*/Release/RealtekRTL8111.kext
install_kext RehabMan-Battery*/Release/ACPIBatteryManager.kext
cd ../..

# Install local kexts
cd ./kexts
install_kext USBXHC_*.kext
# Installs the Wifi injector by default
if [ "$1" != "native_wifi" ]; then
    install_kext AirPortInjector.kext
fi
cd ..

# Install PS2 driver that's currently in use.
if [ -d $HDKEXTDIR/VoodooPS2Controller.kext ]; then
    cd ./downloads/kexts
    install_kext ./downloads/kexts/Release/VoodooPS2Controller.kext && cd ..
else
    install_kext ./kexts/ApplePS2SmartTouchPad.kext
fi

# Download & install HFSPlus.efi to CLOVER/drivers64UEFI if it's not present
if [ ! -e $CLOVER/drivers64UEFI/HFSPlus.efi ]; then
    echo Downloading HFSPlus.efi...
    curl https://raw.githubusercontent.com/JrCs/CloverGrowerPro/master/Files/HFSPlus/X64/HFSPlus.efi -o ./downloads/HFSPlus.efi -s
    echo Copying HFSPlus.efi to $CLOVER/drivers64UEFI
    cp ./downloads/HFSPlus.efi $CLOVER/drivers64UEFI
fi

echo Done.
