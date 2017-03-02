#!/bin/bash

EFI=`sudo ./mount_efi.sh`
config=$EFI/EFI/CLOVER/config.plist

function inject_edid
{
# $1 is the EDID string
    comment=`/usr/libexec/PlistBuddy -c "Print :Graphics:CustomEDID" $config 2>&1`
    if [[ "$comment" == *"Does Not Exist"* ]]; then
        /usr/libexec/PlistBuddy -c "Add ':Graphics:CustomEDID' String" $config
    fi
    /usr/libexec/PlistBuddy -c "Set ':Graphics:CustomEDID' \"$1\"" $config

    comment=`/usr/libexec/PlistBuddy -c "Print :Graphics:InjectEDID" $config 2>&1`
    if [[ "$comment" == *"Does Not Exist"* ]]; then
        /usr/libexec/PlistBuddy -c "Add ':Graphics:InjectEDID' Bool" $config
    fi
    /usr/libexec/PlistBuddy -c "Set ':Graphics:InjectEDID' true" $config
}

Byte1RepValue=1d; Byte1RepValueWhithPrefix=0x$Byte1RepValue
Byte2RepValue=10; Byte2RepValueWhithPrefix=0x$Byte2RepValue

# Extract display parameters to a plist.
ioreg -n AppleBacklightDisplay -arxw0 > /tmp/org.the-braveknight.display.plist

# Define EDID arrays
NativeEDID=(`/usr/libexec/PlistBuddy -c "Print ':0:IODisplayEDID'" /tmp/org.the-braveknight.display.plist|xxd -i`)
PatchedEDID=()

for ((i=0; i < 127; i++)); do
    HexElement=${NativeEDID[$i]}
    HexByte=`echo $HexElement|sed 's/0x\([^,]*\),/\1/'`
    PatchedEDID[$i]=$HexByte
done

Byte1OrigValueWhithPrefix=`echo "${NativeEDID[21]}"|sed 's/,//'`
Byte2OrigValueWhithPrefix=`echo "${NativeEDID[22]}"|sed 's/,//'`
ChecksumOrigValueWhithPrefix=`echo "${NativeEDID[127]}"|sed 's/,//'`

# Replace original bytes with the new values
PatchedEDID[21]=$Byte1RepValue
PatchedEDID[22]=$Byte2RepValue

# Calculate byte #3 (checksum) replacement value
for ((i=0; i < 127; i++)); do
    HexByte=${PatchedEDID[$i]}
    sum=$(($sum+0x$HexByte))
done
ChecksumRepValue=`printf "%02x\n" $(( 256 -  (($sum) % 256) ))`; ChecksumRepValueWhithPrefix=0x$ChecksumRepValue

# Patch checksum
PatchedEDID[127]=$ChecksumRepValue


echo Patched Byte "#1": "$Byte1OrigValueWhithPrefix -> $Byte1RepValueWhithPrefix"
echo Patched Byte "#2": "$Byte2OrigValueWhithPrefix -> $Byte2RepValueWhithPrefix"
echo Patched Checksum Byte: "$ChecksumOrigValueWhithPrefix -> $ChecksumRepValueWhithPrefix"

# Print the new/patched EDID
echo Patched EDID: "<${PatchedEDID[@]}>"

# Construct an EDID string for config.plist
EDIDString=`echo ${PatchedEDID[@]}|sed 's/ //g'`

# Copy EDID string to config.plist
inject_edid "$EDIDString"

