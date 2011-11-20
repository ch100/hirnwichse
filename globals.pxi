
# Parity Flag Table: DO NOT EDIT!!
cdef tuple PARITY_TABLE = (True, False, False, True, False, True, True, False, False, True,
                True, False, True, False, False, True, False, True, True, False,
                True, False, False, True, True, False, False, True, False, True,
                True, False, False, True, True, False, True, False, False, True,
                True, False, False, True, False, True, True, False, True, False,
                False, True, False, True, True, False, False, True, True, False,
                True, False, False, True, False, True, True, False, True, False,
                False, True, True, False, False, True, False, True, True, False,
                True, False, False, True, False, True, True, False, False, True,
                True, False, True, False, False, True, True, False, False, True,
                False, True, True, False, False, True, True, False, True, False,
                False, True, False, True, True, False, True, False, False, True,
                True, False, False, True, False, True, True, False, False, True,
                True, False, True, False, False, True, True, False, False, True,
                False, True, True, False, True, False, False, True, False, True,
                True, False, False, True, True, False, True, False, False, True,
                True, False, False, True, False, True, True, False, False, True,
                True, False, True, False, False, True, False, True, True, False,
                True, False, False, True, True, False, False, True, False, True,
                True, False, True, False, False, True, False, True, True, False,
                False, True, True, False, True, False, False, True, False, True,
                True, False, True, False, False, True, True, False, False, True,
                False, True, True, False, False, True, True, False, True, False,
                False, True, True, False, False, True, False, True, True, False,
                True, False, False, True, False, True, True, False, False, True,
                True, False, True, False, False, True)

# regs:
# offset 0 == QWORD
# offset 1 == DWORD
# offset 2 == WORD
# offset 3 == HBYTE
# offset 4 == LBYTE

DEF CPU_REGISTER_OFFSET_QWORD = 0
DEF CPU_REGISTER_OFFSET_DWORD = 1
DEF CPU_REGISTER_OFFSET_WORD = 2
DEF CPU_REGISTER_OFFSET_HBYTE = 3
DEF CPU_REGISTER_OFFSET_LBYTE = 4



DEF CPU_MIN_REGISTER = 20
DEF CPU_REGISTER_NONE = 0
DEF CPU_REGISTER_RAX = 20
DEF CPU_REGISTER_EAX = 21
DEF CPU_REGISTER_AX  = 22
DEF CPU_REGISTER_AH  = 23
DEF CPU_REGISTER_AL  = 24
DEF CPU_REGISTER_RCX = 25
DEF CPU_REGISTER_ECX = 26
DEF CPU_REGISTER_CX  = 27
DEF CPU_REGISTER_CH  = 28
DEF CPU_REGISTER_CL  = 29
DEF CPU_REGISTER_RDX = 30
DEF CPU_REGISTER_EDX = 31
DEF CPU_REGISTER_DX  = 32
DEF CPU_REGISTER_DH  = 33
DEF CPU_REGISTER_DL  = 34
DEF CPU_REGISTER_RBX = 35
DEF CPU_REGISTER_EBX = 36
DEF CPU_REGISTER_BX  = 37
DEF CPU_REGISTER_BH  = 38
DEF CPU_REGISTER_BL  = 39
DEF CPU_REGISTER_RSP = 40
DEF CPU_REGISTER_ESP = 41
DEF CPU_REGISTER_SP  = 42
DEF CPU_REGISTER_RBP = 45
DEF CPU_REGISTER_EBP = 46
DEF CPU_REGISTER_BP  = 47
DEF CPU_REGISTER_RSI = 50
DEF CPU_REGISTER_ESI = 51
DEF CPU_REGISTER_SI  = 52
DEF CPU_REGISTER_RDI = 55
DEF CPU_REGISTER_EDI = 56
DEF CPU_REGISTER_DI  = 57
DEF CPU_REGISTER_RIP = 60
DEF CPU_REGISTER_EIP = 61
DEF CPU_REGISTER_IP  = 62
DEF CPU_REGISTER_RFLAGS = 65
DEF CPU_REGISTER_EFLAGS = 66
DEF CPU_REGISTER_FLAGS  = 67

DEF CPU_SEGMENT_CS = 72
DEF CPU_SEGMENT_SS = 77
DEF CPU_SEGMENT_DS = 82
DEF CPU_SEGMENT_ES = 87
DEF CPU_SEGMENT_FS = 92
DEF CPU_SEGMENT_GS = 97

DEF CPU_REGISTER_CR0 = 101
DEF CPU_REGISTER_CR2 = 106
DEF CPU_REGISTER_CR3 = 111
DEF CPU_REGISTER_CR4 = 116

DEF CPU_REGISTER_DR0 = 121
DEF CPU_REGISTER_DR1 = 126
DEF CPU_REGISTER_DR2 = 131
DEF CPU_REGISTER_DR3 = 136
DEF CPU_REGISTER_DR6 = 141
DEF CPU_REGISTER_DR7 = 146


DEF CPU_MAX_REGISTER_WO_CR = 100 # without CRd
DEF CPU_MAX_REGISTER = 150
DEF CPU_REGISTER_LENGTH = 200*8
DEF CPU_NB_REGS64 = 16
DEF CPU_NB_REGS = 8
DEF CPU_NB_REGS32 = CPU_NB_REGS
DEF NUM_CORE_REGS = (CPU_NB_REGS * 2) + 25

DEF FLAG_CF   = 0x1
DEF FLAG_REQUIRED = 0x2
DEF FLAG_PF   = 0x4
DEF FLAG_AF   = 0x10
DEF FLAG_ZF   = 0x40
DEF FLAG_SF   = 0x80
DEF FLAG_TF   = 0x100
DEF FLAG_IF   = 0x200
DEF FLAG_DF   = 0x400
DEF FLAG_OF   = 0x800
DEF FLAG_IOPL = 0x3000
DEF FLAG_NT   = 0x4000
DEF FLAG_RF   = 0x10000 # resume flag
DEF FLAG_VM   = 0x20000 # virtual 8086 mode
DEF FLAG_AC   = 0x40000 # alignment check if this and CR0 #AM set
DEF FLAG_VIF  = 0x80000 # virtual interrupt flag
DEF FLAG_VIP  = 0x100000 # virtual interrupt pending flag
DEF FLAG_ID   = 0x200000

DEF CR0_FLAG_PE = 0x1
DEF CR0_FLAG_MP = 0x2
DEF CR0_FLAG_EM = 0x4
DEF CR0_FLAG_TS = 0x8
DEF CR0_FLAG_ET = 0x10
DEF CR0_FLAG_NE = 0x20
DEF CR0_FLAG_WP = 0x10000
DEF CR0_FLAG_AM = 0x40000
DEF CR0_FLAG_NW = 0x20000000
DEF CR0_FLAG_CD = 0x40000000
DEF CR0_FLAG_PG = 0x80000000


DEF CR4_FLAG_VME = 0x1
DEF CR4_FLAG_PVI = 0x2
DEF CR4_FLAG_TSD = 0x4
DEF CR4_FLAG_DE  = 0x8
DEF CR4_FLAG_PSE = 0x10
DEF CR4_FLAG_PAE = 0x20
DEF CR4_FLAG_MCE = 0x40
DEF CR4_FLAG_PGE = 0x80
DEF CR4_FLAG_PCE = 0x100
DEF CR4_FLAG_OSFXSR = 0x200
DEF CR4_FLAG_OSXMMEXCPT = 0x400

DEF MODRM_FLAGS_NONE = 0
DEF MODRM_FLAGS_SREG = 1
DEF MODRM_FLAGS_CREG = 2
DEF MODRM_FLAGS_DREG = 4


DEF IDT_INTR_TYPE_INTERRUPT = 6
DEF IDT_INTR_TYPE_TRAP = 7
DEF IDT_INTR_TYPE_TASK = 5

cdef tuple IDT_INTR_TYPES = (IDT_INTR_TYPE_INTERRUPT, IDT_INTR_TYPE_TRAP, IDT_INTR_TYPE_TASK)


cdef tuple CPU_REGISTER_QWORD = (CPU_REGISTER_RAX,CPU_REGISTER_RCX,CPU_REGISTER_RDX,CPU_REGISTER_RBX,CPU_REGISTER_RSP,
                    CPU_REGISTER_RBP,CPU_REGISTER_RSI,CPU_REGISTER_RDI,CPU_REGISTER_RIP,CPU_REGISTER_RFLAGS)

cdef tuple CPU_REGISTER_DWORD = (CPU_REGISTER_EAX,CPU_REGISTER_ECX,CPU_REGISTER_EDX,CPU_REGISTER_EBX,CPU_REGISTER_ESP,
                    CPU_REGISTER_EBP,CPU_REGISTER_ESI,CPU_REGISTER_EDI,CPU_REGISTER_EIP,CPU_REGISTER_EFLAGS,
                    CPU_REGISTER_CR0,CPU_REGISTER_CR2,CPU_REGISTER_CR3,CPU_REGISTER_CR4,
                    CPU_REGISTER_DR0,CPU_REGISTER_DR1,CPU_REGISTER_DR2,CPU_REGISTER_DR3,
                    CPU_REGISTER_DR6,CPU_REGISTER_DR7)

cdef tuple CPU_REGISTER_WORD = (CPU_REGISTER_AX,CPU_REGISTER_CX,CPU_REGISTER_DX,CPU_REGISTER_BX,CPU_REGISTER_SP,
                   CPU_REGISTER_BP,CPU_REGISTER_SI,CPU_REGISTER_DI,CPU_REGISTER_IP,CPU_REGISTER_FLAGS)

cdef tuple CPU_REGISTER_HBYTE = (CPU_REGISTER_AH,CPU_REGISTER_CH,CPU_REGISTER_DH,CPU_REGISTER_BH)
cdef tuple CPU_REGISTER_LBYTE = (CPU_REGISTER_AL,CPU_REGISTER_CL,CPU_REGISTER_DL,CPU_REGISTER_BL)

cdef tuple CPU_REGISTER_BYTE = (CPU_REGISTER_AL,CPU_REGISTER_CL,CPU_REGISTER_DL,CPU_REGISTER_BL,CPU_REGISTER_AH,CPU_REGISTER_CH,CPU_REGISTER_DH,CPU_REGISTER_BH)

cdef tuple CPU_REGISTER_SREG = (CPU_SEGMENT_ES,CPU_SEGMENT_CS,CPU_SEGMENT_SS,CPU_SEGMENT_DS,CPU_SEGMENT_FS,CPU_SEGMENT_GS,None,None)
cdef tuple CPU_REGISTER_CREG = (CPU_REGISTER_CR0, None, CPU_REGISTER_CR2, CPU_REGISTER_CR3, CPU_REGISTER_CR4, None, None, None)
cdef tuple CPU_REGISTER_DREG = (CPU_REGISTER_DR0, CPU_REGISTER_DR1, CPU_REGISTER_DR2, CPU_REGISTER_DR3, None, None, CPU_REGISTER_DR6, CPU_REGISTER_DR7)

cdef tuple CPU_REGISTER_INST_POINTER = (CPU_REGISTER_RIP, CPU_REGISTER_EIP, CPU_REGISTER_IP)

DEF GDT_USE_LDT = 0x4
DEF GDT_FLAG_GRANULARITY = 0x8
DEF GDT_FLAG_SIZE = 0x4 # 0==16bit; 1==32bit
DEF GDT_FLAG_LONGMODE = 0x2
DEF GDT_FLAG_AVAILABLE = 0x1

DEF GDT_ACCESS_ACCESSED = 0x1
DEF GDT_ACCESS_READABLE_WRITABLE = 0x2 # segment readable/writable
DEF GDT_ACCESS_CONFORMING = 0x4
DEF GDT_ACCESS_EXECUTABLE = 0x8 # 1==code segment; 0==data segment
DEF GDT_ACCESS_SEGMENT_TYPE = 0x10
DEF GDT_ACCESS_DPL = 0x60
DEF GDT_ACCESS_PRESENT = 0x80

DEF SELECTOR_USE_LDT = 0x4

DEF OP_SIZE_BYTE  = 1
DEF OP_SIZE_WORD = 2
DEF OP_SIZE_DWORD = 4
DEF OP_SIZE_QWORD = 8


DEF SET_FLAGS_ADD = 1
DEF SET_FLAGS_SUB = 2
DEF SET_FLAGS_MUL = 3
DEF SET_FLAGS_DIV = 4


DEF CPU_EXCEPTION_DE = 0 # divide-by-zero error
DEF CPU_EXCEPTION_DB = 1 # debug
DEF CPU_EXCEPTION_BP = 3 # breakpoint
DEF CPU_EXCEPTION_OF = 4 # overflow
DEF CPU_EXCEPTION_BR = 5 # bound range exceeded
DEF CPU_EXCEPTION_UD = 6 # invalid opcode
DEF CPU_EXCEPTION_NM = 7 # device not available
DEF CPU_EXCEPTION_DF = 8 # double fault
DEF CPU_EXCEPTION_TS = 10 # invalid TSS
DEF CPU_EXCEPTION_NP = 11 # segment not present
DEF CPU_EXCEPTION_SS = 12 # stack-segment fault
DEF CPU_EXCEPTION_GP = 13 # general-protection fault
DEF CPU_EXCEPTION_PF = 14 # page fault
DEF CPU_EXCEPTION_MF = 16 # x87 floating-point exception
DEF CPU_EXCEPTION_AC = 17 # alignment check
DEF CPU_EXCEPTION_MC = 18 # machine check
DEF CPU_EXCEPTION_XF = 19 # simd floating-point exception
DEF CPU_EXCEPTION_SX = 30 # security exception


cdef tuple CPU_EXCEPTIONS_FAULT_GROUP = (CPU_EXCEPTION_DE, CPU_EXCEPTION_BR, CPU_EXCEPTION_UD, CPU_EXCEPTION_NM, CPU_EXCEPTION_TS, \
                        CPU_EXCEPTION_NP, CPU_EXCEPTION_SS, CPU_EXCEPTION_GP, CPU_EXCEPTION_PF, CPU_EXCEPTION_MF, \
                        CPU_EXCEPTION_AC, CPU_EXCEPTION_XF)

### TODO: CPU_EXCEPTION_DB is FAULT/TRAP
cdef tuple CPU_EXCEPTIONS_TRAP_GROUP = (CPU_EXCEPTION_DB, CPU_EXCEPTION_BP, CPU_EXCEPTION_OF)

cdef tuple CPU_EXCEPTIONS_WITH_ERRORCODE = (CPU_EXCEPTION_DF, CPU_EXCEPTION_TS, CPU_EXCEPTION_NP, CPU_EXCEPTION_SS, \
                                 CPU_EXCEPTION_GP, CPU_EXCEPTION_PF, CPU_EXCEPTION_AC)


DEF OPCODE_PREFIX_CS=0x2e
DEF OPCODE_PREFIX_SS=0x36
DEF OPCODE_PREFIX_DS=0x3e
DEF OPCODE_PREFIX_ES=0x26
DEF OPCODE_PREFIX_FS=0x64
DEF OPCODE_PREFIX_GS=0x65
cdef tuple OPCODE_PREFIX_SEGMENTS = (OPCODE_PREFIX_CS, OPCODE_PREFIX_SS, OPCODE_PREFIX_DS, OPCODE_PREFIX_ES, OPCODE_PREFIX_FS, OPCODE_PREFIX_GS)
DEF OPCODE_PREFIX_OP=0x66
DEF OPCODE_PREFIX_ADDR=0x67
DEF OPCODE_PREFIX_LOCK=0xf0
DEF OPCODE_PREFIX_REPNE=0xf2
DEF OPCODE_PREFIX_REPE=0xf3
cdef tuple OPCODE_PREFIX_REPS = (OPCODE_PREFIX_REPNE,OPCODE_PREFIX_REPE)


cdef tuple OPCODE_PREFIXES = (OPCODE_PREFIX_LOCK, OPCODE_PREFIX_OP, OPCODE_PREFIX_ADDR, OPCODE_PREFIX_CS,
                 OPCODE_PREFIX_SS, OPCODE_PREFIX_DS, OPCODE_PREFIX_ES, OPCODE_PREFIX_FS,
                 OPCODE_PREFIX_GS, OPCODE_PREFIX_REPNE, OPCODE_PREFIX_REPE) 

cdef tuple OPCODES_LOCK_PREFIX_INVALID = (0x07, 0x17, 0x1f, 0x38, 0x39, 0x3a, 0x3b, 0x3c, 0x3d, 0x58, 0x59, 0x5a, 0x5b, 0x5c, 0x5d,
                               0x5e, 0x5f, 0x60, 0x61, 0x62, 0x63, 0x69, 0x6b, 0x70, 0x71, 0x72, 0x73, 0x74, 0x75,
                               0x76, 0x77, 0x78, 0x79, 0x7a, 0x7b, 0x7c, 0x7d, 0x7e, 0x7f, 0x84, 0x85, 0x90, 0x9a, 0x9c,
                               0xa8, 0xa9, 0xc8, 0xc9, 0xcd, 0xe3, 0xe8, 0xe9, 0xea, 0xeb, 0xf9, 0xfb, 0xfd)


DEF VALUEOP_SAVE = 0
DEF VALUEOP_ADD  = 1
DEF VALUEOP_ADC  = 2
DEF VALUEOP_SUB  = 3
DEF VALUEOP_SBB  = 4
DEF VALUEOP_AND  = 5
DEF VALUEOP_OR   = 6
DEF VALUEOP_XOR  = 7
cdef tuple VALUEOPS = (VALUEOP_SAVE, VALUEOP_ADD, VALUEOP_ADC, VALUEOP_SUB, VALUEOP_SBB, VALUEOP_AND, VALUEOP_OR, VALUEOP_XOR)

DEF GETADDR_OPCODE = 1
DEF GETADDR_NEXT_OPCODE = 2
cdef tuple GETADDR_VALUES = (GETADDR_OPCODE, GETADDR_NEXT_OPCODE)

DEF BT_NONE = 0
DEF BT_NOT = 1
DEF BT_SET = 2
DEF BT_CLEAR = 3

DEF FDC_IRQ = 6 # floppy disk controller's IRQnum
DEF KBC_IRQ = 1 # keyboard controller's IRQnum


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


DEF FDC_ST0_NR = 0x8 # ST0 drive not ready
DEF FDC_ST0_UC = 0x10 # ST0 unit check, set on error
DEF FDC_ST0_SE = 0x20 # ST0 seek end
DEF FDC_ST1_NID = 0x1 # ST1 no address mark
DEF FDC_ST1_NW = 0x2 # ST1 write protected
DEF FDC_ST1_NDAT = 0x4 # ST1 no data
DEF FDC_ST1_TO = 0x10 # ST1 time-out
DEF FDC_ST1_DE = 0x20 # ST1 data error
DEF FDC_ST1_EN = 0x80 # ST1 end of cylinder
DEF FDC_ST3_DSDR = 0x8 # ST3 double sided drive/floppy
DEF FDC_ST3_TRKO = 0x10 # ST3 track 0 seeked
DEF FDC_ST3_RDY = 0x20 # ST3 drive ready
DEF FDC_ST3_WPDR = 0x40 # ST3 write protected
DEF FDC_DOR_NORESET = 0x4 # DOR reset
DEF FDC_DOR_DMA = 0x8 # DOR dma && irq enabled
DEF FDC_MSR_BUSY = 0x10 # MSR command busy
DEF FDC_MSR_NODMA = 0x20 # MSR just use PIO. (NO DMA!)
DEF FDC_MSR_DIO = 0x40 # MSR FIFO IO port expects an IN opcode (wiki.osdev.org)
DEF FDC_MSR_RQM = 0x80 # MSR ok (or mandatory) to exchange bytes with the FIFO IO port (wiki.osdev.org)
DEF FDC_SECTOR_SIZE = 512

cdef dict FDC_CMDLENGTH_TABLE = { 0x3: 3, 0x4: 2, 0x7: 2, 0x8: 1, 0xf: 3, 0x45: 9, 0x46: 9, 0x4a: 2, 0x66: 9, 0xc5: 9, 0xc6: 9, 0xe6: 9}
cdef tuple FDC_FIRST_READ_PORTS = (0x3f0, 0x3f1, 0x3f2, 0x3f3, 0x3f4, 0x3f5, 0x3f6, 0x3f7)
cdef tuple FDC_SECOND_READ_PORTS = (0x370, 0x371, 0x372, 0x373, 0x374, 0x375, 0x376, 0x377)
cdef tuple FDC_FIRST_WRITE_PORTS = (0x3f2, 0x3f3, 0x3f4, 0x3f5, 0x3f6, 0x3f7)
cdef tuple FDC_SECOND_WRITE_PORTS = (0x372, 0x373, 0x374, 0x375, 0x376, 0x377)



DEF FDC_FIRST_PORTBASE  = 0x3f0
DEF FDC_SECOND_PORTBASE = 0x370
DEF FDC_PORTCOUNT       = 7
DEF FDC_DMA_CHANNEL     = 2

DEF FLOPPY_DISK_TYPE_NONE  = 0
DEF FLOPPY_DISK_TYPE_360K  = 1
DEF FLOPPY_DISK_TYPE_1_2M  = 2
DEF FLOPPY_DISK_TYPE_720K  = 3
DEF FLOPPY_DISK_TYPE_1_44M = 4
DEF FLOPPY_DISK_TYPE_2_88M = 5

DEF SIZE_360K = 368640
DEF SIZE_720K = 737280
DEF SIZE_1_2M = 1228800
DEF SIZE_1_44M = 1474560
DEF SIZE_2_88M = 2867200


DEF PIC_PIC1_COMMAND = 0x20
DEF PIC_PIC1_DATA = PIC_PIC1_COMMAND+1
DEF PIC_PIC2_COMMAND = 0xA0
DEF PIC_PIC2_DATA = PIC_PIC2_COMMAND+1
cdef tuple PIC_PIC1_PORTS = (PIC_PIC1_COMMAND, PIC_PIC1_DATA)
cdef tuple PIC_PIC2_PORTS = (PIC_PIC2_COMMAND, PIC_PIC2_DATA)

DEF PIC_MASTER = 0
DEF PIC_SLAVE  = 1
DEF PIC_GET_ICW4 = 0x01
DEF PIC_SINGLE_MODE_NO_ICW3 = 0x02
DEF PIC_CMD_INITIALIZE = 0x10
DEF PIC_EOI = 0x20
DEF PIC_DATA_STEP_ICW1 = 1
DEF PIC_DATA_STEP_ICW2 = 2
DEF PIC_DATA_STEP_ICW3 = 3
DEF PIC_DATA_STEP_ICW4 = 4
DEF PIC_FLAG_80x86 = 0x1
DEF PIC_FLAG_AUTO_EOI = 0x2
DEF PIC_NEED_IRR = 1
DEF PIC_NEED_ISR = 2




