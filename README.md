##Lenovo Z50-70 DSDT patches by the-braveknight based on RehabMan's github repos.

This set of patches/makefile can be used to patch your Haswell Lenovo Z50-70 DSDT/SSDTs.  It relies heavily on already existing laptop DSDT patches at github here: https://github.com/RehabMan/Laptop-DSDT-Patch.. There are also post install scripts that can be used to create and install the kexts the are required for this laptop series.

The current repository actually uses only on-the-fly patches via config.plist and an additional SSDT, SSDT-HACK.aml.

Please refer to this guide thread on tonymacx86.com for a step-by-step process, feedback, and questions:

http://www.tonymacx86.com/el-capitan-laptop-guides/179520-guide-lenovo-z50-70-using-clover-uefi-10-11-a.html

2016-08-03

- Merged changes and fixes from RehabMan’s repo.
- Updated SSDT-HACK.dsl for using the new iasl (ACPI 6.1).


2015-12-24

- Added link to the-braveknight guide/thread on tonymacx86


2015-11-04

- Initial creation based on RehabMan's scripts.

