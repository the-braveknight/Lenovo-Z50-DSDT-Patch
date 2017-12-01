function download
{
    curl --location --silent --output /tmp/org.rehabman.download.txt https://bitbucket.org/RehabMan/$1/downloads/
    scrape=$(grep -o -m 1 "RehabMan/$1/downloads/$2.*\.zip" /tmp/org.rehabman.download.txt|perl -ne 'print $1 if /(.*)\"/')
    echo Downloading $(basename $scrape)
    curl --remote-name --progress-bar --location https://bitbucket.org/$scrape
}

rm -Rf ./downloads && mkdir ./downloads && cd ./downloads

# Download kexts
mkdir ./kexts && cd ./kexts
download os-x-fakesmc-kozlek RehabMan-FakeSMC
download os-x-realtek-network RehabMan-Realtek-Network
download os-x-voodoo-ps2-controller RehabMan-Voodoo
download os-x-acpi-battery-driver RehabMan-Battery
download os-x-fake-pci-id RehabMan-FakePCIID
download os-x-brcmpatchram RehabMan-BrcmPatchRAM
download os-x-usb-inject-all RehabMan-USBInjectAll
download os-x-eapd-codec-commander RehabMan-CodecCommander
download lilu RehabMan-Lilu
download intelgraphicsfixup RehabMan-IntelGraphicsFixup
download ath9kfixup RehabMan-ATH9KFixup
cd ..

# Download tools
mkdir ./tools && cd ./tools
download os-x-maciasl-patchmatic RehabMan-patchmatic
download os-x-maciasl-patchmatic RehabMan-MaciASL
download acpica iasl iasl.zip
cd ..
