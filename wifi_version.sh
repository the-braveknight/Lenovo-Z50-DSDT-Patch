ioreg -n PXSX -arxw0 > /tmp/org.the-braveknight.wifi.plist

id=$(/usr/libexec/PlistBuddy -c "Print :1:IOName" /tmp/org.the-braveknight.wifi.plist)

echo $id
