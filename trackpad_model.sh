ioreg -n PS2M -arxw0 > /tmp/org.the-braveknight.trackpad.plist

id=$(/usr/libexec/PlistBuddy -c "Print :0:name" /tmp/org.the-braveknight.trackpad.plist)

echo $id
