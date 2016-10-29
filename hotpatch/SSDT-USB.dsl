// USB configuration for Lenovo Z50-70/Z40-70 laptops

DefinitionBlock ("", "SSDT", 2, "hack", "USB", 0)
{
    // Override for USBInjectAll.kext
    Device(UIAC)
    {
        Name(_HID, "UIA00000")
        Name(RMCF, Package()
        {
            // EHC1 is disabled
            // XHC overrides
            "8086_9c31", Package()
            {
                //"port-count", Buffer() { 0x0d, 0, 0, 0},
                "ports", Package()
                {
                    "HS01", Package() // USB2 right
                    {
                        "UsbConnector", 0,
                        "port", Buffer() { 1, 0, 0, 0 },
                    },
                    "HS02", Package() // HS USB3 
                    {
                        "UsbConnector", 3,
                        "port", Buffer() { 2, 0, 0, 0 },
                    },
                    "HS03", Package() // USB2 left
                    {
                        "UsbConnector", 0,
                        "port", Buffer() { 3, 0, 0, 0 },
                    },
                    "HS06", Package() // Webcam
                    {
                        "UsbConnector", 255,
                        "port", Buffer() { 6, 0, 0, 0 },
                    },
                    "HS07", Package() // Bluetooth
                    {
                        "UsbConnector", 255,
                        "port", Buffer() { 7, 0, 0, 0 },
                    },
                    "SSP1", Package() // SS USB3
                    {
                        "UsbConnector", 3,
                        "port", Buffer() { 10, 0, 0, 0 },
                    },
                },
            },
        })
    }

    // Disabling EHCI #1
    External(_SB.PCI0, DeviceObj)
    External(_SB.PCI0.LPCB, DeviceObj)
    External(_SB.PCI0.EHC1, DeviceObj)
    External(_SB.PCI0.XHC, DeviceObj)
    Scope(_SB.PCI0)
    {
        // registers needed for disabling EHC#1
        Scope(EHC1)
        {
            OperationRegion(RMP1, PCI_Config, 0x54, 2)
            Field(RMP1, WordAcc, NoLock, Preserve)
            {
                PSTE, 2  // bits 2:0 are power state
            }
        }
        
        External(\_SB.XUSB, FieldUnitObj)
        External(XHC.XRST, IntObj)
        External(XHC.PR3, FieldUnitObj)
        External(XHC.PR3M, FieldUnitObj)
        External(XHC.PR2, FieldUnitObj)
        External(XHC.PR2M, FieldUnitObj)
        Scope(XHC)
        {
            Method(XSEL)
            {
                // This code is based on original XSEL, but without all the conditionals
                // With this code, USB works correctly even in 10.10 after booting Windows
                // setup to route all USB2 on XHCI to XHCI (not EHCI, which is disabled)
                XUSB = 1
                XRST = 1
                Or(And (PR3, 0xFFFFFFC0), PR3M, PR3)
                Or(And (PR2, 0xFFFF8000), PR2M, PR2)
            }
            // Injecting XHC properties
            Method(_DSM, 4) 
            {
                If (!Arg2) { Return (Buffer() { 0x03 } ) }
                Return(Package()
                {
                    "RM,pr2-force", Buffer() { 0xff, 0x3f, 0, 0 },
                    "subsystem-id", Buffer() { 0x70, 0x72, 0x00, 0x00 },
                    "subsystem-vendor-id", Buffer() { 0x86, 0x80, 0x00, 0x00 },
                    "AAPL,current-available", Buffer() { 0x34, 0x08, 0, 0 },
                    "AAPL,current-extra", Buffer() { 0x98, 0x08, 0, 0, },
                    "AAPL,current-extra-in-sleep", Buffer() { 0x40, 0x06, 0, 0, },
                    "AAPL,max-port-current-in-sleep", Buffer() { 0x34, 0x08, 0, 0 },
                })
            }
        }
        
        // registers needed for disabling EHC#1
        Scope(LPCB)
        {
            OperationRegion(RMP1, PCI_Config, 0xF0, 4)
            Field(RMP1, DWordAcc, NoLock, Preserve)
            {
                RCB1, 32, // Root Complex Base Address
            }
            // address is in bits 31:14
            OperationRegion(FDM1, SystemMemory, (RCB1 & Not((1<<14)-1)) + 0x3418, 4)
            Field(FDM1, DWordAcc, NoLock, Preserve)
            {
                ,15,
                FDE1,1, // should be bit 15 (0-based) (FD EHCI#1)
            }
        }
        
        Device(RMD2)
        {
            //Name(_ADR, 0)
            Name(_HID, "RMD10000")
            Method(_INI)
            {
                // disable EHCI#1
                // put EHCI#1 in D3hot (sleep mode)
                ^^EHC1.PSTE = 3
                // disable EHCI#1 PCI space
                ^^LPCB.FDE1 = 1
            }
        }
    }
}
//EOF