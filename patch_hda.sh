#!/bin/bash

# Originally written by RehabMan, reworked/simplified by the-braveknight.

function fixVersion() {
    oldValue=$(/usr/libexec/PlistBuddy -c "Print $1" $2)
    newValue=$(echo $oldValue | perl -p -e 's/(\d*\.\d*(\.\d*)?)/9\1/')
    /usr/libexec/PlistBuddy -c "Set $1 '$newValue'" $2
}

# Create AppleHDA PathMaps/Layouts injector kext
function createAppleHDAInjector() {
    native=/System/Library/Extensions/AppleHDA.kext
    injector=AppleHDA_$1.kext

    echo "Creating $injector"

    rm -Rf $injector && mkdir $injector && mkdir $injector/Contents && mkdir $injector/Contents/Resources && mkdir $injector/Contents/MacOS
    cp $native/Contents/Info.plist $injector/Contents/Info.plist
    ln -s $native/Contents/MacOS/AppleHDA $injector/Contents/MacOS/AppleHDA

    for layout in Resources_$1/layout*.plist; do
        ./tools/zlib deflate $layout > $injector/Contents/Resources/$(basename $layout .plist).xml.zlib
    done

    ./tools/zlib inflate $native/Contents/Resources/Platforms.xml.zlib > /tmp/Platforms.plist
    /usr/libexec/PlistBuddy -c "Delete ':PathMaps'" /tmp/Platforms.plist
    /usr/libexec/PlistBuddy -c "Merge Resources_$1/Platforms.plist" /tmp/Platforms.plist
    ./tools/zlib deflate /tmp/Platforms.plist > $injector/Contents/Resources/Platforms.xml.zlib

    fixVersion ":NSHumanReadableCopyright" $injector/Contents/Info.plist
    fixVersion ":CFBundleVersion" $injector/Contents/Info.plist
    fixVersion ":CFBundleGetInfoString" $injector/Contents/Info.plist
    fixVersion ":CFBundleShortVersionString" $injector/Contents/Info.plist
}

# Create AppleHDAHCD PinConfigs injector kext
function createAppleHDAHCDInjector() {
    native=/System/Library/Extensions/AppleHDA.kext/Contents/PlugIns/AppleHDAHardwareConfigDriver.kext

    # If AppleHDA PathMaps/Layouts injector kext exists, include AppleHDAHCD injector in its PlugIns
    if [ -d AppleHDA_$1.kext/Contents ]; then
        if [ ! -d AppleHDA_$1.kext/Contents/PlugIns ]; then
            mkdir AppleHDA_$1.kext/Contents/PlugIns
        fi
        injector=AppleHDA_$1.kext/Contents/PlugIns/AppleHDAHCD_$1.kext
    else
        injector=AppleHDAHCD_$1.kext
    fi

    echo "Creating $injector"

    rm -Rf $injector && mkdir $injector && mkdir $injector/Contents
    cp $native/Contents/Info.plist $injector/Contents/Info.plist

    fixVersion ":NSHumanReadableCopyright" $injector/Contents/Info.plist
    fixVersion ":CFBundleVersion" $injector/Contents/Info.plist
    fixVersion ":CFBundleGetInfoString" $injector/Contents/Info.plist
    fixVersion ":CFBundleShortVersionString" $injector/Contents/Info.plist

    /usr/libexec/PlistBuddy -c "Delete ':BuildMachineOSBuild'" $injector/Contents/Info.plist
    /usr/libexec/PlistBuddy -c "Delete ':DTCompiler'" $injector/Contents/Info.plist
    /usr/libexec/PlistBuddy -c "Delete ':DTPlatformBuild'" $injector/Contents/Info.plist
    /usr/libexec/PlistBuddy -c "Delete ':DTPlatformVersion'" $injector/Contents/Info.plist
    /usr/libexec/PlistBuddy -c "Delete ':DTSDKBuild'" $injector/Contents/Info.plist
    /usr/libexec/PlistBuddy -c "Delete ':DTSDKName'" $injector/Contents/Info.plist
    /usr/libexec/PlistBuddy -c "Delete ':DTXcode'" $injector/Contents/Info.plist
    /usr/libexec/PlistBuddy -c "Delete ':DTXcodeBuild'" $injector/Contents/Info.plist
    /usr/libexec/PlistBuddy -c "Delete ':OSBundleLibraries'" $injector/Contents/Info.plist
    /usr/libexec/PlistBuddy -c "Delete ':CFBundleExecutable'" $injector/Contents/Info.plist

    /usr/libexec/PlistBuddy -c "Set ':CFBundleIdentifier' 'org.the-braveknight.AppleHDAHCDInjector'" $injector/Contents/Info.plist
    /usr/libexec/PlistBuddy -c "Set ':CFBundleName' 'AppleHDAHCDInjector'" $injector/Contents/Info.plist
    /usr/libexec/PlistBuddy -c "Delete ':IOKitPersonalities:HDA Hardware Config Resource:PostConstructionInitialization'" $injector/Contents/Info.plist
    /usr/libexec/PlistBuddy -c "Delete ':IOKitPersonalities:HDA Hardware Config Resource:HDAConfigDefault'" $injector/Contents/Info.plist
    /usr/libexec/PlistBuddy -c "Merge ./Resources_$1/ahhcd.plist ':IOKitPersonalities:HDA Hardware Config Resource'" $injector/Contents/Info.plist
    /usr/libexec/PlistBuddy -c "Add ':IOKitPersonalities:HDA Hardware Config Resource:IOProbeScore' integer" $injector/Contents/Info.plist
    /usr/libexec/PlistBuddy -c "Set ':IOKitPersonalities:HDA Hardware Config Resource:IOProbeScore' 2000" $injector/Contents/Info.plist
}

if [ "$1" == "" ]; then
    echo Usage: patch_hda.sh {codec}
    echo Example: patch_hda.sh CX20751
    exit 1
fi

rm -Rf AppleHDA_$1.kext && rm -Rf AppleHDAHCD_$1.kext

createAppleHDAInjector "$1"
#createAppleHDAHCDInjector "$1"

