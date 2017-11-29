ioreg -n PS2M -arxw0 > /tmp/org.the-braveknight.trackpad.plist

if [ ! -s /tmp/org.the-braveknight.trackpad.plist ]; then
    echo Error determining trackpad model!
    exit 1
fi

id=`/usr/libexec/PlistBuddy -c "Print :0:name" /tmp/org.the-braveknight.trackpad.plist`

echo $id
