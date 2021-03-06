
#cython: language_level=3, boundscheck=False, wraparound=False, cdivision=True, profile=False, c_string_type=bytes

include "globals.pxi"
include "cpu_globals.pxi"

from cpu import HirnwichseException
import gmpy2, struct
from traceback import print_exc
from atexit import register

# Parity Flag Table: DO NOT EDIT!!!
cdef uint8_t PARITY_TABLE[256]
PARITY_TABLE = (True, False, False, True, False, True, True, False, False, True,
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



cdef class ModRMClass:
    def __init__(self, Registers registers):
        self.registers = registers
    cdef uint8_t modRMOperands(self, uint8_t regSize, uint8_t modRMflags) except BITMASK_BYTE_CONST: # regSize in bytes
        cdef uint8_t modRMByte, reg
        modRMByte = self.registers.getCurrentOpcodeAddUnsignedByte()
        #self.rmNameSeg = &self.registers.segments.ds
        #self.rmName1 = CPU_REGISTER_NONE
        self.rm  = modRMByte&0x7
        self.reg = (modRMByte>>3)&0x7
        self.mod = (modRMByte>>6)&0x3
        #self.ss = 0
        reg = self.reg
        if (modRMflags == MODRM_FLAGS_SREG):
            reg = CPU_REGISTER_SREG[reg]
            if (reg == CPU_REGISTER_NONE):
                raise HirnwichseException(CPU_EXCEPTION_UD)
        elif (modRMflags == MODRM_FLAGS_CREG):
            reg = CPU_REGISTER_CREG[reg]
            if (reg == CPU_REGISTER_NONE):
                raise HirnwichseException(CPU_EXCEPTION_UD)
        elif (modRMflags == MODRM_FLAGS_DREG):
            if (reg in (4, 5)):
                if (self.registers.getFlagDword(CPU_REGISTER_CR4, CR4_FLAG_DE) != 0):
                    raise HirnwichseException(CPU_EXCEPTION_UD)
                else:
                    reg += 2
            reg = CPU_REGISTER_DREG[reg]
        elif (regSize == OP_SIZE_BYTE):
            reg &= 3
        self.regName = reg
        if (self.mod == 3): # if mod==3, then: reg is source ; rm is dest
            self.regSize = regSize
            self.rmName0 = self.rm # rm
            if (regSize == OP_SIZE_BYTE):
                self.rmName0 &= 3
            self.rmName2 = 0
            self.ss = 0
            self.rmName1 = CPU_REGISTER_NONE
            self.rmNameSeg = &self.registers.segments.ds
        else:
            self.regSize = self.registers.main.cpu.addrSize
            if (self.regSize == OP_SIZE_WORD):
                self.rmName0 = CPU_MODRM_16BIT_RM0[self.rm]
                self.rmName1 = CPU_MODRM_16BIT_RM1[self.rm]
                if (self.mod == 0 and self.rm == 6):
                    self.rmName0 = CPU_REGISTER_NONE
                    self.rmName2 = self.registers.getCurrentOpcodeAddUnsignedWord()
                elif (self.mod == 1):
                    self.rmName2 = <uint16_t>(<int8_t>self.registers.getCurrentOpcodeAddUnsignedByte())
                elif (self.mod == 2):
                    self.rmName2 = self.registers.getCurrentOpcodeAddUnsignedWord()
                else:
                    self.rmName2 = 0
                self.ss = 0
            else: #elif (self.regSize == OP_SIZE_DWORD):
                if (self.rm == 4): # If RM==4; then SIB
                    modRMByte = self.registers.getCurrentOpcodeAddUnsignedByte()
                    self.rm  = modRMByte&0x7
                    self.ss = (modRMByte>>6)&3
                    modRMByte   = (modRMByte>>3)&7
                    if (modRMByte != 4):
                        self.rmName1 = modRMByte
                    else:
                        self.rmName1 = CPU_REGISTER_NONE
                else:
                    self.ss = 0
                    self.rmName1 = CPU_REGISTER_NONE
                self.rmName0 = self.rm
                if (self.mod == 0 and self.rm == 5):
                    self.rmName0 = CPU_REGISTER_NONE
                    self.rmName2 = self.registers.getCurrentOpcodeAddUnsignedDword()
                elif (self.mod == 1):
                    self.rmName2 = <uint32_t>(<int8_t>self.registers.getCurrentOpcodeAddUnsignedByte())
                elif (self.mod == 2):
                    self.rmName2 = self.registers.getCurrentOpcodeAddUnsignedDword()
                else:
                    self.rmName2 = 0
            if (self.rmName0 in (CPU_REGISTER_ESP, CPU_REGISTER_EBP)): # on 16-bit modrm, there's no SP
                self.rmNameSeg = &self.registers.segments.ss
            else:
                self.rmNameSeg = &self.registers.segments.ds
        return True
    cdef uint64_t getRMValueFull(self, uint8_t rmSize):
        cdef uint64_t retAddr = 0
        if (self.rmName0 != CPU_REGISTER_NONE):
            if (self.regSize == OP_SIZE_BYTE):
                if (self.rm <= 3):
                    retAddr = self.registers.regs[self.rmName0]._union.word._union.byte.rl
                else: #elif (self.rm >= 4):
                    retAddr = self.registers.regs[self.rmName0]._union.word._union.byte.rh
            elif (self.regSize == OP_SIZE_WORD):
                retAddr = self.registers.regs[self.rmName0]._union.word._union.rx
            elif (self.regSize == OP_SIZE_DWORD):
                retAddr = self.registers.regs[self.rmName0]._union.dword.erx
            elif (self.regSize == OP_SIZE_QWORD):
                retAddr = self.registers.regs[self.rmName0]._union.rrx
        if (self.rmName1 != CPU_REGISTER_NONE):
            retAddr += self.registers.regReadUnsigned(self.rmName1, self.regSize)<<self.ss
        retAddr += self.rmName2
        if (rmSize == OP_SIZE_BYTE):
            return <uint8_t>retAddr
        elif (rmSize == OP_SIZE_WORD):
            return <uint16_t>retAddr
        elif (rmSize == OP_SIZE_DWORD):
            return <uint32_t>retAddr
        return retAddr
    cdef int64_t modRMLoadSigned(self, uint8_t regSize) except? BITMASK_BYTE_CONST:
        # NOTE: imm == unsigned ; disp == signed
        cdef uint64_t mmAddr
        if (self.mod == 3):
            if (regSize == OP_SIZE_BYTE):
                if (self.rm <= 3):
                    return <int8_t>self.registers.regs[self.rmName0]._union.word._union.byte.rl
                else: #elif (self.rm >= 4):
                    return <int8_t>self.registers.regs[self.rmName0]._union.word._union.byte.rh
            elif (regSize == OP_SIZE_WORD):
                return <int16_t>self.registers.regs[self.rmName0]._union.word._union.rx
            elif (regSize == OP_SIZE_DWORD):
                return <int32_t>self.registers.regs[self.rmName0]._union.dword.erx
            #else: #elif (regSize == OP_SIZE_QWORD):
            return <int64_t>self.registers.regs[self.rmName0]._union.rrx
        else:
            mmAddr = self.getRMValueFull(self.regSize)
            if (regSize == OP_SIZE_BYTE):
                return <int8_t>self.registers.mmReadValueUnsignedByte(mmAddr, self.rmNameSeg, True)
            elif (regSize == OP_SIZE_WORD):
                return <int16_t>self.registers.mmReadValueUnsignedWord(mmAddr, self.rmNameSeg, True)
            elif (regSize == OP_SIZE_DWORD):
                return <int32_t>self.registers.mmReadValueUnsignedDword(mmAddr, self.rmNameSeg, True)
            #else: #elif (regSize == OP_SIZE_QWORD):
            return <int64_t>self.registers.mmReadValueUnsignedQword(mmAddr, self.rmNameSeg, True)
    cdef uint64_t modRMLoadUnsigned(self, uint8_t regSize) except? BITMASK_BYTE_CONST:
        # NOTE: imm == unsigned ; disp == signed
        cdef uint64_t mmAddr
        if (self.mod == 3):
            if (regSize == OP_SIZE_BYTE):
                if (self.rm <= 3):
                    return self.registers.regs[self.rmName0]._union.word._union.byte.rl
                else: #elif (self.rm >= 4):
                    return self.registers.regs[self.rmName0]._union.word._union.byte.rh
            elif (regSize == OP_SIZE_WORD):
                return self.registers.regs[self.rmName0]._union.word._union.rx
            elif (regSize == OP_SIZE_DWORD):
                return self.registers.regs[self.rmName0]._union.dword.erx
            #else: #elif (regSize == OP_SIZE_QWORD):
            return self.registers.regs[self.rmName0]._union.rrx
        else:
            mmAddr = self.getRMValueFull(self.regSize)
            if (regSize == OP_SIZE_BYTE):
                return self.registers.mmReadValueUnsignedByte(mmAddr, self.rmNameSeg, True)
            elif (regSize == OP_SIZE_WORD):
                return self.registers.mmReadValueUnsignedWord(mmAddr, self.rmNameSeg, True)
            elif (regSize == OP_SIZE_DWORD):
                return self.registers.mmReadValueUnsignedDword(mmAddr, self.rmNameSeg, True)
            #else: #elif (regSize == OP_SIZE_QWORD):
            return self.registers.mmReadValueUnsignedQword(mmAddr, self.rmNameSeg, True)
    cdef uint8_t modRMSave(self, uint8_t regSize, uint64_t value, uint8_t valueOp) except BITMASK_BYTE_CONST:
        # stdValueOp==OPCODE_SAVE
        cdef uint64_t mmAddr = 0
        if (self.mod != 3):
            mmAddr = self.getRMValueFull(self.regSize)
        if (regSize == OP_SIZE_BYTE):
            if (self.mod == 3):
                if (self.rm <= 3):
                    self.registers.regWriteWithOpLowByte(self.rmName0, value, valueOp)
                else: # self.rm >= 4
                    self.registers.regWriteWithOpHighByte(self.rmName0, value, valueOp)
            else:
                self.registers.mmWriteValueWithOp(mmAddr, <uint8_t>value, regSize, self.rmNameSeg, True, valueOp)
        elif (regSize == OP_SIZE_WORD):
            if (self.mod == 3):
                self.registers.regWriteWithOpWords(self.rmName0, <uint16_t>value, valueOp)
            else:
                self.registers.mmWriteValueWithOp(mmAddr, <uint16_t>value, regSize, self.rmNameSeg, True, valueOp)
        elif (regSize == OP_SIZE_DWORD):
            if (self.mod == 3):
                self.registers.regWriteWithOpWords(self.rmName0, <uint32_t>value, valueOp)
            else:
                self.registers.mmWriteValueWithOp(mmAddr, <uint32_t>value, regSize, self.rmNameSeg, True, valueOp)
        else: #elif (regSize == OP_SIZE_QWORD):
            if (self.mod == 3):
                self.registers.regWriteWithOpWords(self.rmName0, <uint64_t>value, valueOp)
            else:
                self.registers.mmWriteValueWithOp(mmAddr, value, regSize, self.rmNameSeg, True, valueOp)
        #self.registers.main.exitError("ModRMClass::modRMSave: if; else.")
        return True
    cdef int64_t modRLoadSigned(self, uint8_t regSize):
        if (regSize == OP_SIZE_BYTE):
            if (self.reg <= 3):
                return <int8_t>self.registers.regs[self.regName]._union.word._union.byte.rl
            else: #elif (self.reg >= 4):
                return <int8_t>self.registers.regs[self.regName]._union.word._union.byte.rh
        elif (regSize == OP_SIZE_WORD):
            return <int16_t>self.registers.regs[self.regName]._union.word._union.rx
        elif (regSize == OP_SIZE_DWORD):
            return <int32_t>self.registers.regs[self.regName]._union.dword.erx
        #else: #elif (regSize == OP_SIZE_QWORD):
        return <int64_t>self.registers.regs[self.regName]._union.rrx
    cdef uint64_t modRLoadUnsigned(self, uint8_t regSize):
        if (regSize == OP_SIZE_BYTE):
            if (self.reg <= 3):
                return self.registers.regs[self.regName]._union.word._union.byte.rl
            else: #elif (self.reg >= 4):
                return self.registers.regs[self.regName]._union.word._union.byte.rh
        elif (regSize == OP_SIZE_WORD):
            return self.registers.regs[self.regName]._union.word._union.rx
        elif (regSize == OP_SIZE_DWORD):
            return self.registers.regs[self.regName]._union.dword.erx
        #else: #elif (regSize == OP_SIZE_QWORD):
        return self.registers.regs[self.regName]._union.rrx
    cdef void modRSave(self, uint8_t_uint16_t_uint32_t_uint64_t value, uint8_t valueOp):
        if (uint8_t_uint16_t_uint32_t_uint64_t is uint8_t):
            if (self.reg <= 3):
                self.registers.regWriteWithOpLowByte(self.regName, value, valueOp)
            else: #elif (self.reg >= 4):
                self.registers.regWriteWithOpHighByte(self.regName, value, valueOp)
        else:
            self.registers.regWriteWithOpWords(self.regName, value, valueOp)


cdef class Fpu:
    def __init__(self, Registers registers, Hirnwichse main):
        self.registers = registers
        self.main = main
        self.st = [None]*8
        #self.opcode = 0
    cdef void reset(self, uint8_t fninit):
        cdef uint8_t i
        if (fninit):
            self.setCtrl(0x37f)
            self.tag = 0xffff
        else:
            for i in range(8):
                self.st[i] = bytes(10)
            self.setCtrl(0x40)
            self.tag = 0x5555
        self.status = 0
        self.dataSeg = self.instSeg = 0
        self.dataPointer = self.instPointer = 0
        self.opcode = 0 # TODO: should this get cleared?
    cdef inline uint8_t getPrecision(self):
        return FPU_PRECISION[(self.ctrl>>8)&3]
    cdef inline void setPrecision(self):
        gmpy2.get_context().precision=self.getPrecision()
    cdef inline void setCtrl(self, uint16_t ctrl):
        self.ctrl = ctrl
        self.setPrecision()
    cdef inline void setPointers(self, uint16_t opcode):
        self.opcode = opcode
        self.instSeg = self.main.cpu.savedCs
        self.instPointer = self.main.cpu.savedEip
    cdef inline void setDataPointers(self, uint16_t dataSeg, uint32_t dataPointer):
        self.dataSeg = dataSeg
        self.dataPointer = dataPointer
    cdef inline void setTag(self, uint16_t index, uint8_t tag):
        index <<= 1
        self.tag &= ~(3<<index)
        self.tag |= tag<<index
    cdef inline void setFlag(self, uint16_t index, uint8_t flag):
        index = 1<<index
        if (flag):
            self.status |= index
        else:
            self.status &= ~index
    cdef inline void setExc(self, uint16_t index, uint8_t flag):
        self.setFlag(index, flag)
        index = 1<<index
        if (flag and (self.ctrl & index) != 0):
            self.setFlag(FPU_EXCEPTION_ES, True)
    cdef inline void setC(self, uint16_t index, uint8_t flag):
        if (index < 3):
            index = 8+index
        else:
            index = 14
        self.setFlag(index, flag)
    cdef inline uint8_t getIndex(self, uint8_t index):
        return (((self.status >> 11) & 7) + index) & 7
    cdef inline void addTop(self, int8_t index):
        cdef char tempIndex
        tempIndex = (self.status >> 11) & 7
        self.status &= ~(7 << 11)
        tempIndex += index
        self.status |= (tempIndex & 7) << 11
    cdef inline void setVal(self, uint8_t tempIndex, object data, uint8_t setFlags): # load
        cdef int32_t tempVal
        cdef tuple tempTuple
        cdef bytes tempData
        data = gmpy2.mpfr(data)
        #self.main.notice("Fpu::setVal: data==%s", repr(data))
        tempIndex = self.getIndex(tempIndex)
        if (not gmpy2.is_zero(data)):
            tempTuple = data.as_integer_ratio()
            tempVal = (tempTuple[0].bit_length()-tempTuple[1].bit_length())
            tempVal = <uint16_t>(tempVal+16383)
            if (gmpy2.is_signed(data)):
                tempVal |= 0x8000
            tempData = (gmpy2.to_binary(data))[:11:-1]
            self.st[tempIndex] = tempVal.to_bytes(OP_SIZE_WORD, byteorder="big")+tempData
        else:
            self.st[tempIndex] = bytes(10)
        #self.main.notice("Fpu::setVal: tempIndex==%u, len(st[ti])==%u, repr(st[ti]==%s)", tempIndex, len(self.st[tempIndex]), repr(self.st[tempIndex]))
        if (gmpy2.is_zero(data)):
            self.setTag(tempIndex, 1)
        elif (not gmpy2.is_regular(data)):
            self.setTag(tempIndex, 2)
        else:
            self.setTag(tempIndex, 0)
        if (setFlags):
            if (data.rc != 0):
                self.setExc(FPU_EXCEPTION_PE, True)
            self.setC(1, data.rc > 0)
    cdef inline object getVal(self, uint8_t tempIndex): # store
        cdef uint8_t negative, info_byte
        cdef uint32_t exp
        cdef object data
        tempIndex = self.getIndex(tempIndex)
        #self.main.notice("Fpu::getVal: tempIndex==%u, len(st[ti])==%u, repr(st[ti]==%s)", tempIndex, len(self.st[tempIndex]), repr(self.st[tempIndex]))
        if (self.st[tempIndex] == bytes(10)):
            return gmpy2.mpfr(0)
        exp = int.from_bytes(self.st[tempIndex][:2],byteorder="big")
        negative = (exp & 0x8000) != 0
        exp &= <uint16_t>(~(<uint16_t>0x8000))
        exp = <uint16_t>((exp-16383)+1)
        if (negative):
            info_byte = 0x43
        else:
            info_byte = 0x41
        if (exp >= 0x8000):
            exp = 0x10000 - exp
            info_byte |= 0x20
        data = gmpy2.from_binary(b"\x04"+bytes([ info_byte ])+b"\x00\x00"+bytes([self.getPrecision()])+b"\x00\x00\x00"+struct.pack("<I", exp)+self.st[tempIndex][9:1:-1])
        #self.main.notice("Fpu::getVal: data==%s", repr(data))
        return data
    cdef inline void push(self, object data, uint8_t setFlags): # load
        self.addTop(-1)
        self.setVal(0, data, setFlags)
    cdef inline object pop(self): # store
        cdef object data
        data = self.getVal(0)
        self.setTag(self.getIndex(0), 3)
        self.addTop(1)
        return data
    cdef void run(self):
        pass


cdef class Registers:
    def __init__(self, Hirnwichse main):
        self.main = main
        self.segments = Segments(self, self.main)
        self.fpu = Fpu(self, self.main)
        IF CPU_CACHE_SIZE:
            with nogil:
                self.cpuCache = <char*>malloc(CPU_CACHE_SIZE+OP_SIZE_QWORD)
            if (self.cpuCache is NULL):
                self.main.exitError("Registers::init: not self.cpuCache.")
                return
            with nogil:
                memset(self.cpuCache, 0, CPU_CACHE_SIZE+OP_SIZE_QWORD)
        self.A20Active = False
        self.regWriteDword(CPU_REGISTER_CR0, CR0_FLAG_CD | CR0_FLAG_NW | CR0_FLAG_ET)
        register(self.quitFunc, self)
    cdef void quitFunc(self):
        try:
            self.main.quitFunc()
            IF CPU_CACHE_SIZE:
                if (self.cpuCache is not NULL):
                    with nogil:
                        free(self.cpuCache)
                    self.cpuCache = NULL
        except:
            print_exc()
            self.main.exitError('Registers::quitFunc: exception, exiting...')
    cdef void reset(self):
        self.cpl = self.protectedModeOn = self.pagingOn = self.writeProtectionOn = self.ssInhibit = self.cacheDisabled = self.cpuCacheBase = self.cpuCacheSize = self.cpuCacheIndex = self.ldtr = self.cpuCacheCodeSegChange = self.ignoreExceptions = 0
        self.apicBase = <uint32_t>0xfee00000|(1<<8)
        self.apicBaseReal = self.apicBase&<uint32_t>0xfffff000
        self.apicBaseRealPlusSize = self.apicBaseReal+SIZE_4KB
        IF CPU_CACHE_SIZE:
            with nogil:
                memset(self.cpuCache, 0, CPU_CACHE_SIZE+OP_SIZE_QWORD)
        #self.regs[CPU_REGISTER_EDX]._union.dword.erx = 0x521
        #self.regs[CPU_REGISTER_EDX]._union.dword.erx = 0x611
        #self.regs[CPU_REGISTER_EDX]._union.dword.erx = 0x631
        self.regs[CPU_REGISTER_EDX]._union.dword.erx = 0x635
        #with gil:
        IF 1:
            self.fpu.reset(False)
            self.regWriteDword(CPU_REGISTER_EFLAGS, FLAG_REQUIRED)
            self.regWriteDword(CPU_REGISTER_CR0, self.getFlagDword(CPU_REGISTER_CR0, CR0_FLAG_CD | CR0_FLAG_NW) | CR0_FLAG_ET)
            #self.regWriteDword(CPU_REGISTER_DR6, <uint32_t>0xffff1ff0) # why has bochs bit 12 set?
            self.regWriteDword(CPU_REGISTER_DR6, <uint32_t>0xffff0ff0)
            self.regWriteDword(CPU_REGISTER_DR7, 0x400)
            self.segWriteSegment(&self.segments.cs, 0xf000)
            self.regWriteDword(CPU_REGISTER_EIP, 0xfff0)
    cdef inline uint8_t checkCache(self, uint32_t mmAddr, uint8_t dataSize) except BITMASK_BYTE_CONST: # called on a memory write; reload cache for self-modifying-code
        cdef uint32_t cpuCacheBasePhy
        IF CPU_CACHE_SIZE:
            self.ignoreExceptions = True
            cpuCacheBasePhy = self.mmGetRealAddr(self.cpuCacheBase, 1, NULL, False, False, False)
            if (not self.ignoreExceptions):
                self.reloadCpuCache()
                return True
            else:
                self.ignoreExceptions = False
            if (self.cpuCacheCodeSegChange or (mmAddr >= cpuCacheBasePhy and mmAddr+dataSize <= cpuCacheBasePhy+self.cpuCacheSize)):
                self.reloadCpuCache()
        return True
    cdef uint8_t reloadCpuCache(self) except BITMASK_BYTE_CONST:
        IF CPU_CACHE_SIZE:
            cdef uint32_t mmAddr, mmAddr2, temp, tempSize=0
            cdef char *tempMmArea
            IF COMP_DEBUG:
                if (self.main.debugEnabled):
                    self.main.notice("Registers::reloadCpuCache: EIP: 0x%08x", self.regs[CPU_REGISTER_EIP]._union.dword.erx)
            mmAddr = self.mmGetRealAddr(self.regs[CPU_REGISTER_EIP]._union.dword.erx, 1, &self.segments.cs, False, False, False)
            if (self.protectedModeOn and self.pagingOn):
                while (tempSize < CPU_CACHE_SIZE):
                    temp = SIZE_4KB-((self.segments.cs.gdtEntry.base+self.regs[CPU_REGISTER_EIP]._union.dword.erx+tempSize)&0xfff)
                    if (tempSize+temp > CPU_CACHE_SIZE):
                        temp = CPU_CACHE_SIZE-tempSize
                    #self.main.notice("Registers::reloadCpuCache: temp==%d", temp)
                    self.ignoreExceptions = True
                    mmAddr2 = self.mmGetRealAddr(self.regs[CPU_REGISTER_EIP]._union.dword.erx+tempSize, temp, &self.segments.cs, False, False, False)
                    if (not self.ignoreExceptions):
                        break
                    else:
                        self.ignoreExceptions = False
                    tempMmArea = self.main.mm.mmPhyRead(mmAddr2, temp)
                    with nogil:
                        memcpy(self.cpuCache+tempSize, tempMmArea, temp)
                    tempSize += temp
                #self.main.notice("Registers::reloadCpuCache: tempSize==%d; CPU_CACHE_SIZE==%d", tempSize, CPU_CACHE_SIZE)
                with nogil:
                    memset(self.cpuCache+tempSize, 0, CPU_CACHE_SIZE-tempSize)
            else:
                tempMmArea = self.main.mm.mmPhyRead(mmAddr, CPU_CACHE_SIZE)
                with nogil:
                    memcpy(self.cpuCache, tempMmArea, CPU_CACHE_SIZE)
                tempSize = CPU_CACHE_SIZE
            with nogil:
                memset(self.cpuCache+CPU_CACHE_SIZE, 0, OP_SIZE_QWORD)
            self.cpuCacheBase = self.segments.cs.gdtEntry.base+self.regs[CPU_REGISTER_EIP]._union.dword.erx
            self.cpuCacheSize = tempSize
            self.cpuCacheIndex = self.cpuCacheCodeSegChange = 0
        return True
    cdef uint64_t readFromCacheAddUnsigned(self, uint8_t numBytes) except? BITMASK_BYTE_CONST:
        IF CPU_CACHE_SIZE:
            cdef uint64_t *retVal
            IF COMP_DEBUG:
                if (self.main.debugEnabled):
                    self.main.notice("Registers::readFromCacheAddUnsigned: cpuCacheIndex: 0x%08x, numBytes: %u", self.cpuCacheIndex, numBytes)
            if (self.cpuCacheIndex+numBytes > self.cpuCacheSize):
                self.reloadCpuCache()
            retVal = <uint64_t*>(self.cpuCache+self.cpuCacheIndex)
            self.cpuCacheIndex += numBytes
            if (numBytes == OP_SIZE_BYTE):
                return <uint8_t>retVal[0]
            elif (numBytes == OP_SIZE_WORD):
                return <uint16_t>retVal[0]
            elif (numBytes == OP_SIZE_DWORD):
                return <uint32_t>retVal[0]
            #else:
            return retVal[0]
        ELSE:
            return 0
    cdef uint64_t readFromCacheUnsigned(self, uint8_t numBytes) except? BITMASK_BYTE_CONST:
        IF CPU_CACHE_SIZE:
            cdef uint64_t *retVal
            if (self.cpuCacheIndex+numBytes > self.cpuCacheSize):
                self.reloadCpuCache()
            retVal = <uint64_t*>(self.cpuCache+self.cpuCacheIndex)
            if (numBytes == OP_SIZE_BYTE):
                return <uint8_t>retVal[0]
            elif (numBytes == OP_SIZE_WORD):
                return <uint16_t>retVal[0]
            elif (numBytes == OP_SIZE_DWORD):
                return <uint32_t>retVal[0]
            #else:
            return retVal[0]
        ELSE:
            return 0
    cdef uint8_t getCurrentOpcodeUnsignedByte(self) except? BITMASK_BYTE_CONST:
        cdef uint8_t ret
        IF (CPU_CACHE_SIZE):
            cdef uint32_t physAddr
        (<Paging>(<Segments>self.segments).paging).instrFetch = True
        IF (CPU_CACHE_SIZE):
            if (self.cacheDisabled):
                ret = self.mmReadValueUnsignedByte(self.regs[CPU_REGISTER_EIP]._union.dword.erx, &self.segments.cs, False)
            else:
                self.mmGetRealAddr(self.regs[CPU_REGISTER_EIP]._union.dword.erx, OP_SIZE_BYTE, &self.segments.cs, False, False, True)
                physAddr = self.segments.cs.gdtEntry.base+self.regs[CPU_REGISTER_EIP]._union.dword.erx
                if (self.protectedModeOn and self.pagingOn and PAGE_DIRECTORY_LENGTH-(physAddr&0xfff) < OP_SIZE_BYTE):
                    self.reloadCpuCache()
                ret = <uint8_t>self.readFromCacheUnsigned(OP_SIZE_BYTE)
        ELSE:
            ret = self.mmReadValueUnsignedByte(self.regs[CPU_REGISTER_EIP]._union.dword.erx, &self.segments.cs, False)
        IF COMP_DEBUG:
            if (self.main.debugEnabled):
                self.main.notice("Registers::getCurrentOpcodeUnsignedByte: EIP: 0x%08x, ret==0x%02x", self.regs[CPU_REGISTER_EIP]._union.dword.erx, ret)
        return ret
    cdef uint8_t getCurrentOpcodeAddUnsignedByte(self) except? BITMASK_BYTE_CONST:
        cdef uint8_t ret
        IF (CPU_CACHE_SIZE):
            cdef uint32_t physAddr
        (<Paging>(<Segments>self.segments).paging).instrFetch = True
        IF (CPU_CACHE_SIZE):
            if (self.cacheDisabled):
                ret = self.mmReadValueUnsignedByte(self.regs[CPU_REGISTER_EIP]._union.dword.erx, &self.segments.cs, False)
            else:
                self.mmGetRealAddr(self.regs[CPU_REGISTER_EIP]._union.dword.erx, OP_SIZE_BYTE, &self.segments.cs, False, False, True)
                physAddr = self.segments.cs.gdtEntry.base+self.regs[CPU_REGISTER_EIP]._union.dword.erx
                if (self.protectedModeOn and self.pagingOn and PAGE_DIRECTORY_LENGTH-(physAddr&0xfff) < OP_SIZE_BYTE):
                    self.reloadCpuCache()
                ret = <uint8_t>self.readFromCacheAddUnsigned(OP_SIZE_BYTE)
        ELSE:
            ret = self.mmReadValueUnsignedByte(self.regs[CPU_REGISTER_EIP]._union.dword.erx, &self.segments.cs, False)
        IF COMP_DEBUG:
            if (self.main.debugEnabled):
                self.main.notice("Registers::getCurrentOpcodeAddUnsignedByte: EIP: 0x%08x, ret==0x%02x", self.regs[CPU_REGISTER_EIP]._union.dword.erx, ret)
        self.regs[CPU_REGISTER_EIP]._union.dword.erx += OP_SIZE_BYTE
        return ret
    cdef uint16_t getCurrentOpcodeAddUnsignedWord(self) except? BITMASK_BYTE_CONST:
        cdef uint16_t ret
        IF (CPU_CACHE_SIZE):
            cdef uint32_t physAddr
        (<Paging>(<Segments>self.segments).paging).instrFetch = True
        IF (CPU_CACHE_SIZE):
            if (self.cacheDisabled):
                ret = self.mmReadValueUnsignedWord(self.regs[CPU_REGISTER_EIP]._union.dword.erx, &self.segments.cs, False)
            else:
                self.mmGetRealAddr(self.regs[CPU_REGISTER_EIP]._union.dword.erx, OP_SIZE_WORD, &self.segments.cs, False, False, True)
                physAddr = self.segments.cs.gdtEntry.base+self.regs[CPU_REGISTER_EIP]._union.dword.erx
                if (self.protectedModeOn and self.pagingOn and PAGE_DIRECTORY_LENGTH-(physAddr&0xfff) < OP_SIZE_WORD):
                    self.reloadCpuCache()
                ret = <uint16_t>self.readFromCacheAddUnsigned(OP_SIZE_WORD)
        ELSE:
            ret = self.mmReadValueUnsignedWord(self.regs[CPU_REGISTER_EIP]._union.dword.erx, &self.segments.cs, False)
        IF COMP_DEBUG:
            if (self.main.debugEnabled):
                self.main.notice("Registers::getCurrentOpcodeAddUnsignedWord: EIP: 0x%08x, ret==0x%02x", self.regs[CPU_REGISTER_EIP]._union.dword.erx, ret)
        self.regs[CPU_REGISTER_EIP]._union.dword.erx += OP_SIZE_WORD
        return ret
    cdef uint32_t getCurrentOpcodeAddUnsignedDword(self) except? BITMASK_BYTE_CONST:
        cdef uint32_t ret
        IF (CPU_CACHE_SIZE):
            cdef uint32_t physAddr
        (<Paging>(<Segments>self.segments).paging).instrFetch = True
        IF (CPU_CACHE_SIZE):
            if (self.cacheDisabled):
                ret = self.mmReadValueUnsignedDword(self.regs[CPU_REGISTER_EIP]._union.dword.erx, &self.segments.cs, False)
            else:
                self.mmGetRealAddr(self.regs[CPU_REGISTER_EIP]._union.dword.erx, OP_SIZE_DWORD, &self.segments.cs, False, False, True)
                physAddr = self.segments.cs.gdtEntry.base+self.regs[CPU_REGISTER_EIP]._union.dword.erx
                if (self.protectedModeOn and self.pagingOn and PAGE_DIRECTORY_LENGTH-(physAddr&0xfff) < OP_SIZE_DWORD):
                    self.reloadCpuCache()
                ret = <uint32_t>self.readFromCacheAddUnsigned(OP_SIZE_DWORD)
        ELSE:
            ret = self.mmReadValueUnsignedDword(self.regs[CPU_REGISTER_EIP]._union.dword.erx, &self.segments.cs, False)
        IF COMP_DEBUG:
            if (self.main.debugEnabled):
                self.main.notice("Registers::getCurrentOpcodeAddUnsignedDword: EIP: 0x%08x, ret==0x%02x", self.regs[CPU_REGISTER_EIP]._union.dword.erx, ret)
        self.regs[CPU_REGISTER_EIP]._union.dword.erx += OP_SIZE_DWORD
        return ret
    cdef uint64_t getCurrentOpcodeAddUnsignedQword(self) except? BITMASK_BYTE_CONST:
        cdef uint64_t ret
        IF (CPU_CACHE_SIZE):
            cdef uint32_t physAddr
        (<Paging>(<Segments>self.segments).paging).instrFetch = True
        IF (CPU_CACHE_SIZE):
            if (self.cacheDisabled):
                ret = self.mmReadValueUnsignedQword(self.regs[CPU_REGISTER_EIP]._union.dword.erx, &self.segments.cs, False)
            else:
                self.mmGetRealAddr(self.regs[CPU_REGISTER_EIP]._union.dword.erx, OP_SIZE_QWORD, &self.segments.cs, False, False, True)
                physAddr = self.segments.cs.gdtEntry.base+self.regs[CPU_REGISTER_EIP]._union.dword.erx
                if (self.protectedModeOn and self.pagingOn and PAGE_DIRECTORY_LENGTH-(physAddr&0xfff) < OP_SIZE_QWORD):
                    self.reloadCpuCache()
                ret = self.readFromCacheAddUnsigned(OP_SIZE_QWORD)
        ELSE:
            ret = self.mmReadValueUnsignedQword(self.regs[CPU_REGISTER_EIP]._union.dword.erx, &self.segments.cs, False)
        IF COMP_DEBUG:
            if (self.main.debugEnabled):
                self.main.notice("Registers::getCurrentOpcodeAddUnsignedQword: EIP: 0x%08x, ret==0x%02x", self.regs[CPU_REGISTER_EIP]._union.dword.erx, ret)
        self.regs[CPU_REGISTER_EIP]._union.dword.erx += OP_SIZE_QWORD
        return ret
    cdef uint64_t getCurrentOpcodeAddUnsigned(self, uint8_t numBytes) except? BITMASK_BYTE_CONST:
        cdef uint64_t ret
        IF (CPU_CACHE_SIZE):
            cdef uint32_t physAddr
        (<Paging>(<Segments>self.segments).paging).instrFetch = True
        IF (CPU_CACHE_SIZE):
            if (self.cacheDisabled):
                ret = self.mmReadValueUnsigned(self.regs[CPU_REGISTER_EIP]._union.dword.erx, numBytes, &self.segments.cs, False)
            else:
                self.mmGetRealAddr(self.regs[CPU_REGISTER_EIP]._union.dword.erx, numBytes, &self.segments.cs, False, False, True)
                physAddr = self.segments.cs.gdtEntry.base+self.regs[CPU_REGISTER_EIP]._union.dword.erx
                if (self.protectedModeOn and self.pagingOn and PAGE_DIRECTORY_LENGTH-(physAddr&0xfff) < numBytes):
                    self.reloadCpuCache()
                ret = self.readFromCacheAddUnsigned(numBytes)
        ELSE:
            ret = self.mmReadValueUnsigned(self.regs[CPU_REGISTER_EIP]._union.dword.erx, numBytes, &self.segments.cs, False)
        IF COMP_DEBUG:
            if (self.main.debugEnabled):
                self.main.notice("Registers::getCurrentOpcodeAddUnsigned: EIP: 0x%08x, ret==0x%02x", self.regs[CPU_REGISTER_EIP]._union.dword.erx, ret)
        self.regs[CPU_REGISTER_EIP]._union.dword.erx += numBytes
        return ret
    cdef inline uint8_t isAddressInLimit(self, GdtEntry *gdtEntry, uint32_t address, uint32_t size):
        ## address is an offset.
        if (not gdtEntry[0].anotherLimit):
            if (gdtEntry[0].limit == BITMASK_DWORD):
                return True
            address += size-1
            if (address > gdtEntry[0].limit):
                IF COMP_DEBUG:
                    self.main.notice("Registers::isAddressInLimit: expand-up: not in limit; (addr==0x%08x; size==0x%08x; limit==0x%08x)", address, size, gdtEntry[0].limit)
                return False
        elif (gdtEntry[0].limit):
            address += size-1
            if (address <= gdtEntry[0].limit or (gdtEntry[0].segSize == OP_SIZE_WORD and (address >= BITMASK_WORD))):
                IF COMP_DEBUG:
                    self.main.notice("Registers::isAddressInLimit: expand-down: not in limit; (addr==0x%08x; size==0x%08x; limit==0x%08x)", address, size, gdtEntry[0].limit)
                return False
        return True
    cdef uint8_t segWriteSegment(self, Segment *segment, uint16_t segValue) except BITMASK_BYTE_CONST:
        cdef uint16_t segId
        cdef uint8_t protectedModeOn, segType
        segId = segment[0].segId
        if (segId == CPU_SEGMENT_CS):
            protectedModeOn = self.protectedModeOn
        else:
            protectedModeOn = self.getFlagDword(CPU_REGISTER_CR0, CR0_FLAG_PE) != 0
        protectedModeOn = (protectedModeOn and not self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.vm)
        if (protectedModeOn and segValue > 3):
            segType = self.segments.getSegType(segValue)
            if (segType & GDT_ACCESS_NORMAL_SEGMENT and not (segType & GDT_ACCESS_ACCESSED)):
                segType |= GDT_ACCESS_ACCESSED
                self.segments.setSegType(segValue, segType)
        if (protectedModeOn):
            if (not (<Segments>self.segments).checkSegmentLoadAllowed(segValue, segId)):
                segment[0].useGDT = segment[0].gdtEntry.base = segment[0].gdtEntry.limit = segment[0].gdtEntry.accessByte = segment[0].gdtEntry.flags = \
                  segment[0].gdtEntry.segSize = segment[0].isValid = segment[0].gdtEntry.segPresent = segment[0].gdtEntry.segIsCodeSeg = \
                  segment[0].gdtEntry.segIsRW = segment[0].gdtEntry.segIsConforming = segment[0].gdtEntry.segIsNormal = \
                  segment[0].gdtEntry.segUse4K = segment[0].gdtEntry.segDPL = segment[0].gdtEntry.anotherLimit = segment[0].segIsGDTandNormal = 0
            else:
                self.segments.loadSegment(segment, segValue, False)
        else:
            self.segments.loadSegment(segment, segValue, False)
        if (segId == CPU_SEGMENT_CS):
            self.main.cpu.codeSegSize = segment[0].gdtEntry.segSize
            if (self.protectedModeOn):
                if (self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.vm):
                    self.cpl = 3
                elif (segment[0].isValid and segment[0].useGDT):
                    self.cpl = segValue & 0x3
                else:
                    self.main.exitError("Registers::segWriteSegment: segment seems to be invalid!")
                    return False
            else:
                self.cpl = 0
            IF (CPU_CACHE_SIZE):
                if (not self.cacheDisabled):
                    self.cpuCacheCodeSegChange = True
        elif (segId == CPU_SEGMENT_SS):
            self.ssInhibit = True
        self.regs[CPU_SEGMENT_BASE+segId]._union.word._union.rx = segValue
        return True
    cdef uint64_t regReadUnsigned(self, uint16_t regId, uint8_t regSize):
        if (regSize == OP_SIZE_BYTE):
            return self.regs[regId]._union.word._union.byte.rl
        elif (regSize == OP_SIZE_WORD):
            if (regId == CPU_REGISTER_FLAGS):
                return <uint16_t>self.readFlags()
            return self.regs[regId]._union.word._union.rx
        elif (regSize == OP_SIZE_DWORD):
            if (regId == CPU_REGISTER_EFLAGS):
                return self.readFlags()
            return self.regs[regId]._union.dword.erx
        #else: #elif (regSize == OP_SIZE_QWORD):
        #if (regId == CPU_REGISTER_RFLAGS): # this isn't used yet.
        #    return self.readFlags()
        return self.regs[regId]._union.rrx
    cdef void regWrite(self, uint16_t regId, uint64_t value, uint8_t regSize):
        if (regSize == OP_SIZE_BYTE):
            self.regs[regId]._union.word._union.byte.rl = value
        elif (regSize == OP_SIZE_WORD):
            self.regs[regId]._union.word._union.rx = value
        elif (regSize == OP_SIZE_DWORD):
            self.regs[regId]._union.dword.erx = value
        else: #elif (regSize == OP_SIZE_QWORD):
            self.regs[regId]._union.rrx = value
    cdef uint8_t regWriteWord(self, uint16_t regId, uint16_t value) except BITMASK_BYTE_CONST:
        IF (CPU_CACHE_SIZE):
            cdef uint32_t realNewEip
        if (regId == CPU_REGISTER_EFLAGS):
            value &= ~RESERVED_FLAGS_BITMASK
            value |= FLAG_REQUIRED
            if ((not self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.if_flag) and ((value>>9)&1)):
                self.main.cpu.asyncEvent = True
        self.regs[regId]._union.word._union.rx = value
        if (regId == CPU_REGISTER_EIP and not self.isAddressInLimit(&self.segments.cs.gdtEntry, value, OP_SIZE_WORD)):
            raise HirnwichseException(CPU_EXCEPTION_GP, 0)
        IF (CPU_CACHE_SIZE):
            if (not self.cacheDisabled and regId == CPU_REGISTER_EIP):
                realNewEip = self.segments.cs.gdtEntry.base+self.regs[CPU_REGISTER_EIP]._union.dword.erx
                if (not self.cpuCacheCodeSegChange and realNewEip >= self.cpuCacheBase and realNewEip+OP_SIZE_WORD <= self.cpuCacheBase+self.cpuCacheSize):
                    self.cpuCacheIndex = realNewEip - self.cpuCacheBase
                else:
                #IF 1: # TODO: HACK
                    self.reloadCpuCache()
        return True
    cdef uint8_t regWriteDword(self, uint16_t regId, uint32_t value) except BITMASK_BYTE_CONST:
        IF (CPU_CACHE_SIZE):
            cdef uint32_t realNewEip
        if (regId == CPU_REGISTER_CR0):
            value |= 0x10
            value &= <uint32_t>0xe005003f
        elif (regId == CPU_REGISTER_DR6):
            value &= ~(1 << 12)
            value |= <uint32_t>0xfffe0ff0
        elif (regId == CPU_REGISTER_DR7):
            value &= ~(<uint32_t>0xd000)
            value |= (1 << 10)
        elif (regId == CPU_REGISTER_EFLAGS):
            value &= ~RESERVED_FLAGS_BITMASK
            value |= FLAG_REQUIRED
            if ((not self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.if_flag) and ((value>>9)&1)):
                self.main.cpu.asyncEvent = True
        self.regs[regId]._union.dword.erx = value
        if (regId == CPU_REGISTER_EIP and not self.isAddressInLimit(&self.segments.cs.gdtEntry, value, OP_SIZE_DWORD)):
            raise HirnwichseException(CPU_EXCEPTION_GP, 0)
        IF (CPU_CACHE_SIZE):
            if (not self.cacheDisabled and regId == CPU_REGISTER_EIP):
                realNewEip = self.segments.cs.gdtEntry.base+self.regs[CPU_REGISTER_EIP]._union.dword.erx
                if (not self.cpuCacheCodeSegChange and realNewEip >= self.cpuCacheBase and realNewEip+OP_SIZE_DWORD <= self.cpuCacheBase+self.cpuCacheSize):
                    self.cpuCacheIndex = realNewEip - self.cpuCacheBase
                else:
                #IF 1: # TODO: HACK
                    self.reloadCpuCache()
            #elif (regId == CPU_REGISTER_EFLAGS):
            #    self.reloadCpuCache()
        return True
    cdef uint8_t regWriteQword(self, uint16_t regId, uint64_t value) except BITMASK_BYTE_CONST:
        if (regId == CPU_REGISTER_RFLAGS):
            if ((not self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.if_flag) and ((value>>9)&1)):
                self.main.cpu.asyncEvent = True
        self.regs[regId]._union.rrx = value
        return True
    cdef inline void regWriteWithOpLowByte(self, uint16_t regId, uint8_t value, uint8_t valueOp):
        if (valueOp == OPCODE_SAVE):
            self.regs[regId]._union.word._union.byte.rl = value
        elif (valueOp == OPCODE_ADD):
            self.regs[regId]._union.word._union.byte.rl += value
        elif (valueOp == OPCODE_ADC):
            self.regs[regId]._union.word._union.byte.rl += value+self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf
        elif (valueOp == OPCODE_SUB):
            self.regs[regId]._union.word._union.byte.rl -= value
        elif (valueOp == OPCODE_SBB):
            self.regs[regId]._union.word._union.byte.rl -= value+self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf
        elif (valueOp == OPCODE_AND):
            self.regs[regId]._union.word._union.byte.rl &= value
        elif (valueOp == OPCODE_OR):
            self.regs[regId]._union.word._union.byte.rl |= value
        elif (valueOp == OPCODE_XOR):
            self.regs[regId]._union.word._union.byte.rl ^= value
        elif (valueOp == OPCODE_NEG):
            self.regs[regId]._union.word._union.byte.rl = -value
        elif (valueOp == OPCODE_NOT):
            self.regs[regId]._union.word._union.byte.rl = ~value
        #else:
        #    self.main.notice("REGISTERS::regWriteWithOpLowByte: unknown valueOp %u.", valueOp)
    cdef inline void regWriteWithOpHighByte(self, uint16_t regId, uint8_t value, uint8_t valueOp):
        if (valueOp == OPCODE_SAVE):
            self.regs[regId]._union.word._union.byte.rh = value
        elif (valueOp == OPCODE_ADD):
            self.regs[regId]._union.word._union.byte.rh += value
        elif (valueOp == OPCODE_ADC):
            self.regs[regId]._union.word._union.byte.rh += value+self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf
        elif (valueOp == OPCODE_SUB):
            self.regs[regId]._union.word._union.byte.rh -= value
        elif (valueOp == OPCODE_SBB):
            self.regs[regId]._union.word._union.byte.rh -= value+self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf
        elif (valueOp == OPCODE_AND):
            self.regs[regId]._union.word._union.byte.rh &= value
        elif (valueOp == OPCODE_OR):
            self.regs[regId]._union.word._union.byte.rh |= value
        elif (valueOp == OPCODE_XOR):
            self.regs[regId]._union.word._union.byte.rh ^= value
        elif (valueOp == OPCODE_NEG):
            self.regs[regId]._union.word._union.byte.rh = -value
        elif (valueOp == OPCODE_NOT):
            self.regs[regId]._union.word._union.byte.rh = ~value
        #else:
        #    self.main.notice("REGISTERS::regWriteWithOpHighByte: unknown valueOp %u.", valueOp)
    cdef void regWriteWithOpWords(self, uint16_t regId, uint16_t_uint32_t_uint64_t value, uint8_t valueOp):
        if (uint16_t_uint32_t_uint64_t is uint16_t):
            if (valueOp == OPCODE_SAVE):
                self.regs[regId]._union.word._union.rx = value
            elif (valueOp == OPCODE_ADD):
                self.regs[regId]._union.word._union.rx += value
            elif (valueOp == OPCODE_ADC):
                self.regs[regId]._union.word._union.rx += value+self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf
            elif (valueOp == OPCODE_SUB):
                self.regs[regId]._union.word._union.rx -= value
            elif (valueOp == OPCODE_SBB):
                self.regs[regId]._union.word._union.rx -= value+self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf
            elif (valueOp == OPCODE_AND):
                self.regs[regId]._union.word._union.rx &= value
            elif (valueOp == OPCODE_OR):
                self.regs[regId]._union.word._union.rx |= value
            elif (valueOp == OPCODE_XOR):
                self.regs[regId]._union.word._union.rx ^= value
            elif (valueOp == OPCODE_NEG):
                self.regs[regId]._union.word._union.rx = -value
            elif (valueOp == OPCODE_NOT):
                self.regs[regId]._union.word._union.rx = ~value
            #else:
            #    self.main.notice("REGISTERS::regWriteWithOpWord: unknown valueOp %u.", valueOp)
        elif (uint16_t_uint32_t_uint64_t is uint32_t):
            if (valueOp == OPCODE_SAVE):
                self.regs[regId]._union.dword.erx = value
            elif (valueOp == OPCODE_ADD):
                self.regs[regId]._union.dword.erx += value
            elif (valueOp == OPCODE_ADC):
                self.regs[regId]._union.dword.erx += value+self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf
            elif (valueOp == OPCODE_SUB):
                self.regs[regId]._union.dword.erx -= value
            elif (valueOp == OPCODE_SBB):
                self.regs[regId]._union.dword.erx -= value+self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf
            elif (valueOp == OPCODE_AND):
                self.regs[regId]._union.dword.erx &= value
            elif (valueOp == OPCODE_OR):
                self.regs[regId]._union.dword.erx |= value
            elif (valueOp == OPCODE_XOR):
                self.regs[regId]._union.dword.erx ^= value
            elif (valueOp == OPCODE_NEG):
                self.regs[regId]._union.dword.erx = -value
            elif (valueOp == OPCODE_NOT):
                self.regs[regId]._union.dword.erx = ~value
            #else:
            #    self.main.notice("REGISTERS::regWriteWithOpDword: unknown valueOp %u.", valueOp)
        elif (uint16_t_uint32_t_uint64_t is uint64_t):
        #else:
            if (valueOp == OPCODE_SAVE):
                self.regs[regId]._union.rrx = value
            elif (valueOp == OPCODE_ADD):
                self.regs[regId]._union.rrx += value
            elif (valueOp == OPCODE_ADC):
                self.regs[regId]._union.rrx += value+self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf
            elif (valueOp == OPCODE_SUB):
                self.regs[regId]._union.rrx -= value
            elif (valueOp == OPCODE_SBB):
                self.regs[regId]._union.rrx -= value+self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf
            elif (valueOp == OPCODE_AND):
                self.regs[regId]._union.rrx &= value
            elif (valueOp == OPCODE_OR):
                self.regs[regId]._union.rrx |= value
            elif (valueOp == OPCODE_XOR):
                self.regs[regId]._union.rrx ^= value
            elif (valueOp == OPCODE_NEG):
                self.regs[regId]._union.rrx = -value
            elif (valueOp == OPCODE_NOT):
                self.regs[regId]._union.rrx = ~value
            #else:
            #    self.main.notice("REGISTERS::regWriteWithOpQword: unknown valueOp %u.", valueOp)
    cdef void setSZP(self, uint8_t_uint16_t_uint32_t value, uint8_t regSize): # ((regSize<<3)-1) # HACK: apply patch "cython_diff_1" 
        if (uint8_t_uint16_t_uint32_t is uint8_t):
            #self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.sf = (value>>7)!=0
            self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.sf = (value>>7)&1
        elif (uint8_t_uint16_t_uint32_t is uint16_t):
            #self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.sf = (value>>15)!=0
            self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.sf = (value>>15)&1
        else:
            #self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.sf = (value>>31)!=0
            self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.sf = (value>>31)&1
        #self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.sf = (value>>((regSize<<3)-1))!=0
        #self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.sf = (value>>((regSize<<3)-1))&1
        self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.zf = value==0
        self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.pf = PARITY_TABLE[<uint8_t>value]
    cdef void setSZP_O(self, uint8_t_uint16_t_uint32_t value, uint8_t regSize):
        self.setSZP(value, regSize)
        self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.of = False
    cdef void setSZP_A(self, uint8_t_uint16_t_uint32_t value, uint8_t regSize):
        self.setSZP(value, regSize)
        self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.af = False
    cdef void setSZP_COA(self, uint8_t_uint16_t_uint32_t value, uint8_t regSize):
        self.setSZP(value, regSize)
        self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf = self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.of = self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.af = False
    cdef inline uint8_t getCond(self, uint8_t index):
        cdef uint8_t negateCheck, ret = 0
        negateCheck = index & 1
        index >>= 1
        if (index == 0x0): # O
            ret = self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.of
        elif (index == 0x1): # B
            ret = self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf
        elif (index == 0x2): # Z
            ret = self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.zf
        elif (index == 0x3): # BE
            ret = self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf or self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.zf
        elif (index == 0x4): # S
            ret = self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.sf
        elif (index == 0x5): # P
            ret = self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.pf
        elif (index == 0x6): # L
            ret = self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.sf != self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.of
        elif (index == 0x7): # LE
            ret = self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.zf or self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.sf != self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.of
        #else:
        #    self.main.exitError("getCond: index 0x%02x is invalid.", index)
        if (negateCheck):
            ret = not ret
        return ret
    #cdef void setFullFlags_(self, uint64_t reg0, uint64_t reg1, uint8_t regSize, uint8_t method):
    #    cdef uint8_t unsignedOverflow = False, reg0Nibble, regSumuNibble, regShift, carried = False
    #    cdef uint64_t regSumu = 0
    #    if (method in (OPCODE_ADD, OPCODE_ADC, OPCODE_SUB, OPCODE_SBB, OPCODE_MUL, OPCODE_IMUL, OPCODE_CMP)):
    #        if (method in (OPCODE_MUL, OPCODE_IMUL)):
    #            if (regSize == OP_SIZE_BYTE):
    #                if (method == OPCODE_MUL):
    #                    regSumu = (<uint8_t>reg0*<uint8_t>reg1)
    #                    unsignedOverflow = (<uint16_t>regSumu)!=(<uint8_t>regSumu)
    #                else:
    #                    regSumu = (<int8_t>reg0*<uint8_t>reg1)
    #                    unsignedOverflow = (<int16_t>regSumu)!=(<int8_t>regSumu)
    #                regSumu = <uint8_t>regSumu
    #            elif (regSize == OP_SIZE_WORD):
    #                if (method == OPCODE_MUL):
    #                    regSumu = (<uint16_t>reg0*<uint16_t>reg1)
    #                    unsignedOverflow = (<uint32_t>regSumu)!=(<uint16_t>regSumu)
    #                else:
    #                    regSumu = (<int16_t>reg0*<uint16_t>reg1)
    #                    unsignedOverflow = (<int32_t>regSumu)!=(<int16_t>regSumu)
    #                regSumu = <uint16_t>regSumu
    #            elif (regSize == OP_SIZE_DWORD):
    #                if (method == OPCODE_MUL):
    #                    regSumu = (<uint32_t>reg0*<uint32_t>reg1)
    #                    unsignedOverflow = (<uint64_t>regSumu)!=(<uint32_t>regSumu)
    #                else:
    #                    regSumu = (<int32_t>reg0*<uint32_t>reg1)
    #                    unsignedOverflow = (<int64_t>regSumu)!=(<int32_t>regSumu)
    #                regSumu = <uint32_t>regSumu
    #        else:
    #            if (regSize == OP_SIZE_BYTE):
    #                reg0 = <uint8_t>reg0
    #                reg1 = <uint8_t>reg1
    #            elif (regSize == OP_SIZE_WORD):
    #                reg0 = <uint16_t>reg0
    #                reg1 = <uint16_t>reg1
    #            elif (regSize == OP_SIZE_DWORD):
    #                reg0 = <uint32_t>reg0
    #                reg1 = <uint32_t>reg1
    #            if (method in (OPCODE_ADC, OPCODE_SBB) and self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf):
    #                carried = True
    #                reg1 += 1
    #            if (method in (OPCODE_ADD, OPCODE_ADC)):
    #                regSumu = (reg0+reg1)
    #            elif (method in (OPCODE_SUB, OPCODE_SBB, OPCODE_CMP)):
    #                regSumu = (reg0-reg1)
    #            if (regSize == OP_SIZE_BYTE):
    #                unsignedOverflow = regSumu!=(<uint8_t>regSumu)
    #                regSumu = <uint8_t>regSumu
    #            elif (regSize == OP_SIZE_WORD):
    #                unsignedOverflow = regSumu!=(<uint16_t>regSumu)
    #                regSumu = <uint16_t>regSumu
    #            elif (regSize == OP_SIZE_DWORD):
    #                unsignedOverflow = regSumu!=(<uint32_t>regSumu)
    #                regSumu = <uint32_t>regSumu
    #        self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.pf = PARITY_TABLE[<uint8_t>regSumu]
    #        self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.zf = not regSumu
    #        regShift = (regSize<<3)-1
    #        if (method in (OPCODE_MUL, OPCODE_IMUL)):
    #            self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.af = False
    #            self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.of = unsignedOverflow
    #            regSumu >>= regShift
    #        else:
    #            reg0Nibble = reg0&0xf
    #            regSumuNibble = regSumu&0xf
    #            reg0 >>= regShift
    #            reg1 >>= regShift
    #            regSumu >>= regShift
    #            if (method in (OPCODE_ADD, OPCODE_ADC)):
    #                self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.af = (regSumuNibble<(reg0Nibble+carried))
    #                self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.of = regSumu not in (reg0, reg1)
    #            elif (method in (OPCODE_SUB, OPCODE_SBB, OPCODE_CMP)):
    #                self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.af = ((regSumuNibble+carried)>reg0Nibble)
    #                self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.of = (reg0!=reg1 and reg0!=regSumu and reg1==regSumu)
    #        self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf = unsignedOverflow
    #        self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.sf = regSumu
    cdef void setFullFlags(self, uint8_t_uint16_t_uint32_t reg0, uint8_t_uint16_t_uint32_t reg1, uint8_t method):
        cdef uint8_t unsignedOverflow, reg0Nibble, regSumuNibble, regShift, carried = False
        cdef uint64_t regSumu = 0
        if (uint8_t_uint16_t_uint32_t is uint8_t):
            regShift = OP_SIZE_BYTE
        elif (uint8_t_uint16_t_uint32_t is uint16_t):
            regShift = OP_SIZE_WORD
        elif (uint8_t_uint16_t_uint32_t is uint32_t):
            regShift = OP_SIZE_DWORD
        if (method in (OPCODE_MUL, OPCODE_IMUL)):
            if (method == OPCODE_MUL):
                regSumu = (reg0*reg1)
            if (uint8_t_uint16_t_uint32_t is uint8_t):
                if (method == OPCODE_MUL):
                    unsignedOverflow = (<uint16_t>regSumu)!=(<uint8_t_uint16_t_uint32_t>regSumu)
                else:
                    regSumu = (<int8_t>reg0*reg1)
                    unsignedOverflow = (<int16_t>regSumu)!=(<int8_t>regSumu)
            elif (uint8_t_uint16_t_uint32_t is uint16_t):
                if (method == OPCODE_MUL):
                    unsignedOverflow = (<uint32_t>regSumu)!=(<uint8_t_uint16_t_uint32_t>regSumu)
                else:
                    regSumu = (<int16_t>reg0*reg1)
                    unsignedOverflow = (<int32_t>regSumu)!=(<int16_t>regSumu)
            #elif (uint8_t_uint16_t_uint32_t is uint32_t):
            else:
                if (method == OPCODE_MUL):
                    unsignedOverflow = (<uint64_t>regSumu)!=(<uint8_t_uint16_t_uint32_t>regSumu)
                else:
                    regSumu = (<int32_t>reg0*reg1)
                    unsignedOverflow = (<int64_t>regSumu)!=(<int32_t>regSumu)
        else:
            if (method in (OPCODE_ADC, OPCODE_SBB) and self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf):
                carried = True
            if (method in (OPCODE_ADD, OPCODE_ADC)):
                #regSumu = (reg0+reg1+carried)
                regSumu = (reg0+<uint64_t>reg1+carried) # fix or hack for the winxp cd boot
            elif (method in (OPCODE_SUB, OPCODE_SBB, OPCODE_CMP)):
                regSumu = (reg0-(<uint64_t>reg1+carried))
            unsignedOverflow = regSumu!=(<uint8_t_uint16_t_uint32_t>regSumu)
        regSumu = <uint8_t_uint16_t_uint32_t>regSumu
        self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.pf = PARITY_TABLE[<uint8_t>regSumu]
        self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.zf = not regSumu
        regShift = (regShift<<3)-1
        if (method in (OPCODE_MUL, OPCODE_IMUL)):
            self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.af = False
            self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.of = unsignedOverflow
            regSumu >>= regShift
        else:
            reg0Nibble = reg0&0xf
            regSumuNibble = regSumu&0xf
            reg0 >>= regShift
            reg1 >>= regShift
            regSumu >>= regShift
            if (method in (OPCODE_ADD, OPCODE_ADC)):
                self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.af = (regSumuNibble<(reg0Nibble+carried))
                self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.of = regSumu not in (reg0, reg1)
            elif (method in (OPCODE_SUB, OPCODE_SBB, OPCODE_CMP)):
                self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.af = ((regSumuNibble+carried)>reg0Nibble)
                self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.of = (reg0!=reg1 and reg0!=regSumu and reg1==regSumu)
        self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf = unsignedOverflow
        self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.sf = regSumu
    cdef inline uint32_t mmGetRealAddr(self, uint32_t mmAddr, uint32_t dataSize, Segment *segment, uint8_t allowOverride, uint8_t written, uint8_t noAddress) except? BITMASK_BYTE_CONST:
        cdef uint8_t addrInLimit
        IF COMP_DEBUG:
            cdef uint32_t origMmAddr = mmAddr
        if (allowOverride and self.main.cpu.segmentOverridePrefix is not NULL):
            segment = self.main.cpu.segmentOverridePrefix
        IF COMP_DEBUG:
            if (self.main.debugEnabled):
                self.main.notice("Registers::mmGetRealAddr_1: %s: LIN 0x%08x; dataSize %u", b"WR" if (written) else b"RD", origMmAddr, dataSize)
        if (segment is not NULL):
            IF COMP_DEBUG:
                if (self.main.debugEnabled):
                    self.main.notice("Registers::mmGetRealAddr_1.1: %s: LIN 0x%08x; dataSize %u; segId %u", b"WR" if (written) else b"RD", origMmAddr, dataSize, segment[0].segId)
            if (self.protectedModeOn and segment[0].segId == CPU_SEGMENT_TSS):
                (<Paging>(<Segments>self.segments).paging).implicitSV = True
            addrInLimit = self.isAddressInLimit(&segment[0].gdtEntry, mmAddr, dataSize)
            if (not addrInLimit):
                if (not self.ignoreExceptions):
                    if (segment[0].segId == CPU_SEGMENT_SS):
                        raise HirnwichseException(CPU_EXCEPTION_SS, segment[0].segmentIndex)
                    else:
                        raise HirnwichseException(CPU_EXCEPTION_GP, segment[0].segmentIndex)
                else:
                    self.ignoreExceptions = False
                return BITMASK_BYTE
            if ((written and not segment[0].writeChecked) or (not written and not segment[0].readChecked)):
                if (segment[0].useGDT):
                    if (not (segment[0].segmentIndex&0xfff8) or not segment[0].gdtEntry.segPresent):
                        if (segment[0].segId == CPU_SEGMENT_SS):
                            #self.main.notice("Registers::checkMemAccessRights: test1.1.1")
                            raise HirnwichseException(CPU_EXCEPTION_SS, segment[0].segmentIndex)
                        elif (not segment[0].gdtEntry.segPresent):
                            #self.main.notice("Registers::checkMemAccessRights: test1.1.2")
                            raise HirnwichseException(CPU_EXCEPTION_NP, segment[0].segmentIndex)
                        else:
                            #self.main.notice("Registers::checkMemAccessRights: test1.1.3")
                            raise HirnwichseException(CPU_EXCEPTION_GP, segment[0].segmentIndex)
                if (written):
                    if (segment[0].segIsGDTandNormal and (segment[0].gdtEntry.segIsCodeSeg or not segment[0].gdtEntry.segIsRW)):
                        #self.main.notice("Registers::checkMemAccessRights: test1.3")
                        #self.main.notice("Registers::checkMemAccessRights: test1.3.1; c0==%u; c1==%u; c2==%u", segment[0].gdtEntry.segIsNormal, (segment[0].gdtEntry.segIsCodeSeg or not segment[0].gdtEntry.segIsRW), not addrInLimit)
                        #self.main.notice("Registers::checkMemAccessRights: test1.3.2; mmAddr==0x%08x; dataSize==%u; base==0x%08x; limit==0x%08x", mmAddr, dataSize, segment[0].gdtEntry.base, segment[0].gdtEntry.limit)
                        if (segment[0].segId == CPU_SEGMENT_SS):
                            raise HirnwichseException(CPU_EXCEPTION_SS, segment[0].segmentIndex)
                        else:
                            raise HirnwichseException(CPU_EXCEPTION_GP, segment[0].segmentIndex)
                    segment[0].writeChecked = True
                else:
                    if (segment[0].segIsGDTandNormal and not (<Paging>(<Segments>self.segments).paging).instrFetch and segment[0].gdtEntry.segIsCodeSeg and not segment[0].gdtEntry.segIsRW):
                        #self.main.notice("Registers::checkMemAccessRights: test1.4")
                        if (segment[0].segId == CPU_SEGMENT_SS):
                            raise HirnwichseException(CPU_EXCEPTION_SS, segment[0].segmentIndex)
                        else:
                            raise HirnwichseException(CPU_EXCEPTION_GP, segment[0].segmentIndex)
                    segment[0].readChecked = True
            mmAddr += segment[0].gdtEntry.base
        if (noAddress):
            return True
        # TODO: check for limit asf...
        if (self.protectedModeOn and self.pagingOn): # TODO: is a20 even being applied after paging is enabled? (on the physical address... or even the virtual one?)
            mmAddr = (<Paging>(<Segments>self.segments).paging).getPhysicalAddress(mmAddr, dataSize, written)
        if (not self.A20Active): # A20 Active? if True == on, else off
            mmAddr &= <uint32_t>0xffefffff
        IF COMP_DEBUG:
            if (self.main.debugEnabled):
                self.main.notice("Registers::mmGetRealAddr_2: %s: LIN 0x%08x; PHY 0x%08x", b"WR" if (written) else b"RD", origMmAddr, mmAddr)
        return mmAddr
    cdef inline uint8_t mmReadValueUnsignedByte(self, uint32_t mmAddr, Segment *segment, uint8_t allowOverride) except? BITMASK_BYTE_CONST:
        cdef uint8_t ret
        #if (self.main.debugEnabled):
        #    self.main.notice("Registers::mmReadValueUnsignedByte_1: virt mmAddr 0x%08x; dataSize %u", mmAddr, OP_SIZE_BYTE)
        ret = self.main.mm.mmPhyReadValueUnsignedByte(self.mmGetRealAddr(mmAddr, OP_SIZE_BYTE, segment, allowOverride, False, False))
        IF COMP_DEBUG:
            if (self.main.debugEnabled):
                self.main.notice("Registers::mmReadValueUnsignedByte_2: virt mmAddr 0x%08x; ret 0x%08x; dataSize %u", mmAddr, ret, OP_SIZE_BYTE)
        return ret
    cdef uint16_t mmReadValueUnsignedWord(self, uint32_t mmAddr, Segment *segment, uint8_t allowOverride) except? BITMASK_BYTE_CONST:
        cdef uint16_t ret
        cdef uint32_t physAddr
        if (self.protectedModeOn and self.pagingOn):
            if (allowOverride and self.main.cpu.segmentOverridePrefix is not NULL):
                physAddr = self.main.cpu.segmentOverridePrefix[0].gdtEntry.base+mmAddr
            elif (segment is not NULL):
                physAddr = segment[0].gdtEntry.base+mmAddr
            else:
                physAddr = mmAddr
            if (PAGE_DIRECTORY_LENGTH-(physAddr&0xfff) < OP_SIZE_WORD):
                ret = <uint16_t>self.mmReadValueUnsignedByte(mmAddr, segment, allowOverride)
                ret |= <uint16_t>self.mmReadValueUnsignedByte(mmAddr+1, segment, allowOverride)<<8
                return ret
        physAddr = self.mmGetRealAddr(mmAddr, OP_SIZE_WORD, segment, allowOverride, False, False)
        ret = self.main.mm.mmPhyReadValueUnsignedWord(physAddr)
        IF COMP_DEBUG:
            if (self.main.debugEnabled):
                self.main.notice("Registers::mmReadValueUnsignedWord: virt mmAddr 0x%08x; ret 0x%08x; dataSize %u", mmAddr, ret, OP_SIZE_WORD)
        return ret
    cdef uint32_t mmReadValueUnsignedDword(self, uint32_t mmAddr, Segment *segment, uint8_t allowOverride) except? BITMASK_BYTE_CONST:
        cdef uint32_t ret, physAddr
        if (self.protectedModeOn and self.pagingOn):
            if (allowOverride and self.main.cpu.segmentOverridePrefix is not NULL):
                physAddr = self.main.cpu.segmentOverridePrefix[0].gdtEntry.base+mmAddr
            elif (segment is not NULL):
                physAddr = segment[0].gdtEntry.base+mmAddr
            else:
                physAddr = mmAddr
            if (PAGE_DIRECTORY_LENGTH-(physAddr&0xfff) < OP_SIZE_DWORD):
                ret = <uint32_t>self.mmReadValueUnsignedByte(mmAddr, segment, allowOverride)
                ret |= <uint32_t>self.mmReadValueUnsignedByte(mmAddr+1, segment, allowOverride)<<8
                ret |= <uint32_t>self.mmReadValueUnsignedByte(mmAddr+2, segment, allowOverride)<<16
                ret |= <uint32_t>self.mmReadValueUnsignedByte(mmAddr+3, segment, allowOverride)<<24
                return ret
        physAddr = self.mmGetRealAddr(mmAddr, OP_SIZE_DWORD, segment, allowOverride, False, False)
        ret = self.main.mm.mmPhyReadValueUnsignedDword(physAddr)
        IF COMP_DEBUG:
            if (self.main.debugEnabled):
                self.main.notice("Registers::mmReadValueUnsignedDword: virt mmAddr 0x%08x; ret 0x%08x; dataSize %u", mmAddr, ret, OP_SIZE_DWORD)
        return ret
    cdef uint64_t mmReadValueUnsignedQword(self, uint32_t mmAddr, Segment *segment, uint8_t allowOverride) except? BITMASK_BYTE_CONST:
        cdef uint32_t physAddr
        cdef uint64_t ret
        if (self.protectedModeOn and self.pagingOn):
            if (allowOverride and self.main.cpu.segmentOverridePrefix is not NULL):
                physAddr = self.main.cpu.segmentOverridePrefix[0].gdtEntry.base+mmAddr
            elif (segment is not NULL):
                physAddr = segment[0].gdtEntry.base+mmAddr
            else:
                physAddr = mmAddr
            if (PAGE_DIRECTORY_LENGTH-(physAddr&0xfff) < OP_SIZE_QWORD):
                ret = <uint64_t>self.mmReadValueUnsignedByte(mmAddr, segment, allowOverride)
                ret |= <uint64_t>self.mmReadValueUnsignedByte(mmAddr+1, segment, allowOverride)<<8
                ret |= <uint64_t>self.mmReadValueUnsignedByte(mmAddr+2, segment, allowOverride)<<16
                ret |= <uint64_t>self.mmReadValueUnsignedByte(mmAddr+3, segment, allowOverride)<<24
                ret |= <uint64_t>self.mmReadValueUnsignedByte(mmAddr+4, segment, allowOverride)<<32
                ret |= <uint64_t>self.mmReadValueUnsignedByte(mmAddr+5, segment, allowOverride)<<40
                ret |= <uint64_t>self.mmReadValueUnsignedByte(mmAddr+6, segment, allowOverride)<<48
                ret |= <uint64_t>self.mmReadValueUnsignedByte(mmAddr+7, segment, allowOverride)<<56
                return ret
        physAddr = self.mmGetRealAddr(mmAddr, OP_SIZE_QWORD, segment, allowOverride, False, False)
        ret = self.main.mm.mmPhyReadValueUnsignedQword(physAddr)
        IF COMP_DEBUG:
            if (self.main.debugEnabled):
                self.main.notice("Registers::mmReadValueUnsignedQword: virt mmAddr 0x%08x; ret 0x%08x; dataSize %u", mmAddr, ret, OP_SIZE_QWORD)
        return ret
    cdef uint64_t mmReadValueUnsigned(self, uint32_t mmAddr, uint8_t dataSize, Segment *segment, uint8_t allowOverride) except? BITMASK_BYTE_CONST:
        cdef uint8_t i
        cdef uint32_t physAddr
        cdef uint64_t ret
        if (self.protectedModeOn and self.pagingOn):
            if (allowOverride and self.main.cpu.segmentOverridePrefix is not NULL):
                physAddr = self.main.cpu.segmentOverridePrefix[0].gdtEntry.base+mmAddr
            elif (segment is not NULL):
                physAddr = segment[0].gdtEntry.base+mmAddr
            else:
                physAddr = mmAddr
            if (PAGE_DIRECTORY_LENGTH-(physAddr&0xfff) < dataSize):
                ret = 0
                for i in range(dataSize):
                    ret |= <uint64_t>self.mmReadValueUnsignedByte(mmAddr+i, segment, allowOverride)<<(i<<3)
                return ret
        physAddr = self.mmGetRealAddr(mmAddr, dataSize, segment, allowOverride, False, False)
        ret = self.main.mm.mmPhyReadValueUnsigned(physAddr, dataSize)
        IF COMP_DEBUG:
            if (self.main.debugEnabled):
                self.main.notice("Registers::mmReadValueUnsigned: virt mmAddr 0x%08x; ret 0x%08x; dataSize %u", mmAddr, ret, dataSize)
        return ret
    cdef uint8_t mmWriteValue(self, uint32_t mmAddr, uint64_t data, uint8_t dataSize, Segment *segment, uint8_t allowOverride) except BITMASK_BYTE_CONST:
        cdef uint8_t retVal, i
        cdef uint32_t physAddr
        IF COMP_DEBUG:
            if (self.main.debugEnabled):
                self.main.notice("Registers::mmWriteValue: virt mmAddr 0x%08x; data 0x%08x; dataSize %u", mmAddr, data, dataSize)
        if (self.protectedModeOn and self.pagingOn):
            if (allowOverride and self.main.cpu.segmentOverridePrefix is not NULL):
                physAddr = self.main.cpu.segmentOverridePrefix[0].gdtEntry.base+mmAddr
            elif (segment is not NULL):
                physAddr = segment[0].gdtEntry.base+mmAddr
            else:
                physAddr = mmAddr
            if (PAGE_DIRECTORY_LENGTH-(physAddr&0xfff) < dataSize):
                for i in range(dataSize):
                    self.mmWriteValue(mmAddr+i, <uint8_t>data, OP_SIZE_BYTE, segment, allowOverride)
                    data >>= 8
                return True
        physAddr = self.mmGetRealAddr(mmAddr, dataSize, segment, allowOverride, True, False)
        retVal = self.main.mm.mmPhyWriteValue(physAddr, data, dataSize)
        IF CPU_CACHE_SIZE:
            if (not self.cacheDisabled):
                self.checkCache(physAddr, dataSize)
        return retVal
    cdef uint8_t mmWriteValueWithOp(self, uint32_t mmAddr, uint64_t data, uint8_t dataSize, Segment *segment, uint8_t allowOverride, uint8_t valueOp) except BITMASK_BYTE_CONST:
        cdef uint64_t oldData
        if (valueOp != OPCODE_SAVE):
            if (valueOp == OPCODE_NEG):
                data = (-data)
            elif (valueOp == OPCODE_NOT):
                data = (~data)
            else:
                oldData = self.mmReadValueUnsigned(mmAddr, dataSize, segment, allowOverride)
                if (valueOp == OPCODE_ADD):
                    data = (oldData+data)
                elif (valueOp == OPCODE_SUB):
                    data = (oldData-data)
                elif (valueOp == OPCODE_AND):
                    data = (oldData&data)
                elif (valueOp == OPCODE_OR):
                    data = (oldData|data)
                elif (valueOp == OPCODE_XOR):
                    data = (oldData^data)
                elif (valueOp in (OPCODE_ADC, OPCODE_SBB)):
                    data += self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf
                    if (valueOp == OPCODE_ADC):
                        data = (oldData+data)
                    else:
                        data = (oldData-data)
                #else:
                #    self.main.exitError("Registers::mmWriteValueWithOp: unknown valueOp %u.", valueOp)
        IF COMP_DEBUG:
            if (self.main.debugEnabled):
                self.main.notice("Registers::mmWriteValueWithOp: virt mmAddr 0x%08x; data 0x%08x; dataSize %u", mmAddr, data, dataSize)
        return self.mmWriteValue(mmAddr, data, dataSize, segment, allowOverride)
    cdef uint8_t switchTSS16(self) except BITMASK_BYTE_CONST:
        cdef uint32_t baseAddress
        cdef GdtEntry gdtEntry
        #self.main.notice("Registers::switchTSS16: TODO? (savedEip: 0x%08x, savedCs: 0x%04x)", self.main.cpu.savedEip, self.main.cpu.savedCs)
        baseAddress = self.mmGetRealAddr(0, 1, &self.segments.tss, False, False, False)
        if (((baseAddress&0xfff)+TSS_MIN_16BIT_HARD_LIMIT) > 0xfff):
            self.main.exitError("Registers::switchTSS16: TSS is over page boundary!")
            return False
        self.ldtr = self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_16BIT_LDT_SEG_SEL)
        if (self.ldtr):
            if (not self.segments.gdt.getEntry(&gdtEntry, self.ldtr&0xfff8)):
                #self.main.notice("Registers::switchTSS16: gdtEntry is invalid, mark LDTR as invalid.")
                (<Gdt>self.segments.ldt).loadTablePosition(0, 0)
            else:
                (<Gdt>self.segments.ldt).loadTablePosition(gdtEntry.base, gdtEntry.limit)
        else:
            (<Gdt>self.segments.ldt).loadTablePosition(0, 0)
        self.segWriteSegment(&self.segments.cs, self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_16BIT_CS))
        self.regWriteWord(CPU_REGISTER_IP, self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_16BIT_IP))
        self.segWriteSegment(&self.segments.ss, self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_16BIT_SS))
        self.regs[CPU_REGISTER_SP]._union.word._union.rx = self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_16BIT_SP)
        self.regWriteWord(CPU_REGISTER_FLAGS, self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_16BIT_FLAGS))
        if (self.readFlags()):
            self.main.cpu.asyncEvent = True
        self.segWriteSegment(&self.segments.ds, self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_16BIT_DS))
        self.segWriteSegment(&self.segments.es, self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_16BIT_ES))
        self.regs[CPU_REGISTER_AX]._union.word._union.rx = self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_16BIT_AX)
        self.regs[CPU_REGISTER_CX]._union.word._union.rx = self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_16BIT_CX)
        self.regs[CPU_REGISTER_DX]._union.word._union.rx = self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_16BIT_DX)
        self.regs[CPU_REGISTER_BX]._union.word._union.rx = self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_16BIT_BX)
        self.regs[CPU_REGISTER_BP]._union.word._union.rx = self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_16BIT_BP)
        self.regs[CPU_REGISTER_SI]._union.word._union.rx = self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_16BIT_SI)
        self.regs[CPU_REGISTER_DI]._union.word._union.rx = self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_16BIT_DI)
        self.regs[CPU_REGISTER_CR0]._union.dword.erx |= CR0_FLAG_TS
        return True
    cdef uint8_t saveTSS16(self) except BITMASK_BYTE_CONST:
        cdef uint32_t baseAddress
        #self.main.notice("Registers::saveTSS16: TODO? (savedEip: 0x%08x, savedCs: 0x%04x)", self.main.cpu.savedEip, self.main.cpu.savedCs)
        baseAddress = self.mmGetRealAddr(0, 1, &self.segments.tss, False, True, False)
        if (((baseAddress&0xfff)+TSS_MIN_16BIT_HARD_LIMIT) > 0xfff):
            self.main.exitError("Registers::saveTSS16: TSS is over page boundary!")
            return False
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_16BIT_AX, self.regs[CPU_REGISTER_AX]._union.word._union.rx, OP_SIZE_WORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_16BIT_CX, self.regs[CPU_REGISTER_CX]._union.word._union.rx, OP_SIZE_WORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_16BIT_DX, self.regs[CPU_REGISTER_DX]._union.word._union.rx, OP_SIZE_WORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_16BIT_BX, self.regs[CPU_REGISTER_BX]._union.word._union.rx, OP_SIZE_WORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_16BIT_BP, self.regs[CPU_REGISTER_BP]._union.word._union.rx, OP_SIZE_WORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_16BIT_SI, self.regs[CPU_REGISTER_SI]._union.word._union.rx, OP_SIZE_WORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_16BIT_DI, self.regs[CPU_REGISTER_DI]._union.word._union.rx, OP_SIZE_WORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_16BIT_ES, self.regs[CPU_SEGMENT_BASE+CPU_SEGMENT_ES]._union.word._union.rx, OP_SIZE_WORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_16BIT_CS, self.regs[CPU_SEGMENT_BASE+CPU_SEGMENT_CS]._union.word._union.rx, OP_SIZE_WORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_16BIT_DS, self.regs[CPU_SEGMENT_BASE+CPU_SEGMENT_DS]._union.word._union.rx, OP_SIZE_WORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_16BIT_IP, self.regs[CPU_REGISTER_IP]._union.word._union.rx, OP_SIZE_WORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_16BIT_FLAGS, self.readFlags(), OP_SIZE_WORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_16BIT_SP, self.regs[CPU_REGISTER_SP]._union.word._union.rx, OP_SIZE_WORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_16BIT_SS, self.regs[CPU_SEGMENT_BASE+CPU_SEGMENT_SS]._union.word._union.rx, OP_SIZE_WORD)
        return True
    cdef uint8_t switchTSS32(self) except BITMASK_BYTE_CONST:
        cdef uint32_t baseAddress, temp
        cdef GdtEntry gdtEntry
        #self.main.notice("Registers::switchTSS32: TODO? (savedEip: 0x%08x, savedCs: 0x%04x)", self.main.cpu.savedEip, self.main.cpu.savedCs)
        #self.main.cpu.cpuDump()
        #self.main.notice("Registers::switchTSS32: TODO? (getCPL(): %u; cpl: %u)", self.getCPL(), self.cpl)
        baseAddress = self.mmGetRealAddr(0, 1, &self.segments.tss, False, False, False)
        if (((baseAddress&0xfff)+TSS_MIN_32BIT_HARD_LIMIT) > 0xfff):
            self.main.exitError("Registers::switchTSS32: TSS is over page boundary!")
            return False
        temp = self.main.mm.mmPhyReadValueUnsignedDword(baseAddress + TSS_32BIT_LDT_SEG_SEL)
        if (not self.segments.inLimit(temp)):
            raise HirnwichseException(CPU_EXCEPTION_TS, temp)
        # TODO: add the missing checks
        if (self.protectedModeOn and self.pagingOn):
            temp = self.main.mm.mmPhyReadValueUnsignedDword(baseAddress + TSS_32BIT_CR3) # intel manual (7.3 Task Switching) says to read it without writing it afterwards if paging is disabled. does doing so make any sense with the current design of the emulator?
            self.regs[CPU_REGISTER_CR3]._union.dword.erx = temp
            #(<Paging>self.segments.paging).invalidateTables(temp, True)
            (<Paging>self.segments.paging).invalidateTables(temp, False)
        self.ldtr = self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_32BIT_LDT_SEG_SEL)
        if (self.ldtr):
            if (not self.segments.gdt.getEntry(&gdtEntry, self.ldtr&0xfff8)):
                #self.main.notice("Registers::switchTSS32: gdtEntry is invalid, mark LDTR as invalid.")
                (<Gdt>self.segments.ldt).loadTablePosition(0, 0)
            else:
                (<Gdt>self.segments.ldt).loadTablePosition(gdtEntry.base, gdtEntry.limit)
        else:
            (<Gdt>self.segments.ldt).loadTablePosition(0, 0)
        self.segWriteSegment(&self.segments.cs, self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_32BIT_CS))
        self.regWriteDword(CPU_REGISTER_EIP, self.main.mm.mmPhyReadValueUnsignedDword(baseAddress + TSS_32BIT_EIP))
        self.segWriteSegment(&self.segments.ss, self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_32BIT_SS))
        self.regs[CPU_REGISTER_ESP]._union.dword.erx = self.main.mm.mmPhyReadValueUnsignedDword(baseAddress + TSS_32BIT_ESP)
        self.regWriteDword(CPU_REGISTER_EFLAGS, self.main.mm.mmPhyReadValueUnsignedDword(baseAddress + TSS_32BIT_EFLAGS))
        if (self.readFlags()):
            self.main.cpu.asyncEvent = True
        self.segWriteSegment(&self.segments.ds, self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_32BIT_DS))
        self.segWriteSegment(&self.segments.es, self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_32BIT_ES))
        self.segWriteSegment(&self.segments.fs, self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_32BIT_FS))
        self.segWriteSegment(&self.segments.gs, self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_32BIT_GS))
        self.regs[CPU_REGISTER_EAX]._union.dword.erx = self.main.mm.mmPhyReadValueUnsignedDword(baseAddress + TSS_32BIT_EAX)
        self.regs[CPU_REGISTER_ECX]._union.dword.erx = self.main.mm.mmPhyReadValueUnsignedDword(baseAddress + TSS_32BIT_ECX)
        self.regs[CPU_REGISTER_EDX]._union.dword.erx = self.main.mm.mmPhyReadValueUnsignedDword(baseAddress + TSS_32BIT_EDX)
        self.regs[CPU_REGISTER_EBX]._union.dword.erx = self.main.mm.mmPhyReadValueUnsignedDword(baseAddress + TSS_32BIT_EBX)
        self.regs[CPU_REGISTER_EBP]._union.dword.erx = self.main.mm.mmPhyReadValueUnsignedDword(baseAddress + TSS_32BIT_EBP)
        self.regs[CPU_REGISTER_ESI]._union.dword.erx = self.main.mm.mmPhyReadValueUnsignedDword(baseAddress + TSS_32BIT_ESI)
        self.regs[CPU_REGISTER_EDI]._union.dword.erx = self.main.mm.mmPhyReadValueUnsignedDword(baseAddress + TSS_32BIT_EDI)
        self.regs[CPU_REGISTER_CR0]._union.dword.erx |= CR0_FLAG_TS
        #IF (CPU_CACHE_SIZE):
        #    self.reloadCpuCache()
        #self.main.cpu.cpuDump()
        #self.main.notice("Registers::switchTSS32: TODO? (getCPL(): %u; cpl: %u)", self.getCPL(), self.cpl)
        if ((self.main.mm.mmPhyReadValueUnsignedByte(baseAddress + TSS_32BIT_T_FLAG) & 1) != 0):
            self.main.notice("Registers::switchTSS32: Debug")
            raise HirnwichseException(CPU_EXCEPTION_DB)
        return True
    cdef uint8_t saveTSS32(self) except BITMASK_BYTE_CONST:
        cdef uint32_t baseAddress
        #self.main.notice("Registers::saveTSS32: TODO? (savedEip: 0x%08x, savedCs: 0x%04x)", self.main.cpu.savedEip, self.main.cpu.savedCs)
        #self.main.cpu.cpuDump()
        #self.main.notice("Registers::saveTSS32: TODO? (getCPL(): %u; cpl: %u)", self.getCPL(), self.cpl)
        baseAddress = self.mmGetRealAddr(0, 1, &self.segments.tss, False, True, False)
        if (((baseAddress&0xfff)+TSS_MIN_32BIT_HARD_LIMIT) > 0xfff):
            self.main.exitError("Registers::saveTSS32: TSS is over page boundary!")
            return False
        #self.main.debugEnabled = True
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_32BIT_EAX, self.regs[CPU_REGISTER_EAX]._union.dword.erx, OP_SIZE_DWORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_32BIT_ECX, self.regs[CPU_REGISTER_ECX]._union.dword.erx, OP_SIZE_DWORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_32BIT_EDX, self.regs[CPU_REGISTER_EDX]._union.dword.erx, OP_SIZE_DWORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_32BIT_EBX, self.regs[CPU_REGISTER_EBX]._union.dword.erx, OP_SIZE_DWORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_32BIT_EBP, self.regs[CPU_REGISTER_EBP]._union.dword.erx, OP_SIZE_DWORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_32BIT_ESI, self.regs[CPU_REGISTER_ESI]._union.dword.erx, OP_SIZE_DWORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_32BIT_EDI, self.regs[CPU_REGISTER_EDI]._union.dword.erx, OP_SIZE_DWORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_32BIT_ES, self.regs[CPU_SEGMENT_BASE+CPU_SEGMENT_ES]._union.word._union.rx, OP_SIZE_WORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_32BIT_CS, self.regs[CPU_SEGMENT_BASE+CPU_SEGMENT_CS]._union.word._union.rx, OP_SIZE_WORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_32BIT_DS, self.regs[CPU_SEGMENT_BASE+CPU_SEGMENT_DS]._union.word._union.rx, OP_SIZE_WORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_32BIT_FS, self.regs[CPU_SEGMENT_BASE+CPU_SEGMENT_FS]._union.word._union.rx, OP_SIZE_WORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_32BIT_GS, self.regs[CPU_SEGMENT_BASE+CPU_SEGMENT_GS]._union.word._union.rx, OP_SIZE_WORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_32BIT_EIP, self.regs[CPU_REGISTER_EIP]._union.dword.erx, OP_SIZE_DWORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_32BIT_EFLAGS, self.readFlags(), OP_SIZE_DWORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_32BIT_ESP, self.regs[CPU_REGISTER_ESP]._union.dword.erx, OP_SIZE_DWORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_32BIT_SS, self.regs[CPU_SEGMENT_BASE+CPU_SEGMENT_SS]._union.word._union.rx, OP_SIZE_WORD)
        return True
    cdef void run(self):
        self.segments.run()
        self.fpu.run()



