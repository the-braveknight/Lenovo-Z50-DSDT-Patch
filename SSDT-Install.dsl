// Instead of providing patched DSDT/SSDT, just include a single SSDT
// and do the rest of the work in config.plist

// A bit experimental, and a bit more difficult with laptops, but
// still possible.

// This SSDT is only for use in the installer. It disables EHCI #1
// and the nVidia graphics card (if present).

DefinitionBlock ("", "SSDT", 2, "hack", "install", 0)
{
    External(_SB.PCI0, DeviceObj)
    External(_SB.PCI0.LPCB, DeviceObj)
    External(ECON, FieldUnitObj)
    External(_SB.PCI0.LPCB.EC0.XREG, MethodObj)
    External(_SB.PCI0.LPCB.EC0.GATY, FieldUnitObj)
    External(P8XH, MethodObj)
    External(_SB.PCI0.RP05.PEGP.LCTL, FieldUnitObj)
    External(_SB.PCI0.RP05.PEGP.ELCT, IntObj)
    External(_SB.PCI0.RP05.PEGP.VREG, FieldUnitObj)
    External(_SB.PCI0.RP05.PEGP.VGAB, BuffObj)
    External(_SB.PCI0.RP05.PEGP.LNKD, FieldUnitObj)
    External(_SB.PCI0.RP05.PEGP.LNKS, FieldUnitObj)
    External(_SB.PCI0.RP05.PEGP.SGPO, MethodObj)
    External(_SB.PCI0.RP05.PEGP.HLRS, FieldUnitObj)
    External(_SB.PCI0.RP05.PEGP.PWEN, FieldUnitObj)
    External(_SB.PCI0.EHC1, DeviceObj)
    External(_SB.PCI0.XHC.PR2, FieldUnitObj)
    External(_SB.PCI0.XHC.PR2M, FieldUnitObj)
    External(_SB.PCI0.XHC.PR3, FieldUnitObj)
    External(_SB.PCI0.XHC.PR3M, FieldUnitObj)
    External(_SB.XUSB, FieldUnitObj)
    External(_SB.PCI0.XHC.XRST, IntObj)

//
// Disabling EHCI #1
//
    Scope(_SB.PCI0)
    {
        Method(XHC.XSEL)
        {
            // This code is based on original XSEL, but without all the conditionals
            // With this code, USB works correctly even in 10.10 after booting Windows
            // setup to route all USB2 on XHCI to XHCI (not EHCI, which is disabled)
            Store(1, XUSB)
            Store(1, XRST)
            Or(And (PR3, 0xFFFFFFC0), PR3M, PR3)
            Or(And (PR2, 0xFFFF8000), PR2M, PR2)
        }
        // registers needed for disabling EHC#1
        Scope(EHC1)
        {
            OperationRegion(PSTS, PCI_Config, 0x54, 2)
            Field(PSTS, WordAcc, NoLock, Preserve)
            {
                PSTE, 2  // bits 2:0 are power state
            }
        }
        
        Scope(LPCB)
        {
            OperationRegion(RMLP, PCI_Config, 0xF0, 4)
            Field(RMLP, DWordAcc, NoLock, Preserve)
            {
                RCB1, 32, // Root Complex Base Address
            }
            // address is in bits 31:14
            OperationRegion(FDM1, SystemMemory, Add(And(RCB1,Not(Subtract(ShiftLeft(1,14),1))),0x3418), 4)
            Field(FDM1, DWordAcc, NoLock, Preserve)
            {
                ,15,    // skip first 15 bits
                FDE1,1, // should be bit 15 (0-based) (FD EHCI#1)
            }
        }
        Device(RMD1)
        {
            //Name(_ADR, 0)
            Name(_HID, "RMD10000")
            Method(_INI)
            {
                // disable EHCI#1
                // put EHCI#1 in D3hot (sleep mode)
                Store(3, ^^EHC1.PSTE)
                // disable EHCI#1 PCI space
                Store(1, ^^LPCB.FDE1)
            }
        }
    }
    
    Scope (_SB.PCI0) // disable nVidia from methods _OFF & _REG
    {
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
        
        Method (LPCB.EC0._REG, 2, NotSerialized) // disable nVidia from method _REG
        {
            \_SB.PCI0.LPCB.EC0.XREG(Arg0, Arg1)
            If (ECON) { Store (Zero, \_SB.PCI0.LPCB.EC0.GATY) }
        }
    }
}
// EOF