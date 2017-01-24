# Sometimes iMessage breaks due to SmUUID being blacklisted
# or blocked by Apple servers, so generating a new SmUUID
# is required in order to get it to work again.

EFI=`sudo ./mount_efi.sh /`
UUID=`uuidgen`
CONFIG=$EFI/EFI/CLOVER/config.plist
SMBIOS=$EFI/EFI/CLOVER/smbios.plist

if [ -e $EFI/EFI/CLOVER/smbios.plist ]; then
    PLIST=$SMBIOS
else
    PLIST=$CONFIG
fi

COMMENT=`/usr/libexec/PlistBuddy -c "Print :SMBIOS:SmUUID" $PLIST 2>&1`

if [[ "$COMMENT" == *"Does Not Exist"* ]]; then
    /usr/libexec/PlistBuddy -c "Add ':SMBIOS:SmUUID' String" $PLIST
fi

/usr/libexec/PlistBuddy -c "Set ':SMBIOS:SmUUID' '$UUID'" $PLIST

echo $PLIST/SMBIOS/SmUUID=$UUID.
