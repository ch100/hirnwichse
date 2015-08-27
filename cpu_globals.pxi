

DEF CPU_REGISTER_RAX = 0
DEF CPU_REGISTER_EAX = 0
DEF CPU_REGISTER_AX = 0
DEF CPU_REGISTER_AH = 0
DEF CPU_REGISTER_AL = 0
DEF CPU_REGISTER_RCX = 1
DEF CPU_REGISTER_ECX = 1
DEF CPU_REGISTER_CX = 1
DEF CPU_REGISTER_CH = 1
DEF CPU_REGISTER_CL = 1
DEF CPU_REGISTER_RDX = 2
DEF CPU_REGISTER_EDX = 2
DEF CPU_REGISTER_DX = 2
DEF CPU_REGISTER_DH = 2
DEF CPU_REGISTER_DL = 2
DEF CPU_REGISTER_RBX = 3
DEF CPU_REGISTER_EBX = 3
DEF CPU_REGISTER_BX = 3
DEF CPU_REGISTER_BH = 3
DEF CPU_REGISTER_BL = 3
DEF CPU_REGISTER_RSP = 4
DEF CPU_REGISTER_ESP = 4
DEF CPU_REGISTER_SP = 4
DEF CPU_REGISTER_RBP = 5
DEF CPU_REGISTER_EBP = 5
DEF CPU_REGISTER_BP = 5
DEF CPU_REGISTER_RSI = 6
DEF CPU_REGISTER_ESI = 6
DEF CPU_REGISTER_SI = 6
DEF CPU_REGISTER_RDI = 7
DEF CPU_REGISTER_EDI = 7
DEF CPU_REGISTER_DI = 7
DEF CPU_REGISTER_RIP = 8
DEF CPU_REGISTER_EIP = 8
DEF CPU_REGISTER_IP = 8
DEF CPU_REGISTER_RFLAGS = 9
DEF CPU_REGISTER_EFLAGS = 9
DEF CPU_REGISTER_FLAGS = 9

DEF CPU_SEGMENT_BASE = 10
DEF CPU_SEGMENT_CS  = 1 # 11
DEF CPU_SEGMENT_SS  = 2 # 12
DEF CPU_SEGMENT_DS  = 3 # 13
DEF CPU_SEGMENT_ES  = 4 # 14
DEF CPU_SEGMENT_FS  = 5 # 15
DEF CPU_SEGMENT_GS  = 6 # 16
DEF CPU_SEGMENT_TSS = 7 # 17


DEF CPU_REGISTER_CR0 = 18
DEF CPU_REGISTER_CR2 = 19
DEF CPU_REGISTER_CR3 = 20
DEF CPU_REGISTER_CR4 = 21

DEF CPU_REGISTER_DR0 = 22
DEF CPU_REGISTER_DR1 = 23
DEF CPU_REGISTER_DR2 = 24
DEF CPU_REGISTER_DR3 = 25
DEF CPU_REGISTER_DR6 = 26
DEF CPU_REGISTER_DR7 = 27

DEF CPU_REGISTER_NONE = 28

DEF CPU_REGISTERS = 29

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

DEF FLAG_CF_ZF = FLAG_CF | FLAG_ZF
DEF FLAG_SF_OF = FLAG_SF | FLAG_OF
DEF FLAG_SF_OF_ZF = FLAG_SF | FLAG_OF | FLAG_ZF

#DEF RESERVED_FLAGS_BITMASK = 0xffc0802a
cdef unsigned int RESERVED_FLAGS_BITMASK = 0xffc0802a
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
#cdef unsigned int CR0_FLAG_NW = 0x20000000
#cdef unsigned int CR0_FLAG_CD = 0x40000000
#cdef unsigned int CR0_FLAG_PG = 0x80000000


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


DEF REG_TYPE_LOW_BYTE = 1
DEF REG_TYPE_HIGH_BYTE = 2
DEF REG_TYPE_WORD = 3
DEF REG_TYPE_DWORD = 4
DEF REG_TYPE_QWORD = 5

cdef unsigned char CPU_REGISTER_SREG[9]
CPU_REGISTER_SREG = (CPU_SEGMENT_ES,CPU_SEGMENT_CS,CPU_SEGMENT_SS,CPU_SEGMENT_DS,CPU_SEGMENT_FS,CPU_SEGMENT_GS, \
                                CPU_REGISTER_NONE, CPU_REGISTER_NONE, CPU_SEGMENT_TSS)
cdef unsigned char CPU_REGISTER_CREG[8]
CPU_REGISTER_CREG = (CPU_REGISTER_CR0, CPU_REGISTER_NONE, CPU_REGISTER_CR2, CPU_REGISTER_CR3, CPU_REGISTER_CR4, \
                                CPU_REGISTER_NONE, CPU_REGISTER_NONE, CPU_REGISTER_NONE)
cdef unsigned char CPU_REGISTER_DREG[8]
CPU_REGISTER_DREG = (CPU_REGISTER_DR0, CPU_REGISTER_DR1, CPU_REGISTER_DR2, CPU_REGISTER_DR3, CPU_REGISTER_DR6, \
                                CPU_REGISTER_DR7, CPU_REGISTER_DR6, CPU_REGISTER_DR7)

cdef unsigned char CPU_MODRM_16BIT_RM0[8]
CPU_MODRM_16BIT_RM0 = (CPU_REGISTER_RBX, CPU_REGISTER_RBX, CPU_REGISTER_RBP, CPU_REGISTER_RBP, CPU_REGISTER_RSI, \
                                  CPU_REGISTER_RDI, CPU_REGISTER_RBP, CPU_REGISTER_RBX)

cdef unsigned char CPU_MODRM_16BIT_RM1[8]
CPU_MODRM_16BIT_RM1 = (CPU_REGISTER_RSI, CPU_REGISTER_RDI, CPU_REGISTER_RSI, CPU_REGISTER_RDI, CPU_REGISTER_NONE, \
                                  CPU_REGISTER_NONE, CPU_REGISTER_NONE, CPU_REGISTER_NONE)


DEF GDT_USE_LDT = 0x4
DEF GDT_FLAG_USE_4K = 0x8
DEF GDT_FLAG_SIZE = 0x4 # 0==16bit; 1==32bit
DEF GDT_FLAG_LONGMODE = 0x2
DEF GDT_FLAG_AVAILABLE = 0x1

DEF GDT_ACCESS_ACCESSED = 0x1
DEF GDT_ACCESS_READABLE_WRITABLE = 0x2 # segment readable/writable
DEF GDT_ACCESS_CONFORMING = 0x4
DEF GDT_ACCESS_EXECUTABLE = 0x8 # 1==code segment; 0==data segment
DEF GDT_ACCESS_NORMAL_SEGMENT = 0x10 # 1==code/data segment; 0==system segment
DEF GDT_ACCESS_DPL = 0x60
DEF GDT_ACCESS_PRESENT = 0x80

DEF TABLE_ENTRY_SYSTEM_TYPE_16BIT_TSS = 0x1
DEF TABLE_ENTRY_SYSTEM_TYPE_LDT = 0x2
DEF TABLE_ENTRY_SYSTEM_TYPE_16BIT_TSS_BUSY = 0x3
DEF TABLE_ENTRY_SYSTEM_TYPE_16BIT_CALL_GATE = 0x4
DEF TABLE_ENTRY_SYSTEM_TYPE_TASK_GATE = 0x5
DEF TABLE_ENTRY_SYSTEM_TYPE_16BIT_INTERRUPT_GATE = 0x6
DEF TABLE_ENTRY_SYSTEM_TYPE_16BIT_TRAP_GATE = 0x7
DEF TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS = 0x9
DEF TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS_BUSY = 0xb
DEF TABLE_ENTRY_SYSTEM_TYPE_32BIT_CALL_GATE = 0xc
DEF TABLE_ENTRY_SYSTEM_TYPE_32BIT_INTERRUPT_GATE = 0xe
DEF TABLE_ENTRY_SYSTEM_TYPE_32BIT_TRAP_GATE = 0xf
DEF TABLE_ENTRY_SYSTEM_TYPE_MASK = 0x1f
DEF TABLE_ENTRY_SYSTEM_TYPE_MASK_WITHOUT_BUSY = 0x1d


DEF SELECTOR_USE_LDT = 0x4

DEF GDT_HARD_LIMIT = 0xffff
DEF IDT_HARD_LIMIT = 0xffff
DEF TSS_MIN_16BIT_HARD_LIMIT = 0x2b
DEF TSS_MIN_32BIT_HARD_LIMIT = 0x67



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


DEF CPU_EXCEPTIONS_FAULT_GROUP = (CPU_EXCEPTION_DE, CPU_EXCEPTION_BR, CPU_EXCEPTION_UD, CPU_EXCEPTION_NM, CPU_EXCEPTION_TS, \
                        CPU_EXCEPTION_NP, CPU_EXCEPTION_SS, CPU_EXCEPTION_GP, CPU_EXCEPTION_PF, CPU_EXCEPTION_MF, \
                        CPU_EXCEPTION_AC, CPU_EXCEPTION_XF)

### TODO: CPU_EXCEPTION_DB is FAULT/TRAP
DEF CPU_EXCEPTIONS_TRAP_GROUP = (CPU_EXCEPTION_DB, CPU_EXCEPTION_BP, CPU_EXCEPTION_OF)

DEF CPU_EXCEPTIONS_WITH_ERRORCODE = (CPU_EXCEPTION_DF, CPU_EXCEPTION_TS, CPU_EXCEPTION_NP, CPU_EXCEPTION_SS, \
                                 CPU_EXCEPTION_GP, CPU_EXCEPTION_PF, CPU_EXCEPTION_AC)


DEF OPCODE_PREFIX_CS=0x2e
DEF OPCODE_PREFIX_SS=0x36
DEF OPCODE_PREFIX_DS=0x3e
DEF OPCODE_PREFIX_ES=0x26
DEF OPCODE_PREFIX_FS=0x64
DEF OPCODE_PREFIX_GS=0x65
DEF OPCODE_PREFIX_SEGMENTS = (OPCODE_PREFIX_CS, OPCODE_PREFIX_SS, OPCODE_PREFIX_DS, OPCODE_PREFIX_ES, OPCODE_PREFIX_FS, OPCODE_PREFIX_GS)
DEF OPCODE_PREFIX_OP=0x66
DEF OPCODE_PREFIX_ADDR=0x67
DEF OPCODE_PREFIX_LOCK=0xf0
DEF OPCODE_PREFIX_REPNE=0xf2
DEF OPCODE_PREFIX_REPE=0xf3
DEF OPCODE_PREFIX_REPS = (OPCODE_PREFIX_REPNE,OPCODE_PREFIX_REPE)


DEF OPCODE_PREFIXES = (OPCODE_PREFIX_OP, OPCODE_PREFIX_ADDR, OPCODE_PREFIX_CS,
                 OPCODE_PREFIX_SS, OPCODE_PREFIX_DS, OPCODE_PREFIX_ES, OPCODE_PREFIX_FS,
                 OPCODE_PREFIX_GS, OPCODE_PREFIX_REPNE, OPCODE_PREFIX_REPE, OPCODE_PREFIX_LOCK)


DEF OPCODE_SAVE = 0
DEF OPCODE_ADD  = 1
DEF OPCODE_ADC  = 2
DEF OPCODE_SUB  = 3
DEF OPCODE_SBB  = 4
DEF OPCODE_CMP  = 5
DEF OPCODE_AND  = 6
DEF OPCODE_OR   = 7
DEF OPCODE_XOR  = 8
DEF OPCODE_TEST = 9
DEF OPCODE_NEG  = 10
DEF OPCODE_NOT  = 11
DEF OPCODE_MUL  = 12
DEF OPCODE_IMUL = 13
DEF OPCODE_DIV  = 14
DEF OPCODE_IDIV = 15
DEF OPCODE_JUMP = 16
DEF OPCODE_CALL = 17

#DEF CPU_CLOCK_TICK_SHIFT = 8
#DEF CPU_CLOCK_TICK_SHIFT = 4
DEF CPU_CLOCK_TICK_SHIFT = 0
DEF CPU_CLOCK_TICK = 1<<CPU_CLOCK_TICK_SHIFT

DEF PAGE_PRESENT = 0x1
DEF PAGE_WRITABLE = 0x2
DEF PAGE_EVERY_RING = 0x4 # allow access from every ring
DEF PAGE_WRITE_THROUGH_CACHING = 0x8
DEF PAGE_NO_CACHING = 0x10
DEF PAGE_WAS_USED = 0x20
DEF PAGE_WRITTEN_ON_PAGE = 0x40 # if page_directory: set it on write access at 4MB pages;; if page_table: set it on write access
DEF PAGE_SIZE = 0x80
DEF PAGE_GLOBAL = 0x100
DEF PAGE_DIRECTORY_LENGTH = 0x1000
DEF PAGE_DIRECTORY_ENTRIES = 0x400
DEF TLB_SIZE = 0x400000


DEF TSS_PREVIOUS_TASK_LINK = 0x00
DEF TSS_16BIT_SP0 = 0x02
DEF TSS_16BIT_SS0  = 0x04
DEF TSS_16BIT_SP1 = 0x06
DEF TSS_16BIT_SS1  = 0x08
DEF TSS_16BIT_SP2 = 0x0a
DEF TSS_16BIT_SS2  = 0x0c
DEF TSS_16BIT_IP  = 0x0e
DEF TSS_16BIT_FLAGS = 0x10
DEF TSS_16BIT_AX  = 0x12
DEF TSS_16BIT_CX  = 0x14
DEF TSS_16BIT_DX  = 0x16
DEF TSS_16BIT_BX  = 0x18
DEF TSS_16BIT_SP  = 0x1a
DEF TSS_16BIT_BP  = 0x1c
DEF TSS_16BIT_SI  = 0x1e
DEF TSS_16BIT_DI  = 0x20
DEF TSS_16BIT_ES   = 0x22
DEF TSS_16BIT_CS   = 0x24
DEF TSS_16BIT_SS   = 0x26
DEF TSS_16BIT_DS   = 0x28
DEF TSS_16BIT_LDT_SEG_SEL = 0x2a


DEF TSS_32BIT_ESP0 = 0x04
DEF TSS_32BIT_SS0  = 0x08
DEF TSS_32BIT_ESP1 = 0x0C
DEF TSS_32BIT_SS1  = 0x10
DEF TSS_32BIT_ESP2 = 0x14
DEF TSS_32BIT_SS2  = 0x18
DEF TSS_32BIT_CR3  = 0x1c
DEF TSS_32BIT_EIP  = 0x20
DEF TSS_32BIT_EFLAGS = 0x24
DEF TSS_32BIT_EAX  = 0x28
DEF TSS_32BIT_ECX  = 0x2c
DEF TSS_32BIT_EDX  = 0x30
DEF TSS_32BIT_EBX  = 0x34
DEF TSS_32BIT_ESP  = 0x38
DEF TSS_32BIT_EBP  = 0x3c
DEF TSS_32BIT_ESI  = 0x40
DEF TSS_32BIT_EDI  = 0x44
DEF TSS_32BIT_ES   = 0x48
DEF TSS_32BIT_CS   = 0x4c
DEF TSS_32BIT_SS   = 0x50
DEF TSS_32BIT_DS   = 0x54
DEF TSS_32BIT_FS   = 0x58
DEF TSS_32BIT_GS   = 0x5c
DEF TSS_32BIT_LDT_SEG_SEL = 0x60
DEF TSS_32BIT_T_FLAG = 0x64
DEF TSS_32BIT_IOMAP_BASE_ADDR = 0x66


#DEF CPU_CACHE_SIZE = 16*1024 # in bytes
DEF CPU_CACHE_SIZE = 0 # in bytes



