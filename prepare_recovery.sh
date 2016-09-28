#!/bin/bash

# Written by the-braveknight, based on RehabMan's scripts.

# This script simply copies what's necessary to boot
# the macOS/OS X recovery to EFI/CLOVER.

SUDO=sudo
EFI=`$SUDO ./mount_efi.sh /`
CLOVER=$EFI/EFI/CLOVER
KEXTDEST=$CLOVER/kexts/Other

function install_kext
{
    if [ "$1" != "" ]; then
        echo Installing $1 to $KEXTDEST
        rm -Rf $KEXTDEST/`basename $1`
        cp -Rf $1 $KEXTDEST
    fi
}


# Download required kexts
./download.sh recovery_kexts



# Remove Clover/kexts/10.* folders, keep 'Others' only.
rm -Rf $CLOVER/kexts/10.*
# Remove any kext(s) already present in 'Others' folder.
rm -Rf $KEXTDEST/*.kext


# Extract & install downloaded kexts
cd ./downloads/kexts
rm -Rf */
mkdir RehabMan-FakeSMC-REC && unzip -q RehabMan-FakeSMC-*.zip -d RehabMan-FakeSMC-REC
mkdir RehabMan-Realtek-Network-v2-REC && unzip -q RehabMan-Realtek-Network-v2-*.zip -d RehabMan-Realtek-Network-v2-REC
mkdir RehabMan-Battery-REC && unzip -q RehabMan-Battery-*.zip -d RehabMan-Battery-REC
cd RehabMan-FakeSMC-REC && install_kext FakeSMC.kext && cd ..
cd RehabMan-Realtek-Network-v2-REC/Release && install_kext RealtekRTL8111.kext && cd ..//..
cd RehabMan-Battery-REC/Release && install_kext ACPIBatteryManager.kext && cd ..//..
cd ..//..

# Install local kexts
cd ./kexts
install_kext USBXHC_*.kext
install_kext ApplePS2SmartTouchPad.kext
# Install AirPortInjector.kext by default
if [ "$1" != "native_wifi" ]; then
    install_kext AirPortInjector.kext
fi
cd ..

# Download & copy HFSPlus.efi from CloverGrowerPro repo to CLOVER/drivers64UEFI if it's not present
if [ ! -e $CLOVER/drivers64UEFI/HFSPlus.efi ]; then
    echo Downloading HFSPlus.efi...
    curl https://raw.githubusercontent.com/JrCs/CloverGrowerPro/master/Files/HFSPlus/X64/HFSPlus.efi -o ./downloads/HFSPlus.efi -s
    echo Copying HFSPlus.efi to $CLOVER/drivers64UEFI
    cp ./downloads/HFSPlus.efi $CLOVER/drivers64UEFI
fi

echo Done.
