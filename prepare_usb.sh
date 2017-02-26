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

KextsToInstall=(FakeSMC.kext RealtekRTL8111.kext FakePCIID.kext FakePCIID_Broadcom_WiFi.kext FakePCIID_Intel_HD_Graphics.kext USBInjectAll.kext)
SSDTsToInstall=(SSDT-USB.dsl SSDT-UIAC.dsl SSDT-NVDA.dsl)
EFINeededDrivers=(OsxAptioFixDrv-64.efi FSInject-64.efi OsxFatBinaryDrv-64.efi HFSPlus.efi)

function install_kext
{
    if [ "$1" != "" ]; then
        echo Installing `basename $1` to $KEXTDEST
        rm -Rf $KEXTDEST/`basename $1`
        cp -Rf $1 $KEXTDEST
    fi
}

function copy
{
    if [ "$1" != "" ] && [ "$2" != "" ]; then
        if [ -e $1 ] && [ -e $2 ]; then
            echo Copying `basename $1` to $2
            cp $1 $2
        fi
    fi
}

function clean_dir
{
    if [ "$1" != "" ]; then
        if [ -d $1 ]; then
            rm -Rf $1/*
        fi
    fi
}

function compile_dsl
{
    if [ "$1" != "" ]; then
        echo Compiling `basename $1`...
        iasl -ve -p $BUILDDIR/`basename $1 .dsl`.aml $1 > /dev/null
    fi
}

function download_file
{
    # $1: Remote link
    # $2: Folder
    echo Downloading `basename $1`...
    curl $1 -o $2/`basename $1` -s
}

function copy_smbios
{
    diskutil unmount $USBEFI > /dev/null
    HDEFI=`$SUDO ./mount_efi.sh /`
    if [ -e $HDEFI/EFI/CLOVER/smbios.plist ]; then
        cp $HDEFI/EFI/CLOVER/smbios.plist /tmp/smbios.plist
        diskutil unmount $HDEFI > /dev/null
        USBEFI=`$SUDO ./mount_efi.sh /dev/disk1`
        copy /tmp/smbios.plist $CLOVER
    else
        diskutil unmount $HDEFI > /dev/null
        USBEFI=`$SUDO ./mount_efi.sh /dev/disk1`
    fi
}

function unzip_all_indir
{
    if [ "$1" != "" ]; then
        if [ -d $1 ] && [ "`basename $1/*.zip`" != "*.zip" ]; then
            for ZIP in $1/*.zip; do
                unzip -q $ZIP -d $1/`basename $ZIP .zip`
            done
        fi
    fi
}

function install_kexts_indir
{
    if [ "$1" != "" ] && [ -d $1 ]; then
        for DownloadedKext in $1/*/*.kext $1/*/Release/*.kext; do
            for KextToInstall in ${KextsToInstall[@]}; do
                if [ "`basename $DownloadedKext`" == "$KextToInstall" ]; then
                    install_kext $DownloadedKext
                fi
            done
        done
    fi
}

# Copy config_install.plist from the repo to Clover folder
copy config.plist $CLOVER

# Cleanup config.plist
echo Cleaning up config.plist
/usr/libexec/PlistBuddy -c "Delete ':ACPI'" $CONFIG
/usr/libexec/PlistBuddy -c "Delete ':KernelAndKextPatches:KextsToPatch'" $CONFIG
/usr/libexec/PlistBuddy -c "Merge './install_usb/config-usb.plist'" $CONFIG

# Delete already existing files from CLOVER/ACPI/patched
clean_dir $CLOVER/ACPI/patched

# Delete files in ./build
clean_dir build

# Compile SSDTs
for DSL in ${SSDTsToInstall[@]}; do
    compile_dsl ./hotpatch/$DSL
done

# Install SSDTs
for AML in $BUILDDIR/*.aml; do
    copy $AML $CLOVER/ACPI/patched
done

# Download the required kexts for the installer
./download.sh --usb-kexts

unzip_all_indir ./downloads/kexts

# Remove Clover/kexts/* folders.
clean_dir $CLOVER/kexts
# Recreate 'Others' directory.
mkdir $KEXTDEST

# Install kexts
install_kexts_indir ./downloads/kexts

# Delete unneeded drivers
if [ ! -d /tmp/Clover ]; then mkdir /tmp/Clover; else clean_dir /tmp/Clover; fi
for EFINeededDriver in ${EFINeededDrivers[@]}; do
    cp $CLOVER/drivers64UEFI/$EFINeededDriver /tmp/Clover
done
clean_dir $CLOVER/drivers64UEFI && cp /tmp/Clover/*.efi $CLOVER/drivers64UEFI

# Special script arguments
for arg in $@; do
    if [ "$arg" == "--elan-kext" ]; then
        install_kext ./kexts/ApplePS2SmartTouchPad.kext
    fi

    if [ "$arg" == "--voodoo-kext" ]; then
        cd ./downloads/kexts/RehabMan-Voodoo-*
        install_kext ./Release/VoodooPS2Controller.kext
        cd ../../..
    fi

    if [ "$arg" == "--download-hfsplus" ]; then
        download_file https://raw.githubusercontent.com/JrCs/CloverGrowerPro/master/Files/HFSPlus/X64/HFSPlus.efi ./downloads
        copy ./downloads/HFSPlus.efi $CLOVER/drivers64UEFI
    fi

    if [ "$arg" == "--copy-smbios" ]; then
        copy_smbios
    fi
done

echo Done.
