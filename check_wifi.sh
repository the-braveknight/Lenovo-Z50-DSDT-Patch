ioreg -n PXSX -arxw0 > /tmp/org.the-braveknight.wifi.plist

if [ ! -s /tmp/org.the-braveknight.wifi.plist ]; then
    echo Error determining Wi-Fi card model!
    exit 1
fi

id=`/usr/libexec/PlistBuddy -c "Print :1:IOName" /tmp/org.the-braveknight.wifi.plist`

echo $id
