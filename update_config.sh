#!/bin/bash

EFI=$(./mount_efi.sh /)
config=$EFI/EFI/Clover/config.plist

function replaceVar() {
    value=$(/usr/libexec/plistbuddy -c "Print '$1'" config.plist)
    /usr/libexec/plistbuddy -c "Set '$1' '$value'" $config
}

function replaceDict() {
    /usr/libexec/plistbuddy -x -c "Print '$1'" config.plist > /tmp/org_rehabman_node.plist
    /usr/libexec/plistbuddy -c "Delete '$1'" $config
    /usr/libexec/plistbuddy -c "Add '$1' dict" $config
    /usr/libexec/plistbuddy -c "Merge /tmp/org_rehabman_node.plist '$1'" $config
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

echo The config.plist at $config will be updated.

replaceDict ":ACPI"
replaceDict ":Boot"
replaceDict ":Devices"
replaceDict ":KernelAndKextPatches"
replaceDict ":SystemParameters"
replaceVar ":RtVariables:BooterConfig"
replaceVar ":RtVariables:CsrActiveConfig"
