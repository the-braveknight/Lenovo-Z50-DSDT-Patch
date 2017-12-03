## Lenovo Z50-70 DSDT patches by the-braveknight based on RehabMan's github repos.

This set of patches/makefile can be used to patch your Haswell Lenovo Z50-70 DSDT/SSDTs.  It relies heavily on already existing laptop DSDT patches at github here: https://github.com/RehabMan/Laptop-DSDT-Patch.. There are also post install scripts that can be used to create and install the kexts the are required for this laptop series.

The current repository actually uses only on-the-fly patches via config.plist and additional SSDTs.

Please refer to this guide thread on tonymacx86.com for a step-by-step process, feedback, and questions:

https://www.tonymacx86.com/threads/guide-lenovo-z50-70-z40-70-using-clover-uefi.232823/

### 2017-12-1

- Dropped support for 10.10 & earlier.
- Added support for Atheros AR9565 Wi-Fi card (using ATH9KFixup.kext).
- Auto determine trackpad model and install the appropriate kext.


### 2016-10-02

- Split SSDT-HACK.dsl into multiple SSDTs
- Injecting device properties via SSDTs instead of config.plist/Devices/Arbitrary


### 2016-08-03

- Merged changes and fixes from RehabMan’s repo.
- Updated SSDT-HACK.dsl for using the new iasl (ACPI 6.1).


### 2015-12-24

- Added link to the guide/thread on tonymacx86


### 2015-11-04

- Initial creation based on RehabMan's scripts.

