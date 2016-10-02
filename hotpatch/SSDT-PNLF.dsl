// Brightness control

DefinitionBlock("", "SSDT", 2, "hack", "PNLF", 0)
{
    // Adding PNLF device for IntelBacklight.kext
    Device(PNLF)
    {
        Name(_ADR, Zero)
        Name(_HID, EisaId ("APP0002"))
        Name(_CID, "backlight")
        Name(_UID, 10)
        Name(_STA, 0x0B)
        Name(RMCF, Package()
        {
            "PWMMax", 0,
        })
    }
    
    // Enabling brightness keys
    External(_SB.PCI0.LPCB.EC0, DeviceObj)
    External(_SB.PCI0.LPCB.PS2K, DeviceObj)
    Scope(_SB.PCI0.LPCB.EC0) // brightness buttons
    {
        Method (_Q11) // Brightness down
        {
            Notify (PS2K, 0x0405) // For VoodooPS2Controller.kext
            Notify (PS2K, 0x20)   // For ApplePS2SmartTouchPad.kext
        }
        
        Method (_Q12) // Btightness up
        {
            Notify (PS2K, 0x0406) // For VoodooPS2Controller.kext
            Notify (PS2K, 0x10)   // For ApplePS2SmartTouchPad.kext
        }
    }
}
//EOF