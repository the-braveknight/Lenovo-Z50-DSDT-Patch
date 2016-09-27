#!/bin/bash

# Written by the-braveknight, based on RehabMan's scripts.

# Note: this script requires download.sh & install_downloads.sh scripts
# to have been run & assumes Clover has already been installed to
# the USB drive which is 'disk1' (/dev/disk1) that is partitioned in GPT.

SUDO=sudo
EFI=`$SUDO ./mount_efi.sh /dev/disk1`
CLOVER=$EFI/EFI/CLOVER
KEXTDEST=$CLOVER/kexts/Other
KEXTSDIR=./kexts
AKEXTSDIR=./downloads/kexts
CONFIG=$CLOVER/config.plist
BUILDDIR=./build
PlistBuddy=/usr/libexec/plistbuddy

function install_kext
{
    if [ "$1" != "" ]; then
        echo installing $1 to $KEXTDEST
        $SUDO rm -Rf $KEXTDEST/`basename $1`
        $SUDO cp -Rf $1 $KEXTDEST
    fi
}

if [ ! -e $AKEXTSDIR ]; then
    echo "no kexts found in $AKEXTSDIR, please run download.sh & install_downloads.sh scripts."
    exit
fi


if [ ! -e $BUILDDIR/SSDT-HACK.aml ]; then
    echo "no SSDT-HACK.aml found in $BUILDDIR, compiling SSDT-HACK.dsl..."
    iasl -ve -p ./build/SSDT-HACK.aml SSDT-HACK.dsl
fi

# Install kexts in the repo
cd $KEXTSDIR
install_kext USBXHC_z50.kext
install_kext ApplePS2SmartTouchPad.kext
cd ..


# Install kexts downloaded by download.sh script
cd $AKEXTSDIR
cd RehabMan-FakeSMC* && install_kext FakeSMC.kext && cd ..
cd RehabMan-Realtek-Network-v2*/Release && install_kext RealtekRTL8111.kext && cd ..//..
cd RehabMan-Battery*/Release && install_kext ACPIBatteryManager.kext && cd ..//..
cd ..//..


# Copy SSDT-HACK.aml from ./build to CLOVER/ACPI/patched
echo copying $BUILDDIR/SSDT-HACK.aml to $CLOVER/ACPI/patched
cp $BUILDDIR/SSDT-HACK.aml $CLOVER/ACPI/patched



# Download & copy HFSPlus.efi from CloverGrowerPro repo to CLOVER/drivers64UEFI
echo downloading HFSPlus.efi
curl https://raw.githubusercontent.com/JrCs/CloverGrowerPro/master/Files/HFSPlus/X64/HFSPlus.efi -o HFSPlus.efi --progress-bar
echo copying HFSPlus.efi to $CLOVER/drivers64UEFI
cp ./HFSPlus.efi $CLOVER/drivers64UEFI


# Copy config_install.plist from the repo to Clover folder
echo copying config.plist to $CLOVER
cp config.plist $CLOVER


# Remove unnecessary patches from Clover/config.plist

echo removing HDA patches from $CONFIG
$PlistBuddy -c "Delete ':Devices:Arbitrary:1'" $CONFIG
$PlistBuddy -c "Delete ':KernelAndKextPatches:KextsToPatch:3'" $CONFIG
$PlistBuddy -c "Delete ':KernelAndKextPatches:KextsToPatch:1'" $CONFIG

echo removing HDMI patches from $CONFIG
$PlistBuddy -c "Delete ':Devices:Arbitrary:1'" $CONFIG
$PlistBuddy -c "Delete ':KernelAndKextPatches:KextsToPatch:0'" $CONFIG

echo removing WiFi/BT patches from $CONFIG
$PlistBuddy -c "Delete ':KernelAndKextPatches:KextsToPatch:0'" $CONFIG
$PlistBuddy -c "Delete ':KernelAndKextPatches:KextsToPatch:6'" $CONFIG
$PlistBuddy -c "Delete ':KernelAndKextPatches:KextsToPatch:5'" $CONFIG
$PlistBuddy -c "Delete ':KernelAndKextPatches:KextsToPatch:4'" $CONFIG



# Copying smbios.plist from EFI/CLOVER (if exists).
diskutil unmount $EFI
HDEFI=`$SUDO ./mount_efi.sh /`
if [ -e $HDEFI/EFI/CLOVER/smbios.plist ]; then
    echo smbios.plist exists, copying to $CLOVER
    cp $HDEFI/EFI/CLOVER/smbios.plist /tmp/smbios.plist
    diskutil unmount $HDEFI
    EFI=`$SUDO ./mount_efi.sh /dev/disk1`
    cp /tmp/smbios.plist $CLOVER
else
    diskutil unmount $HDEFI
    EFI=`$SUDO ./mount_efi.sh /dev/disk1`
fi

echo Done.
