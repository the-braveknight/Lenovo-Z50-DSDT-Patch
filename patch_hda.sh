#!/bin/bash

# Originally written by RehabMan, reworked/simplified by the-braveknight.

hda_native=/System/Library/Extensions/AppleHDA.kext
hcd_native=$hda_native/Contents/PlugIns/AppleHDAHardwareConfigDriver.kext

function fixVersion() {
    oldValue=$(/usr/libexec/PlistBuddy -c "Print $1" $2)
    newValue=$(echo $oldValue | perl -p -e 's/(\d*\.\d*(\.\d*)?)/9\1/')
    /usr/libexec/PlistBuddy -c "Set $1 '$newValue'" $2
}

# AppleHDAHCD PinConfigs injector kext
function createAppleHDAHCDInjector() {
    if [[ -d $2 ]]; then
        hcd_injector=$2/AppleHDAHCD_$1.kext
    else
        hcd_injector=AppleHDAHCD_$1.kext
    fi

    echo "Creating $hcd_injector"

    rm -Rf $hcd_injector && mkdir $hcd_injector && mkdir $hcd_injector/Contents
    cp $hcd_native/Contents/Info.plist $hcd_injector/Contents/Info.plist

    fixVersion ":NSHumanReadableCopyright" $hcd_injector/Contents/Info.plist
    fixVersion ":CFBundleVersion" $hcd_injector/Contents/Info.plist
    fixVersion ":CFBundleGetInfoString" $hcd_injector/Contents/Info.plist
    fixVersion ":CFBundleShortVersionString" $hcd_injector/Contents/Info.plist

    /usr/libexec/PlistBuddy -c "Delete ':BuildMachineOSBuild'" $hcd_injector/Contents/Info.plist
    /usr/libexec/PlistBuddy -c "Delete ':DTCompiler'" $hcd_injector/Contents/Info.plist
    /usr/libexec/PlistBuddy -c "Delete ':DTPlatformBuild'" $hcd_injector/Contents/Info.plist
    /usr/libexec/PlistBuddy -c "Delete ':DTPlatformVersion'" $hcd_injector/Contents/Info.plist
    /usr/libexec/PlistBuddy -c "Delete ':DTSDKBuild'" $hcd_injector/Contents/Info.plist
    /usr/libexec/PlistBuddy -c "Delete ':DTSDKName'" $hcd_injector/Contents/Info.plist
    /usr/libexec/PlistBuddy -c "Delete ':DTXcode'" $hcd_injector/Contents/Info.plist
    /usr/libexec/PlistBuddy -c "Delete ':DTXcodeBuild'" $hcd_injector/Contents/Info.plist
    /usr/libexec/PlistBuddy -c "Delete ':OSBundleLibraries'" $hcd_injector/Contents/Info.plist
    /usr/libexec/PlistBuddy -c "Delete ':CFBundleExecutable'" $hcd_injector/Contents/Info.plist

    /usr/libexec/PlistBuddy -c "Set ':CFBundleIdentifier' 'org.the-braveknight.AppleHDAHCDInjector'" $hcd_injector/Contents/Info.plist
    /usr/libexec/PlistBuddy -c "Set ':CFBundleName' 'AppleHDAHCDInjector'" $hcd_injector/Contents/Info.plist
    /usr/libexec/PlistBuddy -c "Delete ':IOKitPersonalities:HDA Hardware Config Resource:PostConstructionInitialization'" $hcd_injector/Contents/Info.plist
    /usr/libexec/PlistBuddy -c "Delete ':IOKitPersonalities:HDA Hardware Config Resource:HDAConfigDefault'" $hcd_injector/Contents/Info.plist
    /usr/libexec/PlistBuddy -c "Merge ./Resources_$1/ahhcd.plist ':IOKitPersonalities:HDA Hardware Config Resource'" $hcd_injector/Contents/Info.plist
    /usr/libexec/PlistBuddy -c "Add ':IOKitPersonalities:HDA Hardware Config Resource:IOProbeScore' integer" $hcd_injector/Contents/Info.plist
    /usr/libexec/PlistBuddy -c "Set ':IOKitPersonalities:HDA Hardware Config Resource:IOProbeScore' 2000" $hcd_injector/Contents/Info.plist
}

# Generate AppleHDA layouts/pathmaps resources
function createAppleHDAResources() {
    if [[ -d $2 ]]; then
        resources=$2
    else
        resources=AppleHDA_$1_Resources
    fi

    if [[ "$3" == *"-xml" ]]; then
        extension=xml
    else
        extension=zml
    fi

    rm -Rf $resources && mkdir $resources

    for layout in Resources_$1/layout*.plist; do
        ./tools/zlib deflate $layout > $resources/$(basename $layout .plist).$extension.zlib
    done

    ./tools/zlib inflate $hda_native/Contents/Resources/Platforms.xml.zlib > /tmp/Platforms.plist
    /usr/libexec/PlistBuddy -c "Delete ':PathMaps'" /tmp/Platforms.plist
    /usr/libexec/PlistBuddy -c "Merge Resources_$1/Platforms.plist" /tmp/Platforms.plist
    ./tools/zlib deflate /tmp/Platforms.plist > $resources/Platforms.$extension.zlib
}

# Create AppleHDA layouts/pathmaps injector kext
function createAppleHDALayoutsInjector() {
    if [[ -d $2 ]]; then
        hda_injector=$2/AppleHDA_$1.kext
    else
        hda_injector=AppleHDA_$1.kext
    fi

    echo "Creating $hda_injector"

    rm -Rf $hda_injector && mkdir $hda_injector && mkdir $hda_injector/Contents && mkdir $hda_injector/Contents/Resources && mkdir $hda_injector/Contents/MacOS
    cp $hda_native/Contents/Info.plist $hda_injector/Contents/Info.plist
    ln -s $hda_native/Contents/MacOS/AppleHDA $hda_injector/Contents/MacOS/AppleHDA

    createAppleHDAResources $1 $hda_injector/Contents/Resources -xml

    fixVersion ":NSHumanReadableCopyright" $hda_injector/Contents/Info.plist
    fixVersion ":CFBundleVersion" $hda_injector/Contents/Info.plist
    fixVersion ":CFBundleGetInfoString" $hda_injector/Contents/Info.plist
    fixVersion ":CFBundleShortVersionString" $hda_injector/Contents/Info.plist
}

# Create all-in-one AppleHDA injector kext
function createAppleHDAInjector() {
    hda_injector=AppleHDA_$1.kext
    createAppleHDALayoutsInjector "$1"
    mkdir $hda_injector/Contents/PlugIns
    createAppleHDAHCDInjector "$1" $hda_injector/Contents/PlugIns
}

if [ ! -d Resources_$1 ]; then
    echo Usage: patch_hda.sh {codec}
    echo Example: patch_hda.sh CX20751
    exit 1
fi

#createAppleHDAInjector "$1"
createAppleHDALayoutsInjector "$1"
#createAppleHDAHCDInjector "$1"
#createAppleHDAResources "$1"

