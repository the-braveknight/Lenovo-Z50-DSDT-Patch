#!/bin/bash

# Script to install/update kexts in Clover/kexts/Other
# folder, also merges 10.x folders into 'Other' folder.

SUDO=sudo
EFIDIR=$($SUDO ./mount_efi.sh /)
KEXTDEST=$EFIDIR/EFI/CLOVER/kexts/Other
EXCEPTIONS="Sensors|FakePCIID_BCM57XX|FakePCIID_Intel_GbX|FakePCIID_Intel_HDMI|FakePCIID_XHCIMux|FakePCIID_AR9280_as_AR946x|BrcmPatchRAM|BrcmBluetoothInjector|BrcmFirmwareData|BrcmNonPatchRAM|USBInjectAll"
MINOR_VER=$([[ "$(sw_vers -productVersion)" =~ [0-9]+\.([0-9]+) ]] && echo ${BASH_REMATCH[1]})

function check_directory
{
    for x in $1; do
        if [ -e "$x" ]; then
            return 1
        else
            return 0
        fi
    done
}

function install_kext
{
    if [ "$1" != "" ]; then
        echo installing $1 to $KEXTDEST
        $SUDO rm -Rf $KEXTDEST/`basename $1`
        $SUDO cp -Rf $1 $KEXTDEST
    fi
}


function install
{
    installed=0
    out=${1/.zip/}
    rm -Rf $out/* && unzip -q -d $out $1
    check_directory $out/Release/*.kext
    if [ $? -ne 0 ]; then
        for kext in $out/Release/*.kext; do
            # install the kext when it exists regardless of filter
            kextname="`basename $kext`"
            if [[ -e "$SLE/$kextname" || -e "$KEXTDEST/$kextname" || "$2" == "" || "`echo $kextname | grep -vE "$2"`" != "" ]]; then
                install_kext $kext
            fi
        done
        installed=1
    fi
    check_directory $out/*.kext
    if [ $? -ne 0 ]; then
        for kext in $out/*.kext; do
            # install the kext when it exists regardless of filter
            kextname="`basename $kext`"
            if [[ -e "$SLE/$kextname" || -e "$KEXTDEST/$kextname" || "$2" == "" || "`echo $kextname | grep -vE "$2"`" != "" ]]; then
                install_kext $kext
            fi
        done
        installed=1
    fi
}

if [ "$(id -u)" != "0" ]; then
    echo "This script requires superuser access..."
fi


# Copy kexts in Clover/kexts/10.* folders to Clover/kexts/Other
# and delete Clover/kexts/10.* folders.
for each in $(find $EFIDIR/EFI/CLOVER/kexts/ -name "10.*" -type d); do
    for innerdir in $(find $each -name "*.kext" -type d); do
        cp -R $innerdir $KEXTDEST
    done
    rm -R $each
done

# unzip/install kexts
check_directory ./downloads/kexts/*.zip
if [ $? -ne 0 ]; then
    echo Installing kexts...
    cd ./downloads/kexts
    for kext in *.zip; do
        install $kext "$EXCEPTIONS"
    done
    if [[ $MINOR_VER -ge 11 ]]; then
        # 10.11 needs BrcmPatchRAM2.kext
        cd RehabMan-BrcmPatchRAM*/Release && install_kext BrcmPatchRAM2.kext && cd ../..
        cd RehabMan-BrcmPatchRAM*/Release && install_kext BrcmNonPatchRAM2.kext && cd ../..
        # 10.11 needs USBInjectAll.kext
        cd RehabMan-USBInjectAll*/Release && install_kext USBInjectAll.kext && cd ../..
        # remove BrcPatchRAM.kext just in case
        $SUDO rm -Rf $KEXTDEST/BrcmPatchRAM.kext
        # remove injector just in case
        $SUDO rm -Rf $KEXTDEST/BrcmBluetoothInjector.kext
    else
        # prior to 10.11, need BrcmPatchRAM.kext
        cd RehabMan-BrcmPatchRAM*/Release && install_kext BrcmPatchRAM.kext && cd ../..
        cd RehabMan-BrcmPatchRAM*/Release && install_kext BrcmNonPatchRAM.kext && cd ../..
        # remove BrcPatchRAM2.kext just in case
        $SUDO rm -Rf $KEXTDEST/BrcmPatchRAM2.kext
        # remove injector just in case
        $SUDO rm -Rf $KEXTDEST/BrcmBluetoothInjector.kext
    fi
    # this guide does not use BrcmFirmwareData.kext
    $SUDO rm -Rf $KEXTDEST/BrcmFirmwareData.kext
    # now using IntelBacklight.kext instead of ACPIBacklight.kext
    $SUDO rm -Rf $KEXTDEST/ACPIBacklight.kext
    # since EHCI #1 is disabled, FakePCIID_XHCIMux.kext cannot be used
    $SUDO rm -Rf $KEXTDEST/FakePCIID_XHCIMux.kext
    # deal with some renames
    if [[ -e $KEXTDEST/FakePCIID_Broadcom_WiFi.kext ]]; then
        # remove old FakePCIID_BCM94352Z_as_BCM94360CS2.kext
        $SUDO rm -Rf $KEXTDEST/FakePCIID_BCM94352Z_as_BCM94360CS2.kext
    fi
    if [[ -e $KEXTDEST/FakePCIID_Intel_HD_Graphics.kext ]]; then
        # remove old FakePCIID_HD4600_HD4400.kext
        $SUDO rm -Rf $KEXTDEST/FakePCIID_HD4600_HD4400.kext
    fi
    cd ../..
fi

# install ApplePS2SmartTouchPad.kext by EMlyDinEsH from OSXLatitude.com
install_kext ApplePS2SmartTouchPad.kext

# Copy custom firmware to BrcmFirmwareRepo.kext to make it
# able to be injected.
#
# Note: DW1560 BCM94352Z WiFi/BT firmware is injected.
plist=$KEXTDEST/BrcmFirmwareRepo.kext/Contents/Info.plist
/usr/libexec/plistbuddy -c "Merge ./BluetoothFirmware/bt_dev_id.plist ':IOKitPersonalities'" $plist
/usr/libexec/plistbuddy -c "Merge ./BluetoothFirmware/bt_firmware.plist ':IOKitPersonalities:BrcmFirmwareStore'" $plist
rm -R $KEXTDEST/BrcmFirmwareRepo.kext/Contents/Resources

