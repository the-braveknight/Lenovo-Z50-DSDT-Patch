// SSDT-_REG: Experimental

DefinitionBlock ("", "SSDT", 2, "hack", "NVDA-REG", 0)
{
    External(_SB.PCI0.LPCB.EC0, DeviceObj)
    External(ECON, FieldUnitObj)
    Scope(_SB.PCI0.LPCB.EC0)
    {
        External(XREG, MethodObj)
        External(GATY, FieldUnitObj)        
        Method (_REG, 2, NotSerialized)  // _REG: Region Availability
        {
            XREG(Arg0, Arg1)
            If(Arg0 == 3 && Arg1 == 1)
            {
                If(ECON)
                {
                    GATY = Zero
                }
            }
        }
    }
}