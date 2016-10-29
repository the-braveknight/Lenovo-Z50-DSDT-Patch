// Keyboard configuration

DefinitionBlock("", "SSDT", 2, "hack", "PS2K", 0)
{   
    // Enabling brightness keys
    External(_SB.PCI0.LPCB.EC0, DeviceObj)
    External(PS2V, FieldUnitObj)
    External(_SB.PCI0.LPCB.PS2K, DeviceObj)
    Scope(_SB.PCI0.LPCB.EC0) // brightness buttons
    {
        Method (_Q11) // Brightness down
        {
            If (LEqual (PS2V, 2)) // If the touchpad is Synaptics & using RehabMan's VoodooPS2 driver...
            {
                Notify (PS2K, 0x0405)
            }
            Else // If the touchpad is ELAN/Other & using EMlyDinEsH's PS2 driver...
            {
                Notify (PS2K, 0x20)
            }
        }
        
        Method (_Q12) // Btightness up
        {
            If (LEqual (PS2V, 2)) // If the touchpad is Synaptics & using RehabMan's VoodooPS2 driver...
            {
                Notify (PS2K, 0x0406)
            }
            Else // If the touchpad is ELAN/Other & using EMlyDinEsH's PS2 driver...
            {
                Notify (PS2K, 0x10)
            }
        }
    }
}
//EOF