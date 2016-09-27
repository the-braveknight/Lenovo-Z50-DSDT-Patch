#!/bin/bash

# Written by the-braveknight, based on RehabMan's scripts.

# Note: this script requires download.sh & install_downloads.sh
# scripts to have run, Clover to have been installed prior to running it.

SUDO=sudo
EFI=`$SUDO ./mount_efi.sh /dev/disk1`
KEXTDEST=$EFI/EFI/CLOVER/kexts/Other
KEXTSDIR=./kexts
AKEXTSDIR=./downloads/kexts
config=$EFI/EFI/Clover/config.plist

BUILDDIR=./build

function install_kext
{
    if [ "$1" != "" ]; then
        echo installing $1 to $KEXTDEST
        $SUDO rm -Rf $KEXTDEST/`basename $1`
        $SUDO cp -Rf $1 $KEXTDEST
    fi
}

# Install kexts in the repo
cd $KEXTSDIR && install_kext USBXHC_z50.kext && cd ..
cd $KEXTSDIR && install_kext ApplePS2SmartTouchPad.kext && cd ..


# Install kexts downloaded by download.sh script
cd $AKEXTSDIR/RehabMan-FakeSMC* && install_kext FakeSMC.kext && cd ..//..//..
cd $AKEXTSDIR/RehabMan-Realtek-Network-v2*/Release && install_kext RealtekRTL8111.kext && cd ..//..//..//..
cd $AKEXTSDIR/RehabMan-Battery*/Release && install_kext ACPIBatteryManager.kext && cd ..//..//..//..


# Copy SSDT-HACK.aml from ./build to CLOVER/ACPI/patched
echo copying $BUILDDIR/SSDT-HACK.aml to $EFI/EFI/CLOVER/ACPI/patched
cp $BUILDDIR/SSDT-HACK.aml $EFI/EFI/CLOVER/ACPI/patched


# Download & copy HFSPlus.efi from CloverGrowerPro repo to CLOVER/drivers64UEFI
echo downloading HFSPlus.efi
curl -o HFSPlus.efi https://raw.githubusercontent.com/JrCs/CloverGrowerPro/master/Files/HFSPlus/X64/HFSPlus.efi --progress-bar
echo copying HFSPlus.efi to $EFI/EFI/CLOVER/drivers64UEFI
cp ./HFSPlus.efi $EFI/EFI/CLOVER/drivers64UEFI


# Copy config_install.plist from the repo to Clover folder
echo copying config.plist to $EFI/EFI/CLOVER/config.plist
cp config.plist $EFI/EFI/CLOVER/config.plist

# Remove HDA and HDMI patches from config.plist/Devices/Arbitrary; they might cause troubless
echo removing HDA patch from config.plist/Devices/Arbitrary
/usr/libexec/plistbuddy -c "Delete ':Devices:Arbitrary:1'" $config
echo removing HDMI patch from config.plist/Devices/Arbitrary
/usr/libexec/plistbuddy -c "Delete ':Devices:Arbitrary:1'" $config

echo Done.
