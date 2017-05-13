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
            
            // CodecCommander.kext customizations
            // created by nayeweiyang/XuWang
            Name(RMCF, Package()
            {
                "CodecCommander", Package()
                {
                    "Custom Commands", Package()
                    {
                        Package(){}, // signifies Array instead of Dictionary
                        Package()
                        {
                            // 0x19 SET_PIN_WIDGET_CONTROL 0x24
                            "Command", Buffer() { 0x01, 0x97, 0x07, 0x24 },
                            "On Init", ">y",
                            "On Sleep", ">n",
                            "On Wake", ">y",
                        },
                        Package()
                        {
                            // 0x1a SET_PIN_WIDGET_CONTROL 0x24
                            "Command", Buffer() { 0x01, 0xa7, 0x07, 0x24 },
                            "On Init", ">y",
                            "On Sleep", ">n",
                            "On Wake", ">y",
                        },

                    },
                    "Perform Reset", ">n",
                    "Perform Reset on External Wake", ">n",
                },
            })
        }
    }
}
//EOF
