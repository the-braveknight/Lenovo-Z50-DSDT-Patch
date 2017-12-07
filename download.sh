function download() {
    curl --silent --output /tmp/org.$1.download.txt --location https://bitbucket.org/$1/$2/downloads/
    scrape=$(grep -o -m 1 "$1/$2/downloads/$3.*\.zip" /tmp/org.$1.download.txt | sed 's/".*//')
    echo Downloading $(basename $scrape)
    curl --remote-name --progress-bar --location https://bitbucket.org/$scrape
}

rm -Rf ./downloads && mkdir ./downloads && cd ./downloads

# Download kexts
mkdir ./kexts && cd ./kexts
download RehabMan os-x-fakesmc-kozlek
download RehabMan os-x-realtek-network
download RehabMan os-x-voodoo-ps2-controller
download RehabMan os-x-acpi-battery-driver
download RehabMan os-x-fake-pci-id
download RehabMan os-x-brcmpatchram
download RehabMan os-x-usb-inject-all
download RehabMan os-x-eapd-codec-commander
download RehabMan lilu
download RehabMan intelgraphicsfixup
download RehabMan ath9kfixup
cd ..

# Download tools
mkdir ./tools && cd ./tools
download RehabMan os-x-maciasl-patchmatic
download RehabMan os-x-maciasl-patchmatic RehabMan-patchmatic
download RehabMan acpica
cd ..
