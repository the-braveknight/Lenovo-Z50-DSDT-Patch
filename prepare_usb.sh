#!/bin/bash

# Written by the-braveknight, based on RehabMan's scripts.

# Note: this script requires 'make', download.sh & install_downloads.sh
# scripts to have been run & Clover to have been installed prior to running it.

# Note: this script assumes the USB drive is 'disk1' (/dev/disk1) that is
# partitioned in GPT.

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
echo copying $BUILDDIR/SSDT-HACK.aml to $EFI/EFI/CLOVER/ACPI/patched
cp $BUILDDIR/SSDT-HACK.aml $EFI/EFI/CLOVER/ACPI/patched


# Download & copy HFSPlus.efi from CloverGrowerPro repo to CLOVER/drivers64UEFI
echo downloading HFSPlus.efi
curl https://raw.githubusercontent.com/JrCs/CloverGrowerPro/master/Files/HFSPlus/X64/HFSPlus.efi -o HFSPlus.efi --progress-bar
echo copying HFSPlus.efi to $EFI/EFI/CLOVER/drivers64UEFI
cp ./HFSPlus.efi $EFI/EFI/CLOVER/drivers64UEFI


# Copy config_install.plist from the repo to Clover folder
echo copying config.plist to $EFI/EFI/CLOVER/config.plist
cp config.plist $EFI/EFI/CLOVER/config.plist

# Remove unnecessary patches from config.plist
PlistBuddy=/usr/libexec/plistbuddy

echo removing HDA patches from config.plist
$PlistBuddy -c "Delete ':Devices:Arbitrary:1'" $config
$PlistBuddy -c "Delete ':KernelAndKextPatches:KextsToPatch:3'" $config
$PlistBuddy -c "Delete ':KernelAndKextPatches:KextsToPatch:1'" $config

echo removing HDMI patches from config.plist
$PlistBuddy -c "Delete ':Devices:Arbitrary:1'" $config
$PlistBuddy -c "Delete ':KernelAndKextPatches:KextsToPatch:0'" $config

echo removing WiFi/BT patches from config.plist
$PlistBuddy -c "Delete ':KernelAndKextPatches:KextsToPatch:0'" $config
$PlistBuddy -c "Delete ':KernelAndKextPatches:KextsToPatch:6'" $config
$PlistBuddy -c "Delete ':KernelAndKextPatches:KextsToPatch:5'" $config
$PlistBuddy -c "Delete ':KernelAndKextPatches:KextsToPatch:4'" $config



# Copying smbios.plist from EFI/CLOVER (if exists).
diskutil unmount $EFI
HDEFI=`$SUDO ./mount_efi.sh /`
if [ -e $HDEFI/EFI/CLOVER/smbios.plist ]; then
    echo smbios.plist exists, copying to $EFI/EFI/CLOVER
    cp $HDEFI/EFI/CLOVER/smbios.plist /tmp/smbios.plist
    diskutil unmount $HDEFI
    EFI=`$SUDO ./mount_efi.sh /dev/disk1`
    cp /tmp/smbios.plist $EFI/EFI/CLOVER
else
    diskutil unmount $HDEFI
    EFI=`$SUDO ./mount_efi.sh /dev/disk1`
fi

echo Done.
