#!/bin/bash

# Extract display parameters to a plist.
ioreg -n AppleBacklightDisplay -arxw0 > /tmp/org.the-braveknight.display.plist

# Define vendor/product-ids
RepVendId1=0x06; VendId1Index=8  # Offset (0x08)
RepVendId2=0x10; VendId2Index=9  # Offset (0x09)
RepProdId1=0xf2; ProdId1Index=10 # Offset (0x0a)
RepProdId2=0x9c; ProdId2Index=11 # Offset (0x0b)

# Define EDID array
NativeEDID=(`/usr/libexec/PlistBuddy -c "Print ':0:IODisplayEDID'" /tmp/org.the-braveknight.display.plist|xxd -i`)

function replace_byte
{
# $1 = Index (Offset)
# $2 = Value
    PatchedEDID[$1]=${2/0x/}
    echo "Offset `printf \"0x%02x\n\" $1` patched: (${NativeEDID[$1]/,/} -> $2)"
}

function patch_edid
{
    for ((i=0; i < 127; i++)); do
        Byte=${NativeEDID[$i]/,/}

        if [ $i == $VendId1Index ]; then
            replace_byte $i $RepVendId1
            Sum=$(($Sum+$RepVendId1))

        elif [ $i == $VendId2Index ]; then
            replace_byte $i $RepVendId2
            Sum=$(($Sum+$RepVendId2))

        elif [ $i == $ProdId1Index ]; then
            replace_byte $i $RepProdId1
            Sum=$(($Sum+$RepProdId1))

        elif [ $i == $ProdId2Index ]; then
            replace_byte $i $RepProdId2
            Sum=$(($Sum+$RepProdId2))

        else
            PatchedEDID[$i]=${Byte/0x/}
            Sum=$(($Sum+$Byte))
        fi
    done

    RepChksm=`printf "0x%02x\n" $(( 256 -  ($Sum % 256) ))`
    replace_byte 127 $RepChksm

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


OrigVendId1=${NativeEDID[$VendId1Index]/,/}
OrigVendId2=${NativeEDID[$VendId2Index]/,/}
OrigProdId1=${NativeEDID[$ProdId1Index]/,/}
OrigProdId2=${NativeEDID[$ProdId2Index]/,/}


if [ $OrigVendId1 == $RepVendId1 ] && [ $OrigVendId2 == $RepVendId2 ] && [ $OrigProdId1 == $RepProdId1 ] && [ $OrigProdId2 == $RepProdId2 ]; then
    echo "EDID correct or already patched, aborting..."
else
    patch_edid
    mount_efi
    inject_edid $EDIDStr $config
fi
