# makefile

#
# Patches/Installs/Builds DSDT patches for Lenovo Z50-70
#
# Created by RehabMan, modified by the-braveknight
#

BUILDDIR=./build
HDA=CX20751
RESOURCES=./Resources_$(HDA)
HDAINJECT=AppleHDA_$(HDA).kext
HDAHCDINJECT=AppleHDAHCD_$(HDA).kext
HDAZML=AppleHDA_$(HDA)_Resources

VERSION_ERA=$(shell ./print_version.sh)
ifeq "$(VERSION_ERA)" "10.10-"
	INSTDIR=/System/Library/Extensions
else
	INSTDIR=/Library/Extensions
endif
SLE=/System/Library/Extensions

IASLFLAGS=-ve
IASL=iasl

PRODUCTS=$(BUILDDIR)/SSDT-PS2K.aml $(BUILDDIR)/SSDT-HDAU.aml $(BUILDDIR)/SSDT-HDEF.aml $(BUILDDIR)/SSDT-PNLF.aml $(BUILDDIR)/SSDT-XOSI.aml $(BUILDDIR)/SSDT-GPRW.aml $(BUILDDIR)/SSDT-BATT.aml $(BUILDDIR)/SSDT-UIAC.aml $(BUILDDIR)/SSDT-USB.aml $(BUILDDIR)/SSDT-NVDA.aml $(BUILDDIR)/SSDT-IGPU.aml

.PHONY: all
all: $(PRODUCTS) $(HDAINJECT) $(HDAHCDINJECT)

$(BUILDDIR)/%.aml : ./hotpatch/%.dsl
	$(IASL) $(IASLFLAGS) -p $@ $<

.PHONY: clean
clean:
	rm -f $(BUILDDIR)/*.dsl $(BUILDDIR)/*.aml
	make clean_hda

# Clover Install
.PHONY: install
install: $(PRODUCTS)
	$(eval EFIDIR:=$(shell sudo ./mount_efi.sh /))
	rm -f $(EFIDIR)/EFI/CLOVER/ACPI/patched/SSDT-*.aml
	cp $(PRODUCTS) $(EFIDIR)/EFI/CLOVER/ACPI/patched

$(HDAINJECT) $(HDAHCDINJECT): $(RESOURCES)/*.plist ./patch_hda.sh
	./patch_hda.sh $(HDA)

.PHONY: clean_hda
clean_hda:
	rm -rf $(HDAHCDINJECT) $(HDAZML) $(HDAINJECT)

$(BACKLIGHTINJECT): ./backlight/Backlight.plist ./backlight/patch_backlight.sh
	./backlight/patch_backlight.sh
	touch $@

.PHONY: update_kernelcache
update_kernelcache:
	sudo touch $(SLE)
	sudo kextcache -update-volume /

.PHONY: install_hdadummy
install_hdadummy:
	sudo rm -Rf $(INSTDIR)/$(HDAINJECT)
	sudo rm -Rf $(INSTDIR)/$(HDAHCDINJECT)
	sudo cp -R ./$(HDAINJECT) $(INSTDIR)
	sudo rm -f $(SLE)/AppleHDA.kext/Contents/Resources/*.zml*
	if [ "`which tag`" != "" ]; then sudo tag -a Blue $(INSTDIR)/$(HDAINJECT); fi
	make update_kernelcache

.PHONY: install_hda
install_hda:
	sudo rm -Rf $(INSTDIR)/$(HDAINJECT)
	sudo rm -Rf $(INSTDIR)/$(HDAHCDINJECT)
	sudo cp $(HDAZML)/*.zml* $(SLE)/AppleHDA.kext/Contents/Resources
	if [ "`which tag`" != "" ]; then sudo tag -a Blue $(SLE)/AppleHDA.kext/Contents/Resources/*.zml*; fi
	make update_kernelcache

.PHONY: install_hdahcd
install_hdahcd:
	sudo rm -Rf $(INSTDIR)/$(HDAINJECT)
	sudo rm -Rf $(INSTDIR)/$(HDAHCDINJECT)
	sudo cp -R ./$(HDAHCDINJECT) $(INSTDIR)
	if [ "`which tag`" != "" ]; then sudo tag -a Blue $(INSTDIR)/$(HDAHCDINJECT); fi
	sudo cp $(HDAZML)/*.zml* $(SLE)/AppleHDA.kext/Contents/Resources
	if [ "`which tag`" != "" ]; then sudo tag -a Blue $(SLE)/AppleHDA.kext/Contents/Resources/*.zml*; fi
	make update_kernelcache
