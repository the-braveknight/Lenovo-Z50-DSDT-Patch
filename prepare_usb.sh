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

function install_kext
{
    if [ "$1" != "" ]; then
        echo Installing $1 to $KEXTDEST
        rm -Rf $KEXTDEST/`basename $1`
        cp -Rf $1 $KEXTDEST
    fi
}


# Download required kexts
./download.sh usb_kexts


# Remove Clover/kexts/10.* folders, keep 'Others' only.
rm -Rf $CLOVER/kexts/10.*
# Remove any kext(s) already present in 'Others' folder.
rm -Rf $KEXTDEST/*.kext


# Extract & install downloaded kexts
cd ./downloads/kexts
mkdir RehabMan-FakeSMC-USB && unzip -q RehabMan-FakeSMC-*.zip -d RehabMan-FakeSMC-USB
mkdir RehabMan-Realtek-Network-v2-USB && unzip -q RehabMan-Realtek-Network-v2-*.zip -d RehabMan-Realtek-Network-v2-USB
cd RehabMan-FakeSMC-USB && install_kext FakeSMC.kext && cd ..
cd RehabMan-Realtek-Network-v2-USB/Release && install_kext RealtekRTL8111.kext && cd ..//..
cd ..//..

# Install local kexts
cd ./kexts
install_kext USBXHC_*.kext
install_kext ApplePS2SmartTouchPad.kext
if [ "$1" != "native_wifi" ]; then
    install_kext AirPortInjector.kext
fi
cd ..


# Compile SSDT-Install.dsl, copy AML to CLOVER/ACPI/patched
echo Compiling SSDT-Install.dsl
iasl -ve -p $BUILDDIR/SSDT-Install.aml SSDT-Install.dsl
echo copying $BUILDDIR/SSDT-Install.aml to $CLOVER/ACPI/patched
cp $BUILDDIR/SSDT-Install.aml $CLOVER/ACPI/patched


# Download & copy HFSPlus.efi from CloverGrowerPro repo to CLOVER/drivers64UEFI if it's not present
if [ ! -e $CLOVER/drivers64UEFI/HFSPlus.efi ]; then
    echo Downloading HFSPlus.efi...
    curl https://raw.githubusercontent.com/JrCs/CloverGrowerPro/master/Files/HFSPlus/X64/HFSPlus.efi -o ./downloads/HFSPlus.efi -s
    echo Copying HFSPlus.efi to $CLOVER/drivers64UEFI
    cp ./downloads/HFSPlus.efi $CLOVER/drivers64UEFI
fi

# Copy config_install.plist from the repo to Clover folder
echo Copying config.plist to $CLOVER
cp config.plist $CLOVER


# Cleanup config.plist

echo Cleaning up config.plist
$PlistBuddy -c "Delete ':Devices'" $CONFIG
$PlistBuddy -c "Delete ':Graphics'" $CONFIG
$PlistBuddy -c "Delete ':ACPI'" $CONFIG
$PlistBuddy -c "Delete ':KernelAndKextPatches:KextsToPatch'" $CONFIG
$PlistBuddy -c "Merge 'config-install.plist'" $CONFIG


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
