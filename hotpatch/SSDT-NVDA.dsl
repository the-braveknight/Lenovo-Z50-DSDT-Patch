// For disabling the discrete GPU

DefinitionBlock("", "SSDT", 2, "hack", "NVDA", 0)
{   
    External(_SB.PCI0, DeviceObj)
    Scope(_SB.PCI0)
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
        
        External(RP05, DeviceObj)
        Scope(RP05)
        {
            External(PEGP, DeviceObj)
            External(LNKD, FieldUnitObj)
            External(LNKS, FieldUnitObj)
            Scope(PEGP)
            {
                External(\P8XH, MethodObj)
                External(LCTL, FieldUnitObj)
                External(ELCT, IntObj)
                External(VREG, FieldUnitObj)
                External(VGAB, BuffObj)
                External(SGPO, MethodObj)
                External(HLRS, FieldUnitObj)
                External(PWEN, FieldUnitObj)
                Method (_OFF, 0, Serialized)
                { 
                    P8XH (Zero, 0xD6, One)
                    P8XH (One, 0xF0, One)
                    Debug = "_SB.PCI0.RP05.PEGP._OFF"

                    ELCT = LCTL
                    VGAB = VREG
                    LNKD = One
                    While (LNKS != Zero)
                    {
                        Sleep (One)
                    }

                    SGPO (HLRS, One)
                    SGPO (PWEN, Zero)
                    Return (Zero)
                }
            }
        }

        External(LPCB.EC0, DeviceObj)
        Scope(LPCB.EC0)
        {
            External(\ECON, FieldUnitObj)
            External(XREG, MethodObj)
            External(GATY, FieldUnitObj)
            Method (_REG, 2, NotSerialized)
            {
                \_SB.PCI0.LPCB.EC0.XREG(Arg0, Arg1)
                If (ECON) { \_SB.PCI0.LPCB.EC0.GATY = Zero }
            }
        }              
    }
}
//EOF
