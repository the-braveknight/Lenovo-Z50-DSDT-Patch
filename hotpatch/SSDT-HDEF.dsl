// HDEF injection

DefinitionBlock("", "SSDT", 2, "hack", "HDEF", 0)
{
    
    // inject properties for audio
    External(_SB.PCI0, DeviceObj)
    Scope(_SB.PCI0)
    {
        External(HDEF, DeviceObj)
        Scope(HDEF)
        {
            Method(_DSM, 4)
            {
                If (!Arg2) { Return (Buffer() { 0x03 } ) }
                Return(Package()
                {
                    "layout-id", Buffer() { 3, 0, 0, 0 },
                    "PinConfigurations", Buffer() { },
                })
            }
        }
    }
}
//EOF
