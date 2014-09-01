

DEF STRICT_CHECKS = 1

DEF OP_SIZE_BYTE  = 1
DEF OP_SIZE_WORD  = 2
DEF OP_SIZE_DWORD = 4
DEF OP_SIZE_QWORD = 8

DEF BITMASK_BYTE  = 0xff
DEF BITMASK_WORD  = 0xffff
DEF BITMASK_DWORD = 0xffffffff
DEF BITMASK_QWORD = 0xffffffffffffffff
#cdef unsigned int BITMASK_DWORD = 0xffffffff
#cdef unsigned long int BITMASK_QWORD = 0xffffffffffffffff



DEF CMOS_CURRENT_SECOND    = 0x00
DEF CMOS_ALARM_SECOND      = 0x01
DEF CMOS_CURRENT_MINUTE    = 0x02
DEF CMOS_ALARM_MINUTE      = 0x03
DEF CMOS_CURRENT_HOUR      = 0x04
DEF CMOS_ALARM_HOUR        = 0x05
DEF CMOS_DAY_OF_WEEK       = 0x06
DEF CMOS_DAY_OF_MONTH      = 0x07
DEF CMOS_MONTH             = 0x08
DEF CMOS_YEAR_NO_CENTURY   = 0x09 # year without century: e.g.  00 - 99
DEF CMOS_STATUS_REGISTER_A = 0x0a
DEF CMOS_STATUS_REGISTER_B = 0x0b
DEF CMOS_STATUS_REGISTER_C = 0x0c
DEF CMOS_STATUS_REGISTER_D = 0x0d
DEF CMOS_SHUTDOWN_STATUS   = 0x0f
DEF CMOS_FLOPPY_DRIVE_TYPE = 0x10
DEF CMOS_HDD_DRIVE_TYPE    = 0x12
DEF CMOS_HD0_EXTENDED_DRIVE_TYPE = 0x19
DEF CMOS_HD1_EXTENDED_DRIVE_TYPE = 0x1a
DEF CMOS_HD0_CYLINDERS = 0x1b
DEF CMOS_HD1_CYLINDERS = 0x24
DEF CMOS_HD0_WRITE_PRECOMP = 0x1e
DEF CMOS_HD1_WRITE_PRECOMP = 0x27
DEF CMOS_HD0_LANDING_ZONE = 0x21
DEF CMOS_HD1_LANDING_ZONE = 0x2a
DEF CMOS_HD0_HEADS = 0x1d
DEF CMOS_HD1_HEADS = 0x26
DEF CMOS_HD0_SPT = 0x23
DEF CMOS_HD1_SPT = 0x2c
DEF CMOS_HD0_CONTROL_BYTE  = 0x20
DEF CMOS_HD1_CONTROL_BYTE  = 0x29
DEF CMOS_EQUIPMENT_BYTE    = 0x14
DEF CMOS_BASE_MEMORY_L     = 0x15
DEF CMOS_BASE_MEMORY_H     = 0x16
DEF CMOS_EXT_MEMORY_L      = 0x17
DEF CMOS_EXT_MEMORY_H      = 0x18
DEF CMOS_EXT_BIOS_CFG      = 0x2d
DEF CMOS_CHECKSUM_H        = 0x2e
DEF CMOS_CHECKSUM_L        = 0x2f
DEF CMOS_EXT_MEMORY_L2     = 0x30
DEF CMOS_EXT_MEMORY_H2     = 0x31
DEF CMOS_CENTURY           = 0x32
DEF CMOS_EXT_MEMORY2_L     = 0x34
DEF CMOS_EXT_MEMORY2_H     = 0x35
DEF CMOS_BOOT_FROM_3       = 0x38
DEF CMOS_BOOT_FROM_1_2     = 0x3d
DEF CMOS_ATA_0_1_TRANSLATION = 0x39
DEF CMOS_ATA_2_3_TRANSLATION = 0x3a

DEF ATA_TRANSLATE_NONE  = 0
DEF ATA_TRANSLATE_LBA   = 1
DEF ATA_TRANSLATE_LARGE = 2
DEF ATA_TRANSLATE_RECHS = 3

DEF CMOS_STATUSB_24HOUR = 0x02
DEF CMOS_STATUSB_BIN    = 0x04

DEF BDA_TICK_COUNTER_ADDR  = 0x46c # dword
DEF BDA_MIDNIGHT_FLAG_ADDR = 0x470 # byte


DEF FLOPPY_DISK_TYPE_NONE  = 0
DEF FLOPPY_DISK_TYPE_360K  = 1
DEF FLOPPY_DISK_TYPE_1_2M  = 2
DEF FLOPPY_DISK_TYPE_720K  = 3
DEF FLOPPY_DISK_TYPE_1_44M = 4
DEF FLOPPY_DISK_TYPE_2_88M = 5
DEF FLOPPY_DISK_TYPE_160K  = 6
DEF FLOPPY_DISK_TYPE_180K  = 7
DEF FLOPPY_DISK_TYPE_320K  = 8

DEF BOOT_FROM_NONE = 0
DEF BOOT_FROM_FD = 1
DEF BOOT_FROM_HD = 2
DEF BOOT_FROM_CD = 3

DEF SIZE_1MB_MASK = 0xfffff

DEF SIZE_360K = 368640
DEF SIZE_720K = 737280
DEF SIZE_1_2M = 1228800
DEF SIZE_1_44M = 1474560
DEF SIZE_2_88M = 2867200

DEF SIZE_64KB  = 0x10000
DEF SIZE_128KB = 0x20000
DEF SIZE_256KB = 0x40000
DEF SIZE_512KB = 0x80000
DEF SIZE_1MB   = 0x100000
DEF SIZE_2MB   = 0x200000
DEF SIZE_4MB   = 0x400000
DEF SIZE_8MB   = 0x800000
DEF SIZE_16MB  = 0x1000000
DEF SIZE_32MB  = 0x2000000
DEF SIZE_64MB  = 0x4000000
DEF SIZE_128MB = 0x8000000
DEF SIZE_256MB = 0x10000000

DEF ROM_SIZES = (SIZE_64KB, SIZE_128KB, SIZE_256KB, SIZE_512KB, SIZE_1MB, SIZE_2MB, SIZE_4MB,
             SIZE_8MB, SIZE_16MB, SIZE_32MB, SIZE_64MB, SIZE_128MB, SIZE_256MB)


DEF VGA_MEMAREA_ADDR = 0xa0000
DEF VGA_SEQ_INDEX_ADDR = 0x3c4
DEF VGA_SEQ_DATA_ADDR  = 0x3c5
DEF VGA_SEQ_MAX_INDEX  = 1
DEF VGA_SEQ_AREA_SIZE = 256
DEF VGA_CRT_AREA_SIZE = 256
DEF VGA_GDC_AREA_SIZE = 256
DEF VGA_DAC_AREA_SIZE = 0x300
DEF VGA_EXTREG_AREA_SIZE = 256
DEF VGA_ATTRCTRLREG_AREA_SIZE = 256
DEF VGA_CRT_OFREG_LC8 = 0x10
DEF VGA_CRT_PROTECT_REGISTERS = 0x80
DEF VGA_GDC_MISC_GREG_INDEX = 0x06
DEF VGA_GDC_MEMBASE_MASK       = 0x03
DEF VGA_GDC_MEMBASE_A0000_128K = 0x00
DEF VGA_GDC_MEMBASE_A0000_64K  = 0x01
DEF VGA_GDC_MEMBASE_B0000_32K  = 0x02
DEF VGA_GDC_MEMBASE_B8000_32K  = 0x03
DEF VGA_ATTRCTRLREG_VIDEO_ENABLED = 0x20
DEF VGA_ATTRCTRLREG_CONTROL_REG_INDEX = 0x10
DEF VGA_ATTRCTRLREG_CONTROL_REG_LGE = 0x4
DEF VGA_ATTRCTRLREG_CONTROL_REG_BLINK = 0x8
DEF VGA_ATTRCTRLREG_CONTROL_REG_GRAPHICAL_MODE = 0x1
DEF VGA_MODE_ADDR = 0x449
DEF VGA_COLUMNS_ADDR = 0x44a
DEF VGA_PAGE_SIZE_ADDR = 0x44c
DEF VGA_CURSOR_BASE_ADDR  = 0x450
DEF VGA_CURSOR_TYPE_ADDR = 0x460
DEF VGA_ACTUAL_PAGE_ADDR = 0x462
DEF VGA_ROWS_ADDR = 0x484
DEF VGA_VIDEO_CHAR_HEIGHT = 0x485
DEF VGA_VIDEO_CTL_ADDR = 0x487
DEF VGA_EXTREG_PROCESS_RAM = 0x2
DEF VGA_EXTREG_COLOR_MODE = 0x1
DEF VGA_FONTAREA_SIZE = 8192
DEF VGA_FONTAREA_CHAR_HEIGHT = 32

DEF PPCB_T2_GATE = 0x01
DEF PPCB_T2_SPKR   = 0x02
DEF PPCB_T2_OUT  = 0x20

DEF PCI_FUNCTION_CONFIG_SIZE = 256

DEF PCI_BUS_SHIFT = 16
DEF PCI_DEVICE_SHIFT = 11
DEF PCI_FUNCTION_SHIFT = 8

DEF PCI_VENDOR_ID = 0x00
DEF PCI_DEVICE_ID = 0x02
DEF PCI_COMMAND = 0x04
DEF PCI_STATUS = 0x06
DEF PCI_PROG_IF = 0x09
DEF PCI_DEVICE_CLASS = 0x0a
DEF PCI_HEADER_TYPE = 0x0e
DEF PCI_BIST = 0xf
DEF PCI_BASE_ADDRESS_0 = 0x10
DEF PCI_BASE_ADDRESS_1 = 0x14
DEF PCI_BASE_ADDRESS_2 = 0x18
DEF PCI_BASE_ADDRESS_3 = 0x1c
DEF PCI_BASE_ADDRESS_4 = 0x20
DEF PCI_BASE_ADDRESS_5 = 0x24
DEF PCI_ROM_ADDRESS = 0x30
DEF PCI_CAPABILITIES_POINTER = 0x34
DEF PCI_INTERRUPT_LINE = 0x3c

DEF PCI_BRIDGE_IO_BASE_LOW = 0x1c
DEF PCI_BRIDGE_IO_LIMIT_LOW = 0x1d
DEF PCI_BRIDGE_MEM_BASE = 0x20
DEF PCI_BRIDGE_MEM_LIMIT = 0x22
DEF PCI_BRIDGE_PREF_MEM_BASE_LOW = 0x24
DEF PCI_BRIDGE_PREF_MEM_LIMIT_LOW = 0x26
DEF PCI_BRIDGE_PREF_MEM_BASE_HIGH = 0x28
DEF PCI_BRIDGE_PREF_MEM_LIMIT_HIGH = 0x2c
DEF PCI_BRIDGE_IO_BASE_HIGH = 0x30
DEF PCI_BRIDGE_IO_LIMIT_HIGH = 0x32
DEF PCI_BRIDGE_ROM_ADDRESS = 0x38


DEF PCI_PRIMARY_BUS = 0x18
DEF PCI_SECONDARY_BUS = 0x19
DEF PCI_SUBORDINATE_BUS = 0x1a

DEF PCI_CLASS_PATA        = 0x0101
DEF PCI_CLASS_VGA         = 0x0300
DEF PCI_CLASS_BRIDGE_HOST = 0x0600
DEF PCI_CLASS_BRIDGE_PCI  = 0x0604
DEF PCI_VENDOR_ID_INTEL   = 0x8086
DEF PCI_DEVICE_ID_INTEL_440FX = 0x1237

DEF PCI_HEADER_TYPE_STANDARD = 0
DEF PCI_HEADER_TYPE_BRIDGE = 1
DEF PCI_RESET_VALUE = 0x02


DEF PCI_BAR0_ENABLED_MASK = 0x1
DEF PCI_BAR1_ENABLED_MASK = 0x2
DEF PCI_BAR2_ENABLED_MASK = 0x4
DEF PCI_BAR3_ENABLED_MASK = 0x8
DEF PCI_BAR4_ENABLED_MASK = 0x10
DEF PCI_BAR5_ENABLED_MASK = 0x20

DEF PCI_MEM_BASE = 0xc0000000

DEF VGA_ROM_BASE = 0xc0000


DEF UI_CHAR_WIDTH = 9

DEF DMA_EXT_PAGE_REG_PORTS = (0x80, 0x84, 0x85, 0x86, 0x88, 0x8c, 0x8d, 0x8e)
DEF PCI_CONTROLLER_PORTS = (0x4d0, 0x4d1, 0xcf8, 0xcf9, 0xcfc, 0xcfd, 0xcfe, 0xcff)
DEF ATA1_PORTS = (0x1f0, 0x1f1, 0x1f2, 0x1f3, 0x1f4, 0x1f5, 0x1f6, 0x1f7, 0x3f6)
DEF ATA2_PORTS = (0x170, 0x171, 0x172, 0x173, 0x174, 0x175, 0x176, 0x177, 0x376)
DEF ATA3_PORTS = (0x1e8, 0x1e9, 0x1ea, 0x1eb, 0x1ec, 0x1ed, 0x1ee, 0x1ef, 0x3e6, 0x3e7, 0x3ee)
DEF ATA4_PORTS = (0x168, 0x169, 0x16a, 0x16b, 0x16c, 0x16d, 0x16e, 0x16f, 0x366, 0x367, 0x36e)
DEF FDC_FIRST_READ_PORTS = (0x3f0, 0x3f1, 0x3f2, 0x3f3, 0x3f4, 0x3f5, 0x3f7)
DEF FDC_SECOND_READ_PORTS = (0x370, 0x371, 0x372, 0x373, 0x374, 0x375, 0x377)
DEF FDC_FIRST_WRITE_PORTS = (0x3f2, 0x3f3, 0x3f4, 0x3f5, 0x3f7)
DEF FDC_SECOND_WRITE_PORTS = (0x372, 0x373, 0x374, 0x375, 0x377)

DEF VGA_READ_PORTS = (0x1ce, 0x1cf, 0x3b4, 0x3b5, 0x3ba, 0x3c0, 0x3c1, 0x3c5, 0x3cc, 0x3c7, 0x3c8, 0x3c9, 0x3ca, 0x3d4, 0x3d5, 0x3da)
DEF VGA_WRITE_PORTS = (0x1ce, 0x1cf, 0x3b4, 0x3b5, 0x3ba, 0x3c0, 0x3c2, 0x3c4, 0x3c5, 0x3c6, 0x3c7, 0x3c8, 0x3c9, 0x3ca, 0x3ce, 0x3cf, 0x3d4, 0x3d5, 0x3da, 0x400, 0x401, 0x402, 0x403, 0x500, 0x504)




DEF BITMASKS_80 = (None, 0x80, 0x8000, None, 0x80000000, None, None, None, 0x8000000000000000)
DEF BITMASKS_FF = (None, 0xff, 0xffff, None, 0xffffffff, None, None, None, 0xffffffffffffffff)


