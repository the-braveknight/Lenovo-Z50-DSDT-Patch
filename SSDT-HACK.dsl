// Instead of providing patched DSDT/SSDT, just include a single SSDT
// and do the rest of the work in config.plist

// A bit experimental, and a bit more difficult with laptops, but
// still possible.

DefinitionBlock ("SSDT-HACK.aml", "SSDT", 1, "LENOVO", "hack", 0x00003000)
{
    External(_SB.PCI0, DeviceObj)
    External(_SB.PCI0.LPCB, DeviceObj)
    External(_SB.PCI0.LPCB.EC0, DeviceObj)
    External(_SB.PCI0.RP05.PEGP._OFF, MethodObj)
    External(_SB.PCI0.LPCB.PS2K, DeviceObj)
    External(ECON, FieldUnitObj)
    External(_SB.PCI0.LPCB.EC0.XREG, MethodObj)
    External(_SB.PCI0.LPCB.EC0.GATY, FieldUnitObj)
    External(XPRW, MethodObj)
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
    External(_SB.PCI0.EH01, DeviceObj)

    External(_SB.PCI0.LPCB.EC0.BAT0.PBIF, PkgObj)
    External(_SB.PCI0.LPCB.EC0.BAT0.PBST, PkgObj)
    External(_SB.PCI0.LPCB.EC0.BAT0.OBST, BuffObj)
    External(_SB.PCI0.LPCB.EC0.BAT0.OBAC, BuffObj)
    External(_SB.PCI0.LPCB.EC0.BAT0.OBPR, BuffObj)
    External(_SB.PCI0.LPCB.EC0.BAT0.OBRC, BuffObj)
    External(_SB.PCI0.LPCB.EC0.BAT0.OBPV, BuffObj)
    External(_SB.PCI0.LPCB.EC0.B1ST, FieldUnitObj)
    External(_SB.PCI0.LPCB.EC0.SMPR, FieldUnitObj)
    External(_SB.PCI0.LPCB.EC0.SMST, FieldUnitObj)
    External(_SB.PCI0.LPCB.EC0.SMAD, FieldUnitObj)
    External(_SB.PCI0.LPCB.EC0.BCNT, FieldUnitObj)
    External(_SB.PCI0.LPCB.EC0.SMCM, FieldUnitObj)
    External(_SB.PCI0.LPCB.EC0.CMFP, MethodObj)
    External(_SB.PCI0.LPCB.EC0.CFMX, MutexObj)
    External(P80H, FieldUnitObj)
    External(SMID, FieldUnitObj)
    External(SFNO, FieldUnitObj)
    External(CAVR, FieldUnitObj)
    External(STDT, FieldUnitObj)
    External(BFDT, FieldUnitObj)
    External(SMIC, FieldUnitObj)
    External(_SB.PCI0.LPCB.EC0.FUSL, FieldUnitObj)
    External(_SB.PCI0.LPCB.EC0.FUSH, FieldUnitObj)
    External(_SB.PCI0.LPCB.EC0.B1CT, FieldUnitObj)
    External(_SB.PCI0.XHC, DeviceObj)
    External(_SB.PCI0.XHC.PR2, FieldUnitObj)
    External(_SB.PCI0.XHC.PR2M, FieldUnitObj)
    External(_SB.PCI0.XHC.PR3, FieldUnitObj)
    External(_SB.PCI0.XHC.PR3M, FieldUnitObj)
    External(_SB.XUSB, FieldUnitObj)
    External(_SB.PCI0.XHC.XRST, IntObj)
 

    // All _OSI calls in DSDT are routed to XOSI...
    // XOSI simulates "Windows 2009" (which is Windows 7)
    // Note: According to ACPI spec, _OSI("Windows") must also return true
    //  Also, it should return true for all previous versions of Windows.
    Method(XOSI, 1)
    {
        // simulation targets
        // source: (google 'Microsoft Windows _OSI')
        //  http://download.microsoft.com/download/7/E/7/7E7662CF-CBEA-470B-A97E-CE7CE0D98DC2/WinACPI_OSI.docx
        Store(Package()
        {
            "Windows",              // generic Windows query
            "Windows 2001",         // Windows XP
            "Windows 2001 SP2",     // Windows XP SP2
            //"Windows 2001.1",     // Windows Server 2003
            //"Windows 2001.1 SP1", // Windows Server 2003 SP1
            "Windows 2006",         // Windows Vista
            "Windows 2006 SP1",     // Windows Vista SP1
            //"Windows 2006.1",     // Windows Server 2008
            "Windows 2009",         // Windows 7/Windows Server 2008 R2
            "Windows 2012",       // Windows 8/Windows Sesrver 2012
            "Windows 2013",       // Windows 8.1/Windows Server 2012 R2
            "Windows 2015",       // Windows 10/Windows Server TP
        }, Local0)
        Return (LNotEqual(Match(Local0, MEQ, Arg0, MTR, 0, 0), Ones))
    }

    // In DSDT, native GPRW is renamed to XPRW with Clover binpatch.
    // As a result, calls to GPRW land here.
    // The purpose of this implementation is to avoid "instant wake"
    // by returning 0 in the second position (sleep state supported)
    // of the return package.
    Method(GPRW, 2)
    {
        If (LEqual(Arg0, 0x6d)) { Return(Package() { 0x6d, 0, }) }
        Return(XPRW(Arg0, Arg1))
    }

    // For backlight control
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
        Method(_INI)
        {
            If (CondRefOf(\_SB.PCI0.RP05.PEGP._OFF))
            {
                \_SB.PCI0.RP05.PEGP._OFF()
            }
        }
    }
    
    Device(UIAC)
    {
        Name(_HID, "UIA00000")
        Name(RMCF, Package()
        {
            // EH01 has no ports (XHCIMux is used to force USB3 routing OFF)
            "EH01", Package()
            {
                "port-count", Buffer() { 0, 0, 0, 0 },
                "ports", Package() { },
            },
            // XHC overrides
            "8086_9xxx", Package()
            {
                //"port-count", Buffer() { 0x0d, 0, 0, 0},
                "ports", Package()
                {
                    "HS01", Package() // USB2 right
                    {
                        "UsbConnector", 0,
                        "port", Buffer() { 0x01, 0, 0, 0 },
                    },
                    "HS02", Package() // HS USB3 
                    {
                        "UsbConnector", 3,
                        "port", Buffer() { 0x02, 0, 0, 0 },
                    },
                    "HS03", Package() // USB2 left
                    {
                        "UsbConnector", 0,
                        "port", Buffer() { 0x03, 0, 0, 0 },
                    },
                    "HS04", Package() // card reader
                    {
                        "UsbConnector", 255,
                        "port", Buffer() { 0x04, 0, 0, 0 },
                    },
                    "HS06", Package() // webcam
                    {
                        "UsbConnector", 255,
                        "port", Buffer() { 0x06, 0, 0, 0 },
                    },
                    "HS07", Package() // bluetooth
                    {
                        "UsbConnector", 255,
                        "port", Buffer() { 0x07, 0, 0, 0 },
                    },
                    "SSP1", Package() // SS USB3 left
                    {
                        "UsbConnector", 3,
                        "port", Buffer() { 0x0a, 0, 0, 0 },
                    },
                },
            },
        })
    }
    
    Scope (_SB.PCI0)
    {
        Device(IMEI)
        {
            Name (_ADR, 0x00160000)
        }
        
        Device(SBUS.BUS0)
        {
            Name(_CID, "smbus")
            Name(_ADR, Zero)
            Device(DVL0)
            {
                Name(_ADR, 0x57)
                Name(_CID, "diagsvault")
                Method(_DSM, 4)
                {
                    If (LEqual (Arg2, Zero)) { Return (Buffer() { 0x03 } ) }
                    Return (Package() { "address", 0x57 })
                }
            }
        }
        
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
        
        Scope(EH01)
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
                Store(3, ^^EH01.PSTE)
                // disable EHCI#1 PCI space
                Store(1, ^^LPCB.FDE1)
            }
        }
        
        Method (RP05.PEGP._OFF, 0, Serialized)
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
        
        Method (LPCB.EC0._REG, 2, NotSerialized)
        {
            \_SB.PCI0.LPCB.EC0.XREG(Arg0, Arg1) // call original _REG
            If (ECON) { Store (Zero, \_SB.PCI0.LPCB.EC0.GATY) }
        }
        
        Method(LPCB.EC0._Q11)
        {
            Notify (PS2K, 0x20)
        }
        
        Method(LPCB.EC0._Q12)
        {
            Notify (PS2K, 0x10)
        }
    }
    
    Scope(_SB.PCI0.LPCB.EC0) // Battery Patches
    {      
        Method (BAT0._BST, 0, Serialized)  // _BST: Battery Status
        {
            Name (_T_0, Zero)  // _T_x: Emitted by ASL Compiler
            If (LEqual (ECON, One))
            {
                Sleep (0x10)
                Store (B1ST, Local0)
                Store (DerefOf (Index (PBST, Zero)), Local1)
                While (One)
                {
                    Store (And (Local0, 0x07), _T_0)
                    If (LEqual (_T_0, Zero))
                    {
                        Store (And (Local1, 0xF8), OBST)
                    }
                    Else
                    {
                        If (LEqual (_T_0, One))
                        {
                            Store (Or (One, And (Local1, 0xF8)), OBST)
                        }
                        Else
                        {
                            If (LEqual (_T_0, 0x02))
                            {
                                Store (Or (0x02, And (Local1, 0xF8)), OBST)
                            }
                            Else
                            {
                                If (LEqual (_T_0, 0x04))
                                {
                                    Store (Or (0x04, And (Local1, 0xF8)), OBST)
                                }
                            }
                        }
                    }

                    Break
                }

                Sleep (0x10)
                Store (B1B2 (AC00 ,AC01), OBAC)
                If (And (OBST, One))
                {
                    Store (And (Not (OBAC), 0x7FFF), OBAC)
                }

                Store (OBAC, OBPR)
                Sleep (0x10)
                Store (B1B2 (RC00, RC01), OBRC)
                Sleep (0x10)
                Store (B1B2 (FV00, FV01), OBPV)
                Multiply (OBRC, 0x0A, OBRC)
                Store (Divide (Multiply (OBAC, OBPV), 0x03E8, ), OBPR)
                Store (OBST, Index (PBST, Zero))
                Store (OBPR, Index (PBST, One))
                Store (OBRC, Index (PBST, 0x02))
                Store (OBPV, Index (PBST, 0x03))
            }

            Return (PBST)
        }

        Method (BAT0._BIF, 0, NotSerialized)  // _BIF: Battery Information
        {
            If (LEqual (ECON, One))
            {
                Store (B1B2 (DC00, DC01), Local0)
                Multiply (Local0, 0x0A, Local0)
                Store (Local0, Index (PBIF, One))
                Store (B1B2 (FC00, FC01), Local0)
                Multiply (Local0, 0x0A, Local0)
                Store (Local0, Index (PBIF, 0x02))
                Store (B1B2 (DV00, DV01), Index (PBIF, 0x04))
                Store ("", Index (PBIF, 0x09))
                Store ("", Index (PBIF, 0x0B))
            }

            Return (PBIF)
        }
        
        Method (RE1B, 1, NotSerialized)
        {
            OperationRegion(ERM2, EmbeddedControl, Arg0, 1)
            Field(ERM2, ByteAcc, NoLock, Preserve) { BYTE, 8 }
            Return(BYTE)
        }
        Method (RECB, 2, Serialized)
        // Arg0 - offset in bytes from zero-based EC
        // Arg1 - size of buffer in bits
        {
            ShiftRight(Arg1, 3, Arg1)
            Name(TEMP, Buffer(Arg1) { })
            Add(Arg0, Arg1, Arg1)
            Store(0, Local0)
            While (LLess(Arg0, Arg1))
            {
                Store(RE1B(Arg0), Index(TEMP, Local0))
                Increment(Arg0)
                Increment(Local0)
            }
            Return(TEMP)
        }
        
        OperationRegion (ERM2, EmbeddedControl, Zero, 0xFF)
        Field (ERM2, ByteAcc, Lock, Preserve)
        {
            Offset (0xC2),
            RC00, 8,
            RC01, 8,
            Offset (0xC6),
            FV00, 8,
            FV01, 8, 
            DV00, 8,
            DV01, 8, 
            DC00, 8,
            DC01, 8, 
            FC00, 8,
            FC01, 8,
            Offset (0xD2),
            AC00, 8,
            AC01, 8,
        }   
        
        Method (WE1B, 2, NotSerialized)
        {
            OperationRegion(ERM2, EmbeddedControl, Arg0, 1)
            Field(ERM2, ByteAcc, NoLock, Preserve) { BYTE, 8 }
            Store(Arg1, BYTE)
        }
        Method (WECB, 3, Serialized)
        // Arg0 - offset in bytes from zero-based EC
        // Arg1 - size of buffer in bits
        // Arg2 - value to write
        {
            ShiftRight(Arg1, 3, Arg1)
            Name(TEMP, Buffer(Arg1) { })
            Store(Arg2, TEMP)
            Add(Arg0, Arg1, Arg1)
            Store(0, Local0)
            While (LLess(Arg0, Arg1))
            {
                WE1B(Arg0, DerefOf(Index(TEMP, Local0)))
                Increment(Arg0)
                Increment(Local0)
            }
        }
        Method (VPC0.MHPF, 1, NotSerialized)
        {
            Name (BFWB, Buffer (0x25) {})
            CreateByteField (BFWB, Zero, FB0)
            CreateByteField (BFWB, One, FB1)
            CreateByteField (BFWB, 0x02, FB2)
            CreateByteField (BFWB, 0x03, FB3)
            CreateField (BFWB, 0x20, 0x0100, FB4)
            CreateByteField (BFWB, 0x24, FB5)
            If (LLessEqual (SizeOf (Arg0), 0x25))
            {
                If (LNotEqual (SMPR, Zero))
                {
                    Store (SMST, FB1)
                }
                Else
                {
                    Store (Arg0, BFWB)
                    Store (FB2, SMAD)
                    Store (FB3, SMCM)
                    Store (FB5, BCNT)
                    Store (FB0, Local0)
                    If (LEqual (And (Local0, One), Zero))
                    {
                        WECB (0x64, 0x0100, FB4)
                    }

                    Store (Zero, SMST)
                    Store (FB0, SMPR)
                    Store (0x03E8, Local1)
                    While (Local1)
                    {
                        Sleep (One)
                        Decrement (Local1)
                        If (LOr (LAnd (SMST, 0x80), LEqual (SMPR, Zero)))
                        {
                            Break
                        }
                    }

                    Store (FB0, Local0)
                    If (LNotEqual (And (Local0, One), Zero))
                    {
                        Store (RECB (0x64, 0x0100), FB4)
                    }

                    Store (SMST, FB1)
                    If (LOr (LEqual (Local1, Zero), LNot (LAnd (SMST, 0x80))))
                    {
                        Store (Zero, SMPR)
                        Store (0x92, FB1)
                    }
                }

                Return (BFWB)
            }
        }

        Method (VPC0.MHIF, 1, NotSerialized)
        {
            Store (0x50, P80H)
            If (LEqual (Arg0, Zero))
            {
                Name (RETB, Buffer (0x0A) {})
                Name (BUF1, Buffer (0x08) {})
                Store (RECB (0x14, 0x40), BUF1)
                CreateByteField (BUF1, Zero, FW0)
                CreateByteField (BUF1, One, FW1)
                CreateByteField (BUF1, 0x02, FW2)
                CreateByteField (BUF1, 0x03, FW3)
                CreateByteField (BUF1, 0x04, FW4)
                CreateByteField (BUF1, 0x05, FW5)
                CreateByteField (BUF1, 0x06, FW6)
                CreateByteField (BUF1, 0x07, FW7)
                Store (FUSL, Index (RETB, Zero))
                Store (FUSH, Index (RETB, One))
                Store (FW0, Index (RETB, 0x02))
                Store (FW1, Index (RETB, 0x03))
                Store (FW2, Index (RETB, 0x04))
                Store (FW3, Index (RETB, 0x05))
                Store (FW4, Index (RETB, 0x06))
                Store (FW5, Index (RETB, 0x07))
                Store (FW6, Index (RETB, 0x08))
                Store (FW7, Index (RETB, 0x09))
                Return (RETB)
            }
        }
        
        Method (VPC0.GBID, 0, Serialized)
        {
            Name (GBUF, Package (0x04)
            {
                Buffer (0x02)
                {
                    0x00, 0x00                                     
                }, 

                Buffer (0x02)
                {
                    0x00, 0x00                                     
                }, 

                Buffer (0x08)
                {
                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 
                }, 

                Buffer (0x08)
                {
                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 
                }
            })
            Store (B1CT, Index (DerefOf (Index (GBUF, Zero)), Zero))
            Store (Zero, Index (DerefOf (Index (GBUF, One)), Zero))
            Name (BUF1, Buffer (0x08) {})
            Store (RECB (0x14, 0x40), BUF1)
            CreateByteField (BUF1, Zero, FW0)
            CreateByteField (BUF1, One, FW1)
            CreateByteField (BUF1, 0x02, FW2)
            CreateByteField (BUF1, 0x03, FW3)
            CreateByteField (BUF1, 0x04, FW4)
            CreateByteField (BUF1, 0x05, FW5)
            CreateByteField (BUF1, 0x06, FW6)
            CreateByteField (BUF1, 0x07, FW7)
            Store (FW0, Index (DerefOf (Index (GBUF, 0x02)), Zero))
            Store (FW1, Index (DerefOf (Index (GBUF, 0x02)), One))
            Store (FW2, Index (DerefOf (Index (GBUF, 0x02)), 0x02))
            Store (FW3, Index (DerefOf (Index (GBUF, 0x02)), 0x03))
            Store (FW4, Index (DerefOf (Index (GBUF, 0x02)), 0x04))
            Store (FW5, Index (DerefOf (Index (GBUF, 0x02)), 0x05))
            Store (FW6, Index (DerefOf (Index (GBUF, 0x02)), 0x06))
            Store (FW7, Index (DerefOf (Index (GBUF, 0x02)), 0x07))
            Store (Zero, Index (DerefOf (Index (GBUF, 0x03)), Zero))
            Return (GBUF)
        }
        Method (CFUN, 4, Serialized)
        {
            Name (ESRC, 0x05)
            If (LNotEqual (Match (CMFP, MEQ, DerefOf (Index (Arg0, Zero)), MTR, 
                Zero, Zero), Ones))
            {
                Acquire (CFMX, 0xFFFF)
                Store (Arg0, SMID)
                Store (Arg1, SFNO)
                Store (Arg2, BFDT)
                Store (0xCE, SMIC)
                Release (CFMX)
            }
            Else
            {
                If (LEqual (DerefOf (Index (Arg0, Zero)), 0x10))
                {
                    If (LEqual (DerefOf (Index (Arg1, Zero)), One))
                    {
                        CreateByteField (Arg2, Zero, CAPV)
                        Store (CAPV, CAVR)
                        Store (One, STDT)
                    }
                    Else
                    {
                        If (LEqual (DerefOf (Index (Arg1, Zero)), 0x02))
                        {
                            Store (Buffer (0x80) {}, Local0)
                            CreateByteField (Local0, Zero, BFD0)
                            Store (0x08, BFD0)
                            Store (One, STDT)
                            Store (Local0, BFDT)
                        }
                        Else
                        {
                            Store (Zero, STDT)
                        }
                    }
                }
                Else
                {
                    If (LEqual (DerefOf (Index (Arg0, Zero)), 0x18))
                    {
                        Acquire (CFMX, 0xFFFF)
                        If (LEqual (DerefOf (Index (Arg1, Zero)), 0x02))
                        {
                            WECB (0x64, 0x0100, Zero)
                            Store (DerefOf (Index (Arg2, One)), SMAD)
                            Store (DerefOf (Index (Arg2, 0x02)), SMCM)
                            Store (DerefOf (Index (Arg2, Zero)), SMPR)
                            While (LAnd (Not (LEqual (ESRC, Zero)), Not (LEqual (And (SMST, 0x80
                                ), 0x80))))
                            {
                                Sleep (0x14)
                                Subtract (ESRC, One, ESRC)
                            }

                            Store (SMST, Local2)
                            If (LEqual (And (Local2, 0x80), 0x80))
                            {
                                Store (Buffer (0x80) {}, Local1)
                                Store (Local2, Index (Local1, Zero))
                                If (LEqual (Local2, 0x80))
                                {
                                    Store (0xC4, P80H)
                                    Store (BCNT, Index (Local1, One))
                                    Store (RECB (0x64, 0x0100), Local3)
                                    Store (DerefOf (Index (Local3, Zero)), Index (Local1, 0x02))
                                    Store (DerefOf (Index (Local3, One)), Index (Local1, 0x03))
                                    Store (DerefOf (Index (Local3, 0x02)), Index (Local1, 0x04))
                                    Store (DerefOf (Index (Local3, 0x03)), Index (Local1, 0x05))
                                    Store (DerefOf (Index (Local3, 0x04)), Index (Local1, 0x06))
                                    Store (DerefOf (Index (Local3, 0x05)), Index (Local1, 0x07))
                                    Store (DerefOf (Index (Local3, 0x06)), Index (Local1, 0x08))
                                    Store (DerefOf (Index (Local3, 0x07)), Index (Local1, 0x09))
                                    Store (DerefOf (Index (Local3, 0x08)), Index (Local1, 0x0A))
                                    Store (DerefOf (Index (Local3, 0x09)), Index (Local1, 0x0B))
                                    Store (DerefOf (Index (Local3, 0x0A)), Index (Local1, 0x0C))
                                    Store (DerefOf (Index (Local3, 0x0B)), Index (Local1, 0x0D))
                                    Store (DerefOf (Index (Local3, 0x0C)), Index (Local1, 0x0E))
                                    Store (DerefOf (Index (Local3, 0x0D)), Index (Local1, 0x0F))
                                    Store (DerefOf (Index (Local3, 0x0E)), Index (Local1, 0x10))
                                    Store (DerefOf (Index (Local3, 0x0F)), Index (Local1, 0x11))
                                    Store (DerefOf (Index (Local3, 0x10)), Index (Local1, 0x12))
                                    Store (DerefOf (Index (Local3, 0x11)), Index (Local1, 0x13))
                                    Store (DerefOf (Index (Local3, 0x12)), Index (Local1, 0x14))
                                    Store (DerefOf (Index (Local3, 0x13)), Index (Local1, 0x15))
                                    Store (DerefOf (Index (Local3, 0x14)), Index (Local1, 0x16))
                                    Store (DerefOf (Index (Local3, 0x15)), Index (Local1, 0x17))
                                    Store (DerefOf (Index (Local3, 0x16)), Index (Local1, 0x18))
                                    Store (DerefOf (Index (Local3, 0x17)), Index (Local1, 0x19))
                                    Store (DerefOf (Index (Local3, 0x18)), Index (Local1, 0x1A))
                                    Store (DerefOf (Index (Local3, 0x19)), Index (Local1, 0x1B))
                                    Store (DerefOf (Index (Local3, 0x1A)), Index (Local1, 0x1C))
                                    Store (DerefOf (Index (Local3, 0x1B)), Index (Local1, 0x1D))
                                    Store (DerefOf (Index (Local3, 0x1C)), Index (Local1, 0x1E))
                                    Store (DerefOf (Index (Local3, 0x1D)), Index (Local1, 0x1F))
                                    Store (DerefOf (Index (Local3, 0x1E)), Index (Local1, 0x20))
                                    Store (DerefOf (Index (Local3, 0x1F)), Index (Local1, 0x21))
                                }

                                Store (Local1, BFDT)
                                Store (One, STDT)
                            }
                            Else
                            {
                                Store (0xC5, P80H)
                                Store (Zero, STDT)
                            }
                        }
                        Else
                        {
                            Store (0xC6, P80H)
                            Store (Zero, STDT)
                        }

                        Release (CFMX)
                    }
                    Else
                    {
                        Store (Zero, STDT)
                    }
                }
            }
        }
        Method (\B1B2, 2, NotSerialized) { Return(Or(Arg0, ShiftLeft(Arg1, 8))) }
    }
}