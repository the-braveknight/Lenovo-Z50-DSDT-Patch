#!/bin/bash

# Extract display parameters to a plist.
ioreg -n AppleBacklightDisplay -arxw0 > /tmp/org.the-braveknight.display.plist

# Define vendor/product-ids
RepVendId1=0x06; VendId1Index=$((0x08)) # Offset (0x08)
RepVendId2=0x10; VendId2Index=$((0x09)) # Offset (0x09)
RepProdId1=0xf2; ProdId1Index=$((0x0a)) # Offset (0x0a)
RepProdId2=0x9c; ProdId2Index=$((0x0b)) # Offset (0x0b)

# Define EDID array
NativeEDID=(`/usr/libexec/PlistBuddy -c "Print ':0:IODisplayEDID'" /tmp/org.the-braveknight.display.plist|xxd -i -l 128`)

function init_edid
{
    for ((i=0; i < 128; i++)); do
        Byte=${NativeEDID[$i]/,/}
        NativeEDID[$i]=$Byte
        PatchedEDID[$i]=$Byte
    done
}

function replace_byte
{
# $1 = Index (Offset)
# $2 = Value
    PatchedEDID[$1]=$2
    echo "Offset `printf \"0x%02x\n\" $1` patched: (${NativeEDID[$1]} -> $2)"
}

function patch_edid
{
    replace_byte $VendId1Index $RepVendId1
    replace_byte $VendId2Index $RepVendId2
    replace_byte $ProdId1Index $RepProdId1
    replace_byte $ProdId2Index $RepProdId2

    update_chksm

    prepare_edid
}

function update_chksm
{
    for ((i=0; i < 127; i++)); do
        Byte=${PatchedEDID[$i]}
        Sum=$(($Sum+$Byte))
    done

    RepChksm=`printf "0x%02x\n" $(( 256 - ($Sum % 256) ))`

    replace_byte $((0x7f)) $RepChksm
}

function prepare_edid
{
    for ((i=0; i < 128; i++)); do
        Byte=${PatchedEDID[$i]}
        PatchedEDID[$i]=${Byte/0x/}
    done
}

function inject_edid
{
    EFI=`sudo ./mount_efi.sh`
    config=$EFI/EFI/CLOVER/config.plist

    EDIDStr=`echo ${PatchedEDID[@]} | tr -d ' '`

    comment=`/usr/libexec/PlistBuddy -c "Print :Graphics:CustomEDID" $config 2>&1`
    if [[ "$comment" == *"Does Not Exist"* ]]; then
        /usr/libexec/PlistBuddy -c "Add ':Graphics:CustomEDID' String" $config
    fi
    /usr/libexec/PlistBuddy -c "Set ':Graphics:CustomEDID' '$EDIDStr'" $config

    comment=`/usr/libexec/PlistBuddy -c "Print :Graphics:InjectEDID" $config 2>&1`
    if [[ "$comment" == *"Does Not Exist"* ]]; then
        /usr/libexec/PlistBuddy -c "Add ':Graphics:InjectEDID' Bool" $config
    fi
    /usr/libexec/PlistBuddy -c "Set ':Graphics:InjectEDID' 'true'" $config

    echo config.plist/Graphics/CustomEDID updated.
}

init_edid
patch_edid
inject_edid
