// generated from: ./gen_ahhcd.sh CX20751
DefinitionBlock ("", "SSDT", 2, "hack", "CX20751", 0)
{
    External(_SB.PCI0.HDEF, DeviceObj)
    Name(_SB.PCI0.HDEF.RMCF, Package()
    {
        "CodecCommander", Package()
        {
            "Disable", ">y",
        },
        "CodecCommanderPowerHook", Package()
        {
            "Disable", ">y",
        },
        "CodecCommanderProbeInit", Package()
        {
            "Version", 0x020600,
            "14f1_510f", Package()
            {
                "PinConfigDefault", Package()
                {
                    Package(){},
                    Package()
                    {
                        "LayoutID", 3,
                        "PinConfigs", Package()
                        {
                            Package(){},
                            0x16, 0x04211040,
                            0x17, 0x90170110,
                            0x19, 0x04811030,
                            0x1a, 0x90a00120,
                        },
                    },
                },
            },
        },
    })
}
//EOF
