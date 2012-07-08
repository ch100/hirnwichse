

DEF STRICT_CHECKS = 1

DEF OP_SIZE_BYTE  = 1
DEF OP_SIZE_WORD  = 2
DEF OP_SIZE_DWORD = 4
DEF OP_SIZE_QWORD = 8

cdef unsigned char BITMASK_BYTE  = 0xff
cdef unsigned short BITMASK_WORD  = 0xffff
cdef unsigned int BITMASK_DWORD = 0xffffffff
cdef unsigned long int BITMASK_QWORD = 0xffffffffffffffff



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

cdef tuple ROM_SIZES = (SIZE_64KB, SIZE_128KB, SIZE_256KB, SIZE_512KB, SIZE_1MB, SIZE_2MB, SIZE_4MB,
             SIZE_8MB, SIZE_16MB, SIZE_32MB, SIZE_64MB, SIZE_128MB, SIZE_256MB)


DEF VGA_TEXTMODE_ADDR = 0xb8000
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
DEF VGA_CURSOR_BASE_ADDR  = 0x450
DEF VGA_MODE_ADDR = 0x449
DEF VGA_CURSOR_TYPE_ADDR = 0x460
DEF VGA_PAGE_ADDR = 0x462
DEF VGA_VIDEO_CHAR_HEIGHT = 0x485
DEF VGA_VIDEO_CTL_ADDR = 0x487
DEF VGA_EXTREG_PROCESS_RAM = 0x2

DEF PPCB_T2_GATE = 0x01
DEF PPCB_T2_SPKR   = 0x02
DEF PPCB_T2_OUT  = 0x20

DEF UI_CHAR_WIDTH = 8


cdef tuple DMA_EXT_PAGE_REG_PORTS = (0x80, 0x84, 0x85, 0x86, 0x88, 0x8c, 0x8d, 0x8e)
cdef tuple PCI_CONTROLLER_PORTS = (0xcf8, 0xcf9, 0xcfc, 0xcfd, 0xcfe, 0xcff)
cdef tuple FDC_FIRST_READ_PORTS = (0x3f0, 0x3f1, 0x3f2, 0x3f3, 0x3f4, 0x3f5, 0x3f6, 0x3f7)
cdef tuple FDC_SECOND_READ_PORTS = (0x370, 0x371, 0x372, 0x373, 0x374, 0x375, 0x376, 0x377)
cdef tuple FDC_FIRST_WRITE_PORTS = (0x3f2, 0x3f3, 0x3f4, 0x3f5, 0x3f6, 0x3f7)
cdef tuple FDC_SECOND_WRITE_PORTS = (0x372, 0x373, 0x374, 0x375, 0x376, 0x377)


