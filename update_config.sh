#!/bin/bash

#set -x

EFI=`sudo ./mount_efi.sh /`
CONFIG=$EFI/EFI/Clover/config.plist

function replace_var()
# $1 is path to replace
{
    value=`/usr/libexec/plistbuddy -c "Print \"$1\"" $CONFIG`
    /usr/libexec/plistbuddy -c "Set \"$1\" \"$value\"" $CONFIG
}

function replace_dict()
# $1 is path to replace
{
    /usr/libexec/plistbuddy -x -c "Print \"$1\"" config.plist >/tmp/org_rehabman_node.plist
    /usr/libexec/plistbuddy -c "Delete \"$1\"" $CONFIG
    /usr/libexec/plistbuddy -c "Add \"$1\" dict" $CONFIG
    /usr/libexec/plistbuddy -c "Merge /tmp/org_rehabman_node.plist \"$1\"" $CONFIG
}

# existing config.plist, preserve:
#   CPU
#   DisableDrivers
#   GUI
#   RtVariables, except CsrActiveConfig and BooterConfig
#   SMBIOS
#
# replaced are:
#   ACPI
#   Boot
#   Devices
#   KernelAndKextPatches
#   SystemParameters
#   RtVariables:BooterConfig
#   RtVariables:CsrActiveConfig

echo The config.plist at $CONFIG will be updated.

replace_dict ":ACPI"
replace_dict ":Boot"
replace_dict ":Devices"
replace_dict ":KernelAndKextPatches"
replace_dict ":SystemParameters"
replace_var ":RtVariables:BooterConfig"
replace_var ":RtVariables:CsrActiveConfig"
