#!/bin/bash

# Extract display parameters to a plist.
ioreg -n AppleBacklightDisplay -arxw0 > /tmp/org.the-braveknight.display.plist

RepByte1=0x1d
RepByte2=0x10

# Define EDID array
NativeEDID=(`/usr/libexec/PlistBuddy -c "Print ':0:IODisplayEDID'" /tmp/org.the-braveknight.display.plist|xxd -i`)

function patch_edid
{
    for ((i=0; i < 127; i++)); do
        HexByte=${NativeEDID[$i]/,/}
        if [ $i == 21 ]; then
            PatchedEDID[$i]=${RepByte1/0x/}
            Sum=$(($Sum+$RepByte1))
        elif [ $i == 22 ]; then
            PatchedEDID[$i]=${RepByte2/0x/}
            Sum=$(($Sum+$RepByte2))
        else
            PatchedEDID[$i]=${HexByte/0x/}
            Sum=$(($Sum+$HexByte))
        fi
    done

    RepChksm=`printf "0x%02x\n" $(( 256 -  ($Sum % 256) ))`
    PatchedEDID[127]=${RepChksm/0x/}

    echo "Offset 0x16 patched: ($OrigByte1 -> $RepByte1)"
    echo "Offset 0x17 patched: ($OrigByte2 -> $RepByte2)"
    echo "Offset 0x80 patched: ($OrigChksm -> $RepChksm)"

    EDIDStr=`echo ${PatchedEDID[@]} | tr -d ' '`
}

function mount_efi
{
    EFI=`sudo ./mount_efi.sh`
    config=$EFI/EFI/CLOVER/config.plist
}

function inject_edid
{
# $1 is the EDID string
# $2 is the config.plist to patch
    comment=`/usr/libexec/PlistBuddy -c "Print :Graphics:CustomEDID" $2 2>&1`
    if [[ "$comment" == *"Does Not Exist"* ]]; then
        /usr/libexec/PlistBuddy -c "Add ':Graphics:CustomEDID' String" $2
    fi
    /usr/libexec/PlistBuddy -c "Set ':Graphics:CustomEDID' \"$1\"" $2

    comment=`/usr/libexec/PlistBuddy -c "Print :Graphics:InjectEDID" $2 2>&1`
    if [[ "$comment" == *"Does Not Exist"* ]]; then
        /usr/libexec/PlistBuddy -c "Add ':Graphics:InjectEDID' Bool" $2
    fi
    /usr/libexec/PlistBuddy -c "Set ':Graphics:InjectEDID' true" $2

    echo config.plist/Graphics/CustomEDID updated.
}


OrigByte1=${NativeEDID[21]/,/}
OrigByte2=${NativeEDID[22]/,/}
OrigChksm=${NativeEDID[127]/,/}

if [ $OrigByte1 == $RepByte1 ] && [ $OrigByte2 == $RepByte2 ]; then
    echo "EDID correct or already patched, aborting..."
else
    patch_edid
    mount_efi
    inject_edid $EDIDStr $config
fi
