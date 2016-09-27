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
        echo Installing $1 to $KEXTDEST
        rm -Rf $KEXTDEST/`basename $1`
        cp -Rf $1 $KEXTDEST
    fi
}

if [ ! -e $AKEXTSDIR ]; then
    echo "No kexts found in $AKEXTSDIR, please run download.sh & install_downloads.sh scripts."
    exit
fi


# Compile SSDT-Install.dsl, copy AML to CLOVER/ACPI/patched
echo Compiling SSDT-Install.dsl, copying to $CLOVER/ACPI/patched
iasl -ve -p $BUILDDIR/SSDT-Install.aml SSDT-Install.dsl
cp $BUILDDIR/SSDT-Install.aml $CLOVER/ACPI/patched


# Install kexts in ./kexts folder
cd $KEXTSDIR
install_kext USBXHC_*.kext
install_kext ApplePS2SmartTouchPad.kext
cd ..


# Install kexts downloaded by download.sh script
cd $AKEXTSDIR
cd RehabMan-FakeSMC* && install_kext FakeSMC.kext && cd ..
cd RehabMan-Realtek-Network-v2*/Release && install_kext RealtekRTL8111.kext && cd ..//..
cd ..//..


# Download & copy HFSPlus.efi from CloverGrowerPro repo to CLOVER/drivers64UEFI
echo Downloading HFSPlus.efi...
curl https://raw.githubusercontent.com/JrCs/CloverGrowerPro/master/Files/HFSPlus/X64/HFSPlus.efi -o HFSPlus.efi -s
echo Copying HFSPlus.efi to $CLOVER/drivers64UEFI
cp ./HFSPlus.efi $CLOVER/drivers64UEFI


# Copy config_install.plist from the repo to Clover folder
echo Copying config.plist to $CLOVER
cp config.plist $CLOVER


# Cleanup config.plist

echo Cleaning up config.plist
$PlistBuddy -c "Delete ':Devices'" $CONFIG
$PlistBuddy -c "Delete ':Graphics'" $CONFIG
$PlistBuddy -c "Delete ':ACPI'" $CONFIG
$PlistBuddy -c "Delete ':KernelAndKextPatches:KextsToPatch'" $CONFIG

echo Merging config-install.plist with config.plist
$PlistBuddy -c "Merge 'config-install.plist'" $CONFIG


# Copy smbios.plist from EFI/CLOVER (if present).
diskutil unmount $EFI
HDEFI=`$SUDO ./mount_efi.sh /`
if [ -e $HDEFI/EFI/CLOVER/smbios.plist ]; then
    cp $HDEFI/EFI/CLOVER/smbios.plist /tmp/smbios.plist
    diskutil unmount $HDEFI
    $SUDO ./mount_efi.sh /dev/disk1
    cp /tmp/smbios.plist $CLOVER
else
    diskutil unmount $HDEFI
    $SUDO ./mount_efi.sh /dev/disk1
fi

echo Done.
