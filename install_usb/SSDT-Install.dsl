// This SSDT is only for use in the installer. It disables EHCI #1
// and the nVidia graphics card (if present).

DefinitionBlock ("", "SSDT", 2, "hack", "INST", 0)
{
    Device(RMD1)
    {
        Name(_HID, "RMD10000")
        Method(_INI)
        {
            // disable discrete graphics (Nvidia) if it is present
            If (CondRefOf(\_SB.PCI0.RP05.PEGP._OFF)) { \_SB.PCI0.RP05.PEGP._OFF() }
        }
    }
    
    External(_SB.PCI0, DeviceObj)
    Scope(_SB.PCI0)
    {
        External(\P8XH, MethodObj)
        External(RP05.PEGP.LCTL, FieldUnitObj)
        External(RP05.PEGP.ELCT, IntObj)
        External(RP05.PEGP.VREG, FieldUnitObj)
        External(RP05.PEGP.VGAB, BuffObj)
        External(RP05.PEGP.LNKD, FieldUnitObj)
        External(RP05.PEGP.LNKS, FieldUnitObj)
        External(RP05.PEGP.SGPO, MethodObj)
        External(RP05.PEGP.HLRS, FieldUnitObj)
        External(RP05.PEGP.PWEN, FieldUnitObj)
        Method (RP05.PEGP._OFF, 0, Serialized) // disable nVidia from method _OFF
        { 
            P8XH (Zero, 0xD6, One)
            P8XH (One, 0xF0, One)

            Store (LCTL, ELCT)
            Store (VREG, VGAB)
            Store (One, LNKD)
            While (LNotEqual (LNKS, Zero))
            {
                Sleep (One)
            }

            SGPO (HLRS, One)
            SGPO (PWEN, Zero)
            Return (Zero)
        }
        
        External(LPCB.EC0.XREG, MethodObj)
        External(LPCB.EC0.GATY, FieldUnitObj)
        External(\ECON, FieldUnitObj)
        Method (LPCB.EC0._REG, 2, NotSerialized) // disable nVidia from method _REG
        {
            \_SB.PCI0.LPCB.EC0.XREG(Arg0, Arg1)
            If (ECON) { Store (Zero, \_SB.PCI0.LPCB.EC0.GATY) }
        }
    }
    // Disabling EHCI #1
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
                Store(1, XUSB)
                Store(1, XRST)
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
    }
}
//EOF
