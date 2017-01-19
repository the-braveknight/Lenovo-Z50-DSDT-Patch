#!/bin/bash

# Written by the-braveknight, based on RehabMan's scripts.

# Note: this assumes Clover has already been installed to  the USB
# drive which is 'disk1' (/dev/disk1) that is partitioned in GPT.

SUDO=sudo
USBEFI=`$SUDO ./mount_efi.sh /dev/disk1`
CLOVER=$USBEFI/EFI/CLOVER
KEXTDEST=$CLOVER/kexts/Other
CONFIG=$CLOVER/config.plist
BUILDDIR=./build
PlistBuddy=/usr/libexec/plistbuddy
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


# Copy config_install.plist from the repo to Clover folder
echo Copying config.plist to $CLOVER
cp ./config.plist $CLOVER

# Cleanup config.plist
echo Cleaning up config.plist
$PlistBuddy -c "Delete ':ACPI'" $CONFIG
$PlistBuddy -c "Delete ':KernelAndKextPatches:KextsToPatch'" $CONFIG
$PlistBuddy -c "Merge './install_usb/config-usb.plist'" $CONFIG


# Delete already existing files from CLOVER/ACPI/patched
rm -f $CLOVER/ACPI/patched/*

# Compile SSDT-USB.dsl & SSDT-NVDA.dsl, copy AML to CLOVER/ACPI/patched
echo "Compiling the SSDTs required for the installer..."
iasl -ve -p $BUILDDIR/SSDT-USB.aml ./hotpatch/SSDT-USB.dsl
iasl -ve -p $BUILDDIR/SSDT-UIAC.aml ./hotpatch/SSDT-UIAC.dsl
iasl -ve -p $BUILDDIR/SSDT-NVDA.aml ./hotpatch/SSDT-NVDA.dsl
echo "copying the required SSDTs to $CLOVER/ACPI/patched"
cp $BUILDDIR/SSDT-USB.aml $CLOVER/ACPI/patched
cp $BUILDDIR/SSDT-UIAC.aml $CLOVER/ACPI/patched
cp $BUILDDIR/SSDT-NVDA.aml $CLOVER/ACPI/patched


# Download & copy HFSPlus.efi from CloverGrowerPro repo to CLOVER/drivers64UEFI if it's not present
if [ ! -e $CLOVER/drivers64UEFI/HFSPlus.efi ]; then
    echo Downloading HFSPlus.efi...
    curl https://raw.githubusercontent.com/JrCs/CloverGrowerPro/master/Files/HFSPlus/X64/HFSPlus.efi -o ./downloads/HFSPlus.efi -s
    echo Copying HFSPlus.efi to $CLOVER/drivers64UEFI
    cp ./downloads/HFSPlus.efi $CLOVER/drivers64UEFI
fi


# Remove Clover/kexts/10.* folders, keep 'Others' only.
rm -Rf $CLOVER/kexts/10.*
# Remove any kext(s) already present in 'Others' folder.
rm -Rf $KEXTDEST/*.kext

# Download the required kexts for the installer
./download.sh --usb-kexts

# Extract & install downloaded kexts
cd ./downloads/kexts

for ZIP in *.zip; do
    unzip -q $ZIP -d `basename $ZIP .zip`
done

install_kext RehabMan-FakeSMC-*/FakeSMC.kext
install_kext RehabMan-Realtek-Network-v2-*/Release/RealtekRTL8111.kext
install_kext RehabMan-FakePCIID-*/Release/FakePCIID.kext
install_kext RehabMan-FakePCIID-*/Release/FakePCIID_Broadcom_WiFi.kext
install_kext RehabMan-FakePCIID-*/Release/FakePCIID_Intel_HD_Graphics.kext
install_kext RehabMan-USBInjectAll-*/Release/USBInjectAll.kexts
cd ../..

# Install ApplePS2SmartTouchPad.kext
install_kext ./kexts/ApplePS2SmartTouchPad.kext

# Copy smbios.plist from EFI/CLOVER (if present).
diskutil unmount $USBEFI
HDEFI=`$SUDO ./mount_efi.sh /`
if [ -e $HDEFI/EFI/CLOVER/smbios.plist ]; then
    cp $HDEFI/EFI/CLOVER/smbios.plist /tmp/smbios.plist
    diskutil unmount $HDEFI
    USBEFI=`$SUDO ./mount_efi.sh /dev/disk1`
    cp /tmp/smbios.plist $CLOVER
else
    diskutil unmount $HDEFI
    USBEFI=`$SUDO ./mount_efi.sh /dev/disk1`
fi

echo Done.
