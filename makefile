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
BACKLIGHTINJECT=AppleBacklightInjector.kext

VERSION_ERA=$(shell ./print_version.sh)
ifeq "$(VERSION_ERA)" "10.10-"
	INSTDIR=/System/Library/Extensions
else
	INSTDIR=/Library/Extensions
endif
SLE=/System/Library/Extensions

# set build products
PRODUCTS=$(BUILDDIR)/SSDT-HACK.aml $(BUILDDIR)/SSDT-$(HDA).aml

IASLFLAGS=-vw 2095 -vw 2146
IASL=iasl

.PHONY: all
all: $(PRODUCTS) $(HDAHCDINJECT) #  $(HDAINJECT)

$(BUILDDIR)/SSDT-HACK.aml: ./SSDT-HACK.dsl
	$(IASL) $(IASLFLAGS) -p $@ $<

$(BUILDDIR)/SSDT-$(HDA).aml: ./SSDT-$(HDA).dsl
	$(IASL) $(IASLFLAGS) -p $@ $<

.PHONY: clean
clean:
	rm -f $(BUILDDIR)/*.dsl $(BUILDDIR)/*.aml
	make clean_hda

# Clover Install
.PHONY: install
install: $(PRODUCTS)
	$(eval EFIDIR:=$(shell sudo ./mount_efi.sh /))
	rm -f $(EFIDIR)/EFI/CLOVER/ACPI/patched/SSDT-HACK.aml
	rm -f $(EFIDIR)/EFI/CLOVER/ACPI/patched/SSDT-$(HDA).aml
	rm -f $(EFIDIR)/EFI/CLOVER/ACPI/patched/DSDT.aml
	rm -f $(EFIDIR)/EFI/CLOVER/ACPI/patched/SSDT-2.aml
	rm -f $(EFIDIR)/EFI/CLOVER/ACPI/patched/SSDT-3.aml
	rm -f $(EFIDIR)/EFI/CLOVER/ACPI/patched/SSDT-4.aml
	rm -f $(EFIDIR)/EFI/CLOVER/ACPI/patched/SSDT-5.aml
	rm -f $(EFIDIR)/EFI/CLOVER/ACPI/patched/SSDT-7.aml
	cp $(BUILDDIR)/SSDT-HACK.aml $(EFIDIR)/EFI/CLOVER/ACPI/patched/SSDT-HACK.aml
	cp $(BUILDDIR)/SSDT-$(HDA).aml $(EFIDIR)/EFI/CLOVER/ACPI/patched/SSDT-$(HDA).aml

#$(HDAINJECT) $(HDAHCDINJECT): $(RESOURCES)/*.plist ./patch_hda.sh
$(HDAHCDINJECT): $(RESOURCES)/*.plist ./patch_hda.sh
	./patch_hda.sh $(HDA)

.PHONY: clean_hda
clean_hda:
	rm -rf $(HDAHCDINJECT) $(HDAZML) # $(HDAINJECT)

$(BACKLIGHTINJECT): Backlight.plist patch_backlight.sh
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
	#sudo cp -R ./$(HDAHCDINJECT) $(INSTDIR)
	#if [ "`which tag`" != "" ]; then sudo tag -a Blue $(INSTDIR)/$(HDAHCDINJECT); fi
	sudo cp $(HDAZML)/*.zml* $(SLE)/AppleHDA.kext/Contents/Resources
	if [ "`which tag`" != "" ]; then sudo tag -a Blue $(SLE)/AppleHDA.kext/Contents/Resources/*.zml*; fi
	make update_kernelcache

FORCED=/ForcedExtensions
.PHONY: install_hdax
install_hdax:
	sudo rm -Rf $(INSTDIR)/$(HDAINJECT)
	sudo rm -Rf $(INSTDIR)/$(HDAHCDINJECT)
	#sudo cp -R ./$(HDAHCDINJECT) $(FORCED)
	#if [ "`which tag`" != "" ]; then sudo tag -a Blue $(FORCED)/$(HDAHCDINJECT); fi
	sudo cp $(HDAZML)/*.zml* $(FORCED)/AppleHDA_Resources
	if [ "`which tag`" != "" ]; then sudo tag -a Blue $(FORCED)/AppleHDA_Resources/*.zml*; fi

.PHONY: install_backlight
install_backlight:
	sudo rm -Rf $(INSTDIR)/$(BACKLIGHTINJECT)
	sudo cp -R ./$(BACKLIGHTINJECT) $(INSTDIR)
	if [ "`which tag`" != "" ]; then sudo tag -a Blue $(INSTDIR)/$(BACKLIGHTINJECT); fi
	make update_kernelcache

