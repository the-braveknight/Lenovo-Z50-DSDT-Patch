# makefile

#
# Patches/Installs/Builds DSDT patches for Lenovo Z50-70
#
# Created by RehabMan, modified by the-braveknight
#

BUILDDIR=./build

IASLFLAGS=-ve
IASL=iasl

PRODUCTS=$(BUILDDIR)/SSDT-PS2K.aml $(BUILDDIR)/SSDT-HDAU.aml $(BUILDDIR)/SSDT-HDEF.aml $(BUILDDIR)/SSDT-PNLF.aml $(BUILDDIR)/SSDT-XOSI.aml $(BUILDDIR)/SSDT-GPRW.aml $(BUILDDIR)/SSDT-BATT.aml $(BUILDDIR)/SSDT-UIAC.aml $(BUILDDIR)/SSDT-USB.aml $(BUILDDIR)/SSDT-NVDA.aml $(BUILDDIR)/SSDT-IGPU.aml $(BUILDDIR)/SSDT-PM.aml

.PHONY: all
all: $(PRODUCTS)

$(BUILDDIR)/%.aml : ./hotpatch/%.dsl
	$(IASL) $(IASLFLAGS) -p $@ $<

.PHONY: clean
clean:
	rm -f $(BUILDDIR)/*.aml

# Clover Install
.PHONY: install
install: $(PRODUCTS)
	$(eval EFIDIR:=$(shell sudo ./mount_efi.sh /))
	rm -f $(EFIDIR)/EFI/CLOVER/ACPI/patched/*.aml
	cp $(PRODUCTS) $(EFIDIR)/EFI/CLOVER/ACPI/patched
