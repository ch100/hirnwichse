
# cython: language_level=3, boundscheck=False, wraparound=False, cdivision=True, profile=True

include "globals.pxi"
include "cpu_globals.pxi"

from misc import HirnwichseException


# Parity Flag Table: DO NOT EDIT!!!
cdef unsigned char PARITY_TABLE[256]
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
    cdef unsigned char modRMOperands(self, unsigned char regSize, unsigned char modRMflags) except BITMASK_BYTE: # regSize in bytes
        cdef unsigned char modRMByte, index
        modRMByte = self.registers.getCurrentOpcodeAddUnsignedByte()
        self.rmNameSeg = (<Segment>self.registers.segments.ds)
        self.rmName1 = CPU_REGISTER_NONE
        self.rmName2 = 0
        self.rm  = modRMByte&0x7
        self.reg = (modRMByte>>3)&0x7
        self.mod = (modRMByte>>6)&0x3
        self.ss = 0
        self.regName = self.registers.getRegNameWithFlags(modRMflags, self.reg, regSize) # reg
        if (self.mod == 3): # if mod==3, then: reg is source ; rm is dest
            self.regSize = regSize
            self.rmName0 = self.rm # rm
            if (regSize == OP_SIZE_BYTE):
                self.rmName0 &= 3
        else:
            self.regSize = self.registers.addrSize
            if (self.regSize == OP_SIZE_WORD):
                self.rmName0 = CPU_MODRM_16BIT_RM0[self.rm]
                self.rmName1 = CPU_MODRM_16BIT_RM1[self.rm]
                if (self.mod == 0 and self.rm == 6):
                    self.rmName0 = CPU_REGISTER_NONE
                    self.rmName2 = self.registers.getCurrentOpcodeAddUnsignedWord()
                elif (self.mod == 1):
                    self.rmName2 = self.registers.getCurrentOpcodeAddSignedByte()
                elif (self.mod == 2):
                    self.rmName2 = self.registers.getCurrentOpcodeAddUnsignedWord()
            elif (self.regSize == OP_SIZE_DWORD):
                if (self.rm == 4): # If RM==4; then SIB
                    modRMByte = self.registers.getCurrentOpcodeAddUnsignedByte()
                    self.rm  = modRMByte&0x7
                    index   = (modRMByte>>3)&7
                    self.ss = (modRMByte>>6)&3
                    if (index != 4):
                        self.rmName1 = index
                self.rmName0 = self.rm
                if (self.mod == 0 and self.rm == 5):
                    self.rmName0 = CPU_REGISTER_NONE
                    self.rmName2 = self.registers.getCurrentOpcodeAddUnsignedDword()
                elif (self.mod == 1):
                    self.rmName2 = self.registers.getCurrentOpcodeAddSignedByte()
                elif (self.mod == 2):
                    self.rmName2 = self.registers.getCurrentOpcodeAddUnsignedDword()
            if (self.rmName0 in (CPU_REGISTER_ESP, CPU_REGISTER_EBP)):
                self.rmNameSeg = (<Segment>self.registers.segments.ss)
        return True
    cdef unsigned long int getRMValueFull(self, unsigned char rmSize):
        cdef unsigned long int retAddr = 0
        if (self.rmName0 != CPU_REGISTER_NONE):
            if (self.regSize in (OP_SIZE_BYTE, OP_SIZE_WORD)):
                retAddr = self.registers.regReadUnsignedWord(self.rmName0)
                if (self.regSize == OP_SIZE_BYTE):
                    if (self.rm >= 4):
                        retAddr >>= 8
                    retAddr = <unsigned char>retAddr
            elif (self.regSize == OP_SIZE_DWORD):
                retAddr = self.registers.regReadUnsignedDword(self.rmName0)
            elif (self.regSize == OP_SIZE_QWORD):
                retAddr = self.registers.regReadUnsignedQword(self.rmName0)
        if (self.rmName1 != CPU_REGISTER_NONE):
            retAddr += self.registers.regReadUnsigned(self.rmName1, self.regSize)<<self.ss
        retAddr += self.rmName2
        if (rmSize == OP_SIZE_BYTE):
            return <unsigned char>retAddr
        elif (rmSize == OP_SIZE_WORD):
            return <unsigned short>retAddr
        elif (rmSize == OP_SIZE_DWORD):
            return <unsigned int>retAddr
        return retAddr
    cdef signed long int modRMLoadSigned(self, unsigned char regSize) except? BITMASK_BYTE:
        # NOTE: imm == unsigned ; disp == signed
        cdef unsigned long int mmAddr
        cdef signed long int returnInt
        if (self.mod == 3):
            if (regSize == OP_SIZE_BYTE):
                if (self.rm <= 3):
                    returnInt = self.registers.regReadSignedLowByte(self.rmName0)
                else: #elif (self.rm >= 4):
                    returnInt = self.registers.regReadSignedHighByte(self.rmName0)
            elif (regSize == OP_SIZE_WORD):
                returnInt = self.registers.regReadSignedWord(self.rmName0)
            elif (regSize == OP_SIZE_DWORD):
                returnInt = self.registers.regReadSignedDword(self.rmName0)
            elif (regSize == OP_SIZE_QWORD):
                returnInt = self.registers.regReadSignedQword(self.rmName0)
        else:
            mmAddr = self.getRMValueFull(self.regSize)
            returnInt = self.registers.mmReadValueSigned(mmAddr, regSize, self.rmNameSeg, True)
        return returnInt
    cdef unsigned long int modRMLoadUnsigned(self, unsigned char regSize) except? BITMASK_BYTE:
        # NOTE: imm == unsigned ; disp == signed
        cdef unsigned long int mmAddr, returnInt
        if (self.mod == 3):
            if (regSize == OP_SIZE_BYTE):
                if (self.rm <= 3):
                    returnInt = self.registers.regReadUnsignedLowByte(self.rmName0)
                else: #elif (self.rm >= 4):
                    returnInt = self.registers.regReadUnsignedHighByte(self.rmName0)
            elif (regSize == OP_SIZE_WORD):
                returnInt = self.registers.regReadUnsignedWord(self.rmName0)
            elif (regSize == OP_SIZE_DWORD):
                returnInt = self.registers.regReadUnsignedDword(self.rmName0)
            elif (regSize == OP_SIZE_QWORD):
                returnInt = self.registers.regReadUnsignedQword(self.rmName0)
        else:
            mmAddr = self.getRMValueFull(self.regSize)
            returnInt = self.registers.mmReadValueUnsigned(mmAddr, regSize, self.rmNameSeg, True)
        return returnInt
    cdef unsigned long int modRMSave(self, unsigned char regSize, unsigned long int value, unsigned char valueOp) except? BITMASK_BYTE:
        # stdValueOp==OPCODE_SAVE
        cdef unsigned long int mmAddr
        if (self.mod != 3):
            mmAddr = self.getRMValueFull(self.regSize)
        if (regSize == OP_SIZE_BYTE):
            value = <unsigned char>value
            if (self.mod == 3):
                if (self.rm <= 3):
                    return self.registers.regWriteWithOpLowByte(self.rmName0, value, valueOp)
                else: # self.rm >= 4
                    return self.registers.regWriteWithOpHighByte(self.rmName0, value, valueOp)
            return <unsigned char>self.registers.mmWriteValueWithOp(mmAddr, value, regSize, self.rmNameSeg, True, valueOp)
        elif (regSize == OP_SIZE_WORD):
            value = <unsigned short>value
            if (self.mod == 3):
                return self.registers.regWriteWithOpWord(self.rmName0, value, valueOp)
            return <unsigned short>self.registers.mmWriteValueWithOp(mmAddr, value, regSize, self.rmNameSeg, True, valueOp)
        elif (regSize == OP_SIZE_DWORD):
            value = <unsigned int>value
            if (self.mod == 3):
                return self.registers.regWriteWithOpDword(self.rmName0, value, valueOp)
            return <unsigned int>self.registers.mmWriteValueWithOp(mmAddr, value, regSize, self.rmNameSeg, True, valueOp)
        elif (regSize == OP_SIZE_QWORD):
            if (self.mod == 3):
                return self.registers.regWriteWithOpQword(self.rmName0, value, valueOp)
            return self.registers.mmWriteValueWithOp(mmAddr, value, regSize, self.rmNameSeg, True, valueOp)
        self.registers.main.exitError("ModRMClass::modRMSave: if; else.")
        return 0
    cdef signed long int modRLoadSigned(self, unsigned char regSize):
        cdef signed long int retVal = 0
        if (regSize == OP_SIZE_BYTE):
            if (self.reg <= 3):
                retVal = self.registers.regReadSignedLowByte(self.regName)
            else: #elif (self.reg >= 4):
                retVal = self.registers.regReadSignedHighByte(self.regName)
        elif (regSize == OP_SIZE_WORD):
            retVal = self.registers.regReadSignedWord(self.regName)
        elif (regSize == OP_SIZE_DWORD):
            retVal = self.registers.regReadSignedDword(self.regName)
        elif (regSize == OP_SIZE_QWORD):
            retVal = self.registers.regReadSignedQword(self.regName)
        return retVal
    cdef unsigned long int modRLoadUnsigned(self, unsigned char regSize):
        cdef unsigned long int retVal = 0
        if (regSize == OP_SIZE_BYTE):
            if (self.reg <= 3):
                retVal = self.registers.regReadUnsignedLowByte(self.regName)
            else: #elif (self.reg >= 4):
                retVal = self.registers.regReadUnsignedHighByte(self.regName)
        elif (regSize == OP_SIZE_WORD):
            retVal = self.registers.regReadUnsignedWord(self.regName)
        elif (regSize == OP_SIZE_DWORD):
            retVal = self.registers.regReadUnsignedDword(self.regName)
        elif (regSize == OP_SIZE_QWORD):
            retVal = self.registers.regReadUnsignedQword(self.regName)
        return retVal
    cdef unsigned long int modRSave(self, unsigned char regSize, unsigned long int value, unsigned char valueOp):
        if (regSize == OP_SIZE_BYTE):
            value = <unsigned char>value
            if (self.reg <= 3):
                return self.registers.regWriteWithOpLowByte(self.regName, value, valueOp)
            else: #elif (self.reg >= 4):
                return self.registers.regWriteWithOpHighByte(self.regName, value, valueOp)
        elif (regSize == OP_SIZE_WORD):
            value = <unsigned short>value
            return self.registers.regWriteWithOpWord(self.regName, value, valueOp)
        elif (regSize == OP_SIZE_DWORD):
            value = <unsigned int>value
            return self.registers.regWriteWithOpDword(self.regName, value, valueOp)
        elif (regSize == OP_SIZE_QWORD):
            return self.registers.regWriteWithOpQword(self.regName, value, valueOp)



cdef class Registers:
    def __init__(self, Hirnwichse main):
        self.main = main
    cdef void reset(self):
        self.operSize = self.addrSize = self.cf = self.pf = self.af = self.zf = self.sf = self.tf = \
          self.if_flag = self.df = self.of = self.iopl = self.nt = self.rf = self.vm = self.ac = \
          self.vif = self.vip = self.id = self.cpl = self.protectedModeOn = self.pagingOn = writeProtectionOn = self.A20Active = self.ssInhibit = self.cacheDisabled = self.cpuCacheBase = self.cpuCacheIndex = 0
        self.cpuCache = b''
        self.resetPrefixes()
        self.segments.reset()
        self.regWriteDwordEflags(FLAG_REQUIRED)
        #self.regWriteDword(CPU_REGISTER_CR0, 0x40000014)
        self.regWriteDword(CPU_REGISTER_CR0, 0x60000010)
        #self.regWriteDword(CPU_REGISTER_CR0, 0x60000024)
        self.regWriteDword(CPU_REGISTER_DR6, 0xffff1ff0)
        self.regWriteDword(CPU_REGISTER_DR7, 0x400)
        self.regWriteDword(CPU_REGISTER_EDX, 0x421)
        self.segWriteSegment((<Segment>self.segments.cs), 0xf000)
        self.regWriteDword(CPU_REGISTER_EIP, 0xfff0)
    cdef void resetPrefixes(self):
        self.operandSizePrefix = self.addressSizePrefix = self.repPrefix = 0
        self.segmentOverridePrefix = None
    cdef void reloadCpuCache(self):
        IF (CPU_CACHE_SIZE):
            cdef unsigned int mmAddr
            mmAddr = self.mmGetRealAddr(self.regs[CPU_REGISTER_EIP]._union.dword.erx, CPU_CACHE_SIZE, (<Segment>self.segments.cs), False, False)
            self.cpuCache = self.main.mm.mmPhyRead(mmAddr, CPU_CACHE_SIZE)
            self.cpuCacheBase = mmAddr
            self.cpuCacheIndex = 0
        ELSE:
            pass
    cdef void setA20Active(self, unsigned char A20Active):
        self.A20Active = A20Active
        self.reloadCpuCache()
    cdef signed long int readFromCacheAddSigned(self, unsigned char numBytes):
        cdef signed long int retVal
        retVal = int.from_bytes(self.cpuCache[self.cpuCacheIndex:self.cpuCacheIndex+numBytes], byteorder="little", signed=True)
        self.cpuCacheIndex += numBytes
        if (self.cpuCacheIndex >= CPU_CACHE_SIZE):
            self.reloadCpuCache()
        return retVal
    cdef unsigned long int readFromCacheAddUnsigned(self, unsigned char numBytes):
        cdef unsigned long int retVal
        retVal = int.from_bytes(self.cpuCache[self.cpuCacheIndex:self.cpuCacheIndex+numBytes], byteorder="little", signed=False)
        self.cpuCacheIndex += numBytes
        if (self.cpuCacheIndex >= CPU_CACHE_SIZE):
            self.reloadCpuCache()
        return retVal
    cdef unsigned long int readFromCacheUnsigned(self, unsigned char numBytes):
        cdef unsigned long int retVal
        retVal = int.from_bytes(self.cpuCache[self.cpuCacheIndex:self.cpuCacheIndex+numBytes], byteorder="little", signed=False)
        if (self.cpuCacheIndex+numBytes >= CPU_CACHE_SIZE):
            self.reloadCpuCache()
        return retVal
    cdef void readCodeSegSize(self):
        self.operSize = ((((self.codeSegSize==OP_SIZE_WORD)==self.operandSizePrefix) and OP_SIZE_DWORD) or OP_SIZE_WORD)
        self.addrSize = ((((self.codeSegSize==OP_SIZE_WORD)==self.addressSizePrefix) and OP_SIZE_DWORD) or OP_SIZE_WORD)
    cdef unsigned int readFlags(self):
        return (FLAG_REQUIRED | self.cf | (self.pf<<2) | (self.af<<4) | (self.zf<<6) | (self.sf<<7) | (self.tf<<8) | (self.if_flag<<9) | (self.df<<10) | \
          (self.of<<11) | (self.iopl<<12) | (self.nt<<14) | (self.rf<<16) | (self.vm<<17) | (self.ac<<18) | (self.vif<<19) | (self.vip<<20) | (self.id<<21))
    cdef void setFlags(self, unsigned int flags):
        cdef unsigned char ifEnabled
        self.cf = (flags&FLAG_CF)!=0
        self.pf = (flags&FLAG_PF)!=0
        self.af = (flags&FLAG_AF)!=0
        self.zf = (flags&FLAG_ZF)!=0
        self.sf = (flags&FLAG_SF)!=0
        self.tf = (flags&FLAG_TF)!=0
        ifEnabled = ((not self.if_flag) and ((flags&FLAG_IF)!=0))
        self.if_flag = (flags&FLAG_IF)!=0
        self.df = (flags&FLAG_DF)!=0
        self.of = (flags&FLAG_OF)!=0
        self.iopl = (flags>>12)&3
        self.nt = (flags&FLAG_NT)!=0
        self.rf = (flags&FLAG_RF)!=0
        self.vm = (flags&FLAG_VM)!=0
        self.ac = (flags&FLAG_AC)!=0
        self.vif = (flags&FLAG_VIF)!=0
        self.vip = (flags&FLAG_VIP)!=0
        self.id = (flags&FLAG_ID)!=0
        if (ifEnabled):
            self.main.cpu.asyncEvent = True
    cdef unsigned char getCPL(self):
        if (self.vm):
            return 3
        return self.cpl
    cdef unsigned char getIOPL(self):
        return self.iopl
    cdef void syncCR0State(self):
        self.protectedModeOn = self.getFlagDword(CPU_REGISTER_CR0, CR0_FLAG_PE) != 0
    cdef unsigned char getCurrentOpcodeUnsignedByte(self) except? BITMASK_BYTE:
        IF (CPU_CACHE_SIZE):
            return <unsigned char>self.readFromCacheUnsigned(OP_SIZE_BYTE)
        ELSE:
            cdef unsigned int opcodeAddr
            opcodeAddr = self.regs[CPU_REGISTER_EIP]._union.dword.erx
            (<Paging>(<Segments>self.segments).paging).setInstrFetch()
            return self.mmReadValueUnsignedByte(opcodeAddr, (<Segment>self.segments.cs), False)
    cdef signed long int getCurrentOpcodeAddSigned(self, unsigned char numBytes) except? BITMASK_BYTE:
        IF (CPU_CACHE_SIZE):
            self.regs[CPU_REGISTER_EIP]._union.dword.erx += numBytes
            return self.readFromCacheAddSigned(numBytes)
        ELSE:
            cdef unsigned int opcodeAddr
            opcodeAddr = self.regs[CPU_REGISTER_EIP]._union.dword.erx
            self.regs[CPU_REGISTER_EIP]._union.dword.erx += numBytes
            (<Paging>(<Segments>self.segments).paging).setInstrFetch()
            return self.mmReadValueSigned(opcodeAddr, numBytes, (<Segment>self.segments.cs), False)
    cdef unsigned char getCurrentOpcodeAddUnsignedByte(self) except? BITMASK_BYTE:
        IF (CPU_CACHE_SIZE):
            self.regs[CPU_REGISTER_EIP]._union.dword.erx += OP_SIZE_BYTE
            return <unsigned char>self.readFromCacheAddUnsigned(OP_SIZE_BYTE)
        ELSE:
            cdef unsigned int opcodeAddr
            opcodeAddr = self.regs[CPU_REGISTER_EIP]._union.dword.erx
            self.regs[CPU_REGISTER_EIP]._union.dword.erx += OP_SIZE_BYTE
            (<Paging>(<Segments>self.segments).paging).setInstrFetch()
            return self.mmReadValueUnsignedByte(opcodeAddr, (<Segment>self.segments.cs), False)
    cdef unsigned short getCurrentOpcodeAddUnsignedWord(self) except? BITMASK_BYTE:
        IF (CPU_CACHE_SIZE):
            self.regs[CPU_REGISTER_EIP]._union.dword.erx += OP_SIZE_WORD
            return <unsigned short>self.readFromCacheAddUnsigned(OP_SIZE_WORD)
        ELSE:
            cdef unsigned int opcodeAddr
            opcodeAddr = self.regs[CPU_REGISTER_EIP]._union.dword.erx
            self.regs[CPU_REGISTER_EIP]._union.dword.erx += OP_SIZE_WORD
            (<Paging>(<Segments>self.segments).paging).setInstrFetch()
            return self.mmReadValueUnsignedWord(opcodeAddr, (<Segment>self.segments.cs), False)
    cdef unsigned int getCurrentOpcodeAddUnsignedDword(self) except? BITMASK_BYTE:
        IF (CPU_CACHE_SIZE):
            self.regs[CPU_REGISTER_EIP]._union.dword.erx += OP_SIZE_DWORD
            return <unsigned int>self.readFromCacheAddUnsigned(OP_SIZE_DWORD)
        ELSE:
            cdef unsigned int opcodeAddr
            opcodeAddr = self.regs[CPU_REGISTER_EIP]._union.dword.erx
            self.regs[CPU_REGISTER_EIP]._union.dword.erx += OP_SIZE_DWORD
            (<Paging>(<Segments>self.segments).paging).setInstrFetch()
            return self.mmReadValueUnsignedDword(opcodeAddr, (<Segment>self.segments.cs), False)
    cdef unsigned long int getCurrentOpcodeAddUnsignedQword(self) except? BITMASK_BYTE:
        IF (CPU_CACHE_SIZE):
            self.regs[CPU_REGISTER_EIP]._union.dword.erx += OP_SIZE_QWORD
            return self.readFromCacheAddUnsigned(OP_SIZE_QWORD)
        ELSE:
            cdef unsigned int opcodeAddr
            opcodeAddr = self.regs[CPU_REGISTER_EIP]._union.dword.erx
            self.regs[CPU_REGISTER_EIP]._union.dword.erx += OP_SIZE_QWORD
            (<Paging>(<Segments>self.segments).paging).setInstrFetch()
            return self.mmReadValueUnsignedQword(opcodeAddr, (<Segment>self.segments.cs), False)
    cdef unsigned long int getCurrentOpcodeAddUnsigned(self, unsigned char numBytes) except? BITMASK_BYTE:
        IF (CPU_CACHE_SIZE):
            self.regs[CPU_REGISTER_EIP]._union.dword.erx += numBytes
            return self.readFromCacheAddUnsigned(numBytes)
        ELSE:
            cdef unsigned int opcodeAddr
            opcodeAddr = self.regs[CPU_REGISTER_EIP]._union.dword.erx
            self.regs[CPU_REGISTER_EIP]._union.dword.erx += numBytes
            (<Paging>(<Segments>self.segments).paging).setInstrFetch()
            return self.mmReadValueUnsigned(opcodeAddr, numBytes, (<Segment>self.segments.cs), False)
    cdef unsigned short segRead(self, unsigned short segId) except? BITMASK_BYTE:
        return self.regs[CPU_SEGMENT_BASE+segId]._union.word._union.rx
    cdef unsigned short segWrite(self, unsigned short segId, unsigned short segValue) except? BITMASK_BYTE:
        cdef Segment segment
        cdef unsigned char protectedModeOn, segType
        protectedModeOn = (self.protectedModeOn and not self.vm)
        if (protectedModeOn and segValue > 3):
            segType = self.segments.getSegType(segValue)
            if (segType & GDT_ACCESS_NORMAL_SEGMENT and not (segType & GDT_ACCESS_ACCESSED)):
                segType |= GDT_ACCESS_ACCESSED
                self.segments.setSegType(segValue, segType)
        segment = self.segments.getSegment(segId, False)
        segment.loadSegment(segValue, False)
        if (protectedModeOn):
            if (not (<Segments>self.segments).checkSegmentLoadAllowed(segValue, segId)):
                segment.isValid = False
        if (segId == CPU_SEGMENT_CS):
            self.codeSegSize = segment.segSize
            if (self.vm):
                self.cpl = 3
            elif (segment.isValid and segment.useGDT):
                self.cpl = segValue & 0x3
            else:
                self.cpl = 0
        elif (segId == CPU_SEGMENT_SS):
            self.ssInhibit = True
        self.regs[CPU_SEGMENT_BASE+segId]._union.word._union.rx = segValue
        return segValue
    cdef unsigned short segWriteSegment(self, Segment segment, unsigned short segValue) except? BITMASK_BYTE:
        cdef unsigned short segId
        cdef unsigned char protectedModeOn, segType
        protectedModeOn = (self.protectedModeOn and not self.vm)
        if (protectedModeOn and segValue > 3):
            segType = self.segments.getSegType(segValue)
            if (segType & GDT_ACCESS_NORMAL_SEGMENT and not (segType & GDT_ACCESS_ACCESSED)):
                segType |= GDT_ACCESS_ACCESSED
                self.segments.setSegType(segValue, segType)
        segId = segment.segId
        segment.loadSegment(segValue, False)
        if (protectedModeOn):
            if (not (<Segments>self.segments).checkSegmentLoadAllowed(segValue, segId)):
                segment.isValid = False
        if (segId == CPU_SEGMENT_CS):
            self.codeSegSize = segment.segSize
            if (self.vm):
                self.cpl = 3
            elif (segment.isValid and segment.useGDT):
                self.cpl = segValue & 0x3
            else:
                self.cpl = 0
        elif (segId == CPU_SEGMENT_SS):
            self.ssInhibit = True
        self.regs[CPU_SEGMENT_BASE+segId]._union.word._union.rx = segValue
        return segValue
    cdef signed long int regReadSigned(self, unsigned short regId, unsigned char regSize):
        if (regSize == OP_SIZE_BYTE):
            return self.regReadSignedLowByte(regId)
        elif (regSize == OP_SIZE_WORD):
            return self.regReadSignedWord(regId)
        elif (regSize == OP_SIZE_DWORD):
            return self.regReadSignedDword(regId)
        elif (regSize == OP_SIZE_QWORD):
            return self.regReadSignedQword(regId)
        return 0
    cdef unsigned long int regReadUnsigned(self, unsigned short regId, unsigned char regSize):
        if (regSize == OP_SIZE_BYTE):
            return self.regReadUnsignedLowByte(regId)
        elif (regSize == OP_SIZE_WORD):
            if (regId == CPU_REGISTER_FLAGS):
                return <unsigned short>self.readFlags()
            return self.regReadUnsignedWord(regId)
        elif (regSize == OP_SIZE_DWORD):
            if (regId == CPU_REGISTER_EFLAGS):
                return self.readFlags()
            return self.regReadUnsignedDword(regId)
        elif (regSize == OP_SIZE_QWORD):
            #if (regId == CPU_REGISTER_RFLAGS): # this isn't used yet.
            #    return self.readFlags()
            return self.regReadUnsignedQword(regId)
        return 0
    cdef unsigned long int regWrite(self, unsigned short regId, unsigned long int value, unsigned char regSize):
        if (regSize == OP_SIZE_BYTE):
            return self.regWriteLowByte(regId, value)
        elif (regSize == OP_SIZE_WORD):
            if (regId == CPU_REGISTER_FLAGS):
                return self.regWriteWordFlags(<unsigned short>value)
            return self.regWriteWord(regId, value)
        elif (regSize == OP_SIZE_DWORD):
            if (regId == CPU_REGISTER_EFLAGS):
                return self.regWriteDwordEflags(<unsigned int>value)
            return self.regWriteDword(regId, value)
        elif (regSize == OP_SIZE_QWORD):
            if (regId == CPU_REGISTER_RFLAGS):
                return self.regWriteDwordEflags(value)
            return self.regWriteQword(regId, value)
        return 0
    cpdef unsigned int regWriteDword(self, unsigned short regId, unsigned int value):
        IF (CPU_CACHE_SIZE):
            cdef unsigned int realNewEip, tempValue
        ELSE:
            cdef unsigned int tempValue
        if (regId == CPU_REGISTER_CR0):
            value |= 0x10
            value &= 0xe005003f
        self.regs[regId]._union.dword.erx = value
        IF (CPU_CACHE_SIZE):
            if (regId == CPU_REGISTER_EIP):
                realNewEip = self.mmGetRealAddr(self.regs[CPU_REGISTER_EIP]._union.dword.erx, OP_SIZE_DWORD, (<Segment>self.segments.cs), False, False)
                if (realNewEip >= self.cpuCacheBase and realNewEip < self.cpuCacheBase+CPU_CACHE_SIZE):
                    self.cpuCacheIndex = realNewEip - self.cpuCacheBase
                else:
                    self.reloadCpuCache()
        if (regId in (CPU_REGISTER_CR3, CPU_REGISTER_CR4)):
            if (regId == CPU_REGISTER_CR3):
                tempValue = value
            else:
                tempValue = self.regs[CPU_REGISTER_CR3]._union.dword.erx
            #(<Paging>self.segments.paging).invalidateTables(tempValue, True)
            (<Paging>self.segments.paging).invalidateTables(tempValue, False)
            self.reloadCpuCache()
        return value # returned value is unsigned!!
    cdef unsigned long int regAdd(self, unsigned short regId, unsigned long int value, unsigned char regSize):
        if (regSize == OP_SIZE_WORD):
            return self.regAddWord(regId, value)
        elif (regSize == OP_SIZE_DWORD):
            return self.regAddDword(regId, value)
        elif (regSize == OP_SIZE_QWORD):
            return self.regAddQword(regId, value)
        return 0
    cdef unsigned long int regSub(self, unsigned short regId, unsigned long int value, unsigned char regSize):
        if (regSize == OP_SIZE_WORD):
            return self.regSubWord(regId, value)
        elif (regSize == OP_SIZE_DWORD):
            return self.regSubDword(regId, value)
        elif (regSize == OP_SIZE_QWORD):
            return self.regSubQword(regId, value)
        return 0
    cdef unsigned char regWriteWithOpLowByte(self, unsigned short regId, unsigned char value, unsigned char valueOp):
        if (valueOp == OPCODE_SAVE):
            return self.regWriteLowByte(regId, value)
        elif (valueOp == OPCODE_ADD):
            return self.regAddLowByte(regId, value)
        elif (valueOp == OPCODE_ADC):
            return self.regAdcLowByte(regId, value)
        elif (valueOp == OPCODE_SUB):
            return self.regSubLowByte(regId, value)
        elif (valueOp == OPCODE_SBB):
            return self.regSbbLowByte(regId, value)
        elif (valueOp == OPCODE_AND):
            return self.regAndLowByte(regId, value)
        elif (valueOp == OPCODE_OR):
            return self.regOrLowByte(regId, value)
        elif (valueOp == OPCODE_XOR):
            return self.regXorLowByte(regId, value)
        elif (valueOp == OPCODE_NEG):
            value = (-value)
            return self.regWriteLowByte(regId, value)
        elif (valueOp == OPCODE_NOT):
            value = (~value)
            return self.regWriteLowByte(regId, value)
        else:
            self.main.notice("REGISTERS::regWriteWithOpLowByte: unknown valueOp {0:d}.", valueOp)
        return 0
    cdef unsigned char regWriteWithOpHighByte(self, unsigned short regId, unsigned char value, unsigned char valueOp):
        if (valueOp == OPCODE_SAVE):
            return self.regWriteHighByte(regId, value)
        elif (valueOp == OPCODE_ADD):
            return self.regAddHighByte(regId, value)
        elif (valueOp == OPCODE_ADC):
            return self.regAdcHighByte(regId, value)
        elif (valueOp == OPCODE_SUB):
            return self.regSubHighByte(regId, value)
        elif (valueOp == OPCODE_SBB):
            return self.regSbbHighByte(regId, value)
        elif (valueOp == OPCODE_AND):
            return self.regAndHighByte(regId, value)
        elif (valueOp == OPCODE_OR):
            return self.regOrHighByte(regId, value)
        elif (valueOp == OPCODE_XOR):
            return self.regXorHighByte(regId, value)
        elif (valueOp == OPCODE_NEG):
            value = (-value)
            return self.regWriteHighByte(regId, value)
        elif (valueOp == OPCODE_NOT):
            value = (~value)
            return self.regWriteHighByte(regId, value)
        else:
            self.main.notice("REGISTERS::regWriteWithOpHighByte: unknown valueOp {0:d}.", valueOp)
        return 0
    cdef unsigned short regWriteWithOpWord(self, unsigned short regId, unsigned short value, unsigned char valueOp):
        if (valueOp == OPCODE_SAVE):
            return self.regWriteWord(regId, value)
        elif (valueOp == OPCODE_ADD):
            return self.regAddWord(regId, value)
        elif (valueOp == OPCODE_ADC):
            return self.regAdcWord(regId, value)
        elif (valueOp == OPCODE_SUB):
            return self.regSubWord(regId, value)
        elif (valueOp == OPCODE_SBB):
            return self.regSbbWord(regId, value)
        elif (valueOp == OPCODE_AND):
            return self.regAndWord(regId, value)
        elif (valueOp == OPCODE_OR):
            return self.regOrWord(regId, value)
        elif (valueOp == OPCODE_XOR):
            return self.regXorWord(regId, value)
        elif (valueOp == OPCODE_NEG):
            value = (-value)
            return self.regWriteWord(regId, value)
        elif (valueOp == OPCODE_NOT):
            value = (~value)
            return self.regWriteWord(regId, value)
        else:
            self.main.notice("REGISTERS::regWriteWithOpWord: unknown valueOp {0:d}.", valueOp)
        return 0
    cdef unsigned int regWriteWithOpDword(self, unsigned short regId, unsigned int value, unsigned char valueOp):
        if (valueOp == OPCODE_SAVE):
            return self.regWriteDword(regId, value)
        elif (valueOp == OPCODE_ADD):
            return self.regAddDword(regId, value)
        elif (valueOp == OPCODE_ADC):
            return self.regAdcDword(regId, value)
        elif (valueOp == OPCODE_SUB):
            return self.regSubDword(regId, value)
        elif (valueOp == OPCODE_SBB):
            return self.regSbbDword(regId, value)
        elif (valueOp == OPCODE_AND):
            return self.regAndDword(regId, value)
        elif (valueOp == OPCODE_OR):
            return self.regOrDword(regId, value)
        elif (valueOp == OPCODE_XOR):
            return self.regXorDword(regId, value)
        elif (valueOp == OPCODE_NEG):
            value = (-value)
            return self.regWriteDword(regId, value)
        elif (valueOp == OPCODE_NOT):
            value = (~value)
            return self.regWriteDword(regId, value)
        else:
            self.main.notice("REGISTERS::regWriteWithOpDword: unknown valueOp {0:d}.", valueOp)
        return 0
    cdef unsigned long int regWriteWithOpQword(self, unsigned short regId, unsigned long int value, unsigned char valueOp):
        if (valueOp == OPCODE_SAVE):
            return self.regWriteQword(regId, value)
        elif (valueOp == OPCODE_ADD):
            return self.regAddQword(regId, value)
        elif (valueOp == OPCODE_ADC):
            return self.regAdcQword(regId, value)
        elif (valueOp == OPCODE_SUB):
            return self.regSubQword(regId, value)
        elif (valueOp == OPCODE_SBB):
            return self.regSbbQword(regId, value)
        elif (valueOp == OPCODE_AND):
            return self.regAndQword(regId, value)
        elif (valueOp == OPCODE_OR):
            return self.regOrQword(regId, value)
        elif (valueOp == OPCODE_XOR):
            return self.regXorQword(regId, value)
        elif (valueOp == OPCODE_NEG):
            value = (-value)
            return self.regWriteQword(regId, value)
        elif (valueOp == OPCODE_NOT):
            value = (~value)
            return self.regWriteQword(regId, value)
        else:
            self.main.notice("REGISTERS::regWriteWithOpQword: unknown valueOp {0:d}.", valueOp)
        return 0
    cdef void setSZP(self, unsigned int value, unsigned char regSize):
        self.sf = (value>>((regSize<<3)-1))!=0
        self.zf = value==0
        self.pf = PARITY_TABLE[<unsigned char>value]
    cdef void setSZP_O(self, unsigned int value, unsigned char regSize):
        self.setSZP(value, regSize)
        self.of = False
    cdef void setSZP_A(self, unsigned int value, unsigned char regSize):
        self.setSZP(value, regSize)
        self.af = False
    cdef void setSZP_COA(self, unsigned int value, unsigned char regSize):
        self.setSZP(value, regSize)
        self.cf = self.of = self.af = False
    cdef unsigned char getRegNameWithFlags(self, unsigned char modRMflags, unsigned char reg, unsigned char operSize) except BITMASK_BYTE:
        cdef unsigned char regName
        regName = CPU_REGISTER_NONE
        if (modRMflags & MODRM_FLAGS_SREG):
            regName = CPU_REGISTER_SREG[reg]
        elif (modRMflags & MODRM_FLAGS_CREG):
            regName = CPU_REGISTER_CREG[reg]
        elif (modRMflags & MODRM_FLAGS_DREG):
            if (reg in (4, 5) and self.getFlagDword(CPU_REGISTER_CR4, CR4_FLAG_DE) != 0):
                raise HirnwichseException(CPU_EXCEPTION_UD)
            regName = CPU_REGISTER_DREG[reg]
        else:
            regName = reg
            if (operSize == OP_SIZE_BYTE):
                regName &= 3
        if (regName == CPU_REGISTER_NONE):
            raise HirnwichseException(CPU_EXCEPTION_UD)
        return regName
    cdef unsigned char getCond(self, unsigned char index):
        cdef unsigned char origIndex, ret = 0
        origIndex = index
        index >>= 1
        if (index == 0x0): # O
            ret = self.of
        elif (index == 0x1): # B
            ret = self.cf
        elif (index == 0x2): # Z
            ret = self.zf
        elif (index == 0x3): # BE
            ret = self.cf or self.zf
        elif (index == 0x4): # S
            ret = self.sf
        elif (index == 0x5): # P
            ret = self.pf
        elif (index == 0x6): # L
            ret = self.sf != self.of
        elif (index == 0x7): # LE
            ret = self.zf or self.sf != self.of
        else:
            self.main.exitError("getCond: index {0:#04x} is invalid.", index)
        if (origIndex & 0x1):
            ret = not ret
        return ret
    cdef void setFullFlags(self, unsigned long int reg0, unsigned long int reg1, unsigned char regSize, unsigned char method):
        cdef unsigned char unsignedOverflow, reg0Nibble, regSumuNibble, carried
        cdef unsigned int bitMaskHalf
        cdef unsigned long int regSumu
        cdef signed long int regSum
        carried = False
        bitMaskHalf = BITMASKS_80[regSize]
        if (method in (OPCODE_ADD, OPCODE_ADC)):
            if (method == OPCODE_ADC and self.cf):
                carried = True
            if (regSize == OP_SIZE_BYTE):
                reg0 = <unsigned char>reg0
                reg1 = <unsigned char>reg1
                if (carried): reg1 += 1
                regSumu = (reg0+reg1)
                unsignedOverflow = regSumu!=(<unsigned char>regSumu)
                regSumu = <unsigned char>regSumu
            elif (regSize == OP_SIZE_WORD):
                reg0 = <unsigned short>reg0
                reg1 = <unsigned short>reg1
                if (carried): reg1 += 1
                regSumu = (reg0+reg1)
                unsignedOverflow = regSumu!=(<unsigned short>regSumu)
                regSumu = <unsigned short>regSumu
            elif (regSize == OP_SIZE_DWORD):
                reg0 = <unsigned int>reg0
                reg1 = <unsigned int>reg1
                if (carried): reg1 += 1
                regSumu = (reg0+reg1)
                unsignedOverflow = regSumu!=(<unsigned int>regSumu)
                regSumu = <unsigned int>regSumu
            self.pf = PARITY_TABLE[<unsigned char>regSumu]
            self.zf = not regSumu
            reg0Nibble = reg0&0xf
            regSumuNibble = regSumu&0xf
            reg0 &= bitMaskHalf
            reg1 &= bitMaskHalf
            regSumu &= bitMaskHalf
            self.af = (regSumuNibble<(reg0Nibble+carried))
            self.cf = unsignedOverflow
            self.of = (reg0==reg1 and reg0!=regSumu)
            self.sf = regSumu!=0
        elif (method in (OPCODE_SUB, OPCODE_SBB)):
            if (method == OPCODE_SBB and self.cf):
                carried = True
                reg1 += 1
            regSumu = <unsigned int>(reg0-reg1)
            if (regSize == OP_SIZE_BYTE):
                regSumu = <unsigned char>regSumu
            elif (regSize == OP_SIZE_WORD):
                regSumu = <unsigned short>regSumu
            unsignedOverflow = ((regSumu+carried) > reg0)
            self.pf = PARITY_TABLE[<unsigned char>regSumu]
            self.zf = not regSumu
            reg0Nibble = reg0&0xf
            regSumuNibble = regSumu&0xf
            reg0 &= bitMaskHalf
            reg1 &= bitMaskHalf
            regSumu &= bitMaskHalf
            self.af = ((regSumuNibble+carried)>reg0Nibble)
            self.cf = unsignedOverflow
            self.of = (reg0!=reg1 and reg1==regSumu)
            self.sf = regSumu!=0
        elif (method in (OPCODE_MUL, OPCODE_IMUL)):
            if (regSize == OP_SIZE_BYTE):
                reg1 = <unsigned char>reg1
                if (method == OPCODE_MUL):
                    reg0 = <unsigned char>reg0
                    regSumu = (reg0*reg1)
                    unsignedOverflow = (<unsigned short>regSumu)!=(<unsigned char>regSumu)
                else:
                    reg0 = <signed char>reg0
                    regSumu = regSum = (reg0*reg1)
                    unsignedOverflow = (<signed short>regSum)!=(<signed char>regSum)
                regSumu = <unsigned char>regSumu
            elif (regSize == OP_SIZE_WORD):
                reg1 = <unsigned short>reg1
                if (method == OPCODE_MUL):
                    reg0 = <unsigned short>reg0
                    regSumu = (reg0*reg1)
                    unsignedOverflow = (<unsigned int>regSumu)!=(<unsigned short>regSumu)
                else:
                    reg0 = <signed short>reg0
                    regSumu = regSum = (reg0*reg1)
                    unsignedOverflow = (<signed int>regSum)!=(<signed short>regSum)
                regSumu = <unsigned short>regSumu
            elif (regSize == OP_SIZE_DWORD):
                reg1 = <unsigned int>reg1
                if (method == OPCODE_MUL):
                    reg0 = <unsigned int>reg0
                    regSumu = (reg0*reg1)
                    unsignedOverflow = (<unsigned long int>regSumu)!=(<unsigned int>regSumu)
                else:
                    reg0 = <signed int>reg0
                    regSumu = regSum = (reg0*reg1)
                    unsignedOverflow = (<signed long int>regSum)!=(<signed int>regSum)
                regSumu = <unsigned int>regSumu
            self.af = False
            self.cf = self.of = unsignedOverflow
            self.pf = PARITY_TABLE[<unsigned char>regSumu]
            self.zf = not regSumu
            self.sf = (regSumu & bitMaskHalf) != 0
    cdef unsigned char checkMemAccessRights(self, unsigned int mmAddr, unsigned int dataSize, Segment segment, unsigned char written) except BITMASK_BYTE:
        cdef unsigned char addrInLimit
        cdef unsigned short segId, segVal
        segId = segment.segId
        segVal = segment.segmentIndex
        if (segment.useGDT):
            if (not (segVal&0xfff8)):
                self.main.notice("Registers::checkMemAccessRights: test1.1")
                if (segId == CPU_SEGMENT_SS):
                    raise HirnwichseException(CPU_EXCEPTION_SS, segVal)
                else:
                    raise HirnwichseException(CPU_EXCEPTION_GP, segVal)
            if (not segment.segPresent):
                self.main.notice("Registers::checkMemAccessRights: test1.2")
                if (segId == CPU_SEGMENT_SS):
                    raise HirnwichseException(CPU_EXCEPTION_SS, segVal)
                else:
                    raise HirnwichseException(CPU_EXCEPTION_NP, segVal)
        addrInLimit = segment.isAddressInLimit(mmAddr, dataSize)
        if (written):
            if ((segment.useGDT and segment.segIsNormal and (segment.segIsCodeSeg or not segment.segIsRW)) or not addrInLimit):
                self.main.notice("Registers::checkMemAccessRights: test1.3")
                self.main.notice("Registers::checkMemAccessRights: test1.3.1; c0=={0:d}; c1=={1:d}; c2=={2:d}", segment.segIsNormal, (segment.segIsCodeSeg or not segment.segIsRW), not addrInLimit)
                self.main.notice("Registers::checkMemAccessRights: test1.3.2; mmAddr=={0:#010x}; dataSize=={1:d}; base=={2:#010x}; limit=={3:#010x}", mmAddr, dataSize, segment.base, segment.limit)
                if (segId == CPU_SEGMENT_SS):
                    raise HirnwichseException(CPU_EXCEPTION_SS, segVal)
                else:
                    raise HirnwichseException(CPU_EXCEPTION_GP, segVal)
        else:
            if ((segment.useGDT and segment.segIsNormal and segment.segIsCodeSeg and not segment.segIsRW) or not addrInLimit):
                self.main.notice("Registers::checkMemAccessRights: test1.4")
                raise HirnwichseException(CPU_EXCEPTION_GP, segVal)
        return True
    cdef unsigned int mmGetRealAddr(self, unsigned int mmAddr, unsigned int dataSize, Segment segment, unsigned char allowOverride, unsigned char written) except? BITMASK_BYTE:
        cdef unsigned int origMmAddr
        origMmAddr = mmAddr
        if (allowOverride and self.segmentOverridePrefix is not None):
            segment = self.segmentOverridePrefix
        #if (self.vm and self.main.debugEnabled):
        #    self.main.debug("Registers::mmGetRealAddr: TODO. (VM is on)")
        if (segment is not None):
            if (self.protectedModeOn and segment is (<Segment>self.segments.tss)):
                (<Paging>(<Segments>self.segments).paging).implicitSV = True
            #if (segment.useGDT):
            self.checkMemAccessRights(mmAddr, dataSize, segment, written)
            mmAddr += segment.base
        # TODO: check for limit asf...
        if (self.protectedModeOn and self.pagingOn): # TODO: is a20 even being applied after paging is enabled? (on the physical address... or even the virtual one?)
            mmAddr = (<Paging>(<Segments>self.segments).paging).getPhysicalAddress(mmAddr, dataSize, written)
        if (not self.A20Active): # A20 Active? if True == on, else off
            mmAddr &= <unsigned int>0xffefffff
        if (self.main.debugEnabled):
            self.main.debug("Registers::mmGetRealAddr: {0:s}: LIN {1:#010x}; PHY {2:#010x}", "WR" if (written) else "RD", origMmAddr, mmAddr)
        return mmAddr
    cdef bytes mmRead(self, unsigned int mmAddr, unsigned int dataSize, Segment segment, unsigned char allowOverride):
        cdef unsigned int tempSize, physAddr
        cdef bytes ret = b''
        physAddr = self.mmGetRealAddr(mmAddr, dataSize, segment, allowOverride, False)
        if (self.protectedModeOn and self.pagingOn and PAGE_DIRECTORY_LENGTH-(physAddr&0xfff) < dataSize):
            if (not dataSize):
                return ret
            while (dataSize > 0):
                tempSize = min(dataSize, PAGE_DIRECTORY_LENGTH)
                if (((mmAddr&0xfff)+tempSize) > PAGE_DIRECTORY_LENGTH):
                    tempSize -= ((mmAddr&0xfff)+tempSize) - PAGE_DIRECTORY_LENGTH
                if (self.main.debugEnabled):
                    self.main.debug("Registers::mmRead: test1: mmAddr {0:#010x}; ret {1:s}; dataSize {2:d}", mmAddr, repr(ret), dataSize)
                physAddr = self.mmGetRealAddr(mmAddr, tempSize, segment, allowOverride, False)
                ret += self.main.mm.mmPhyRead(physAddr, tempSize)
                if (dataSize <= tempSize):
                    break
                mmAddr += tempSize
                dataSize -= tempSize
            return ret
        ret = self.main.mm.mmPhyRead(physAddr, dataSize)
        if (self.main.debugEnabled):
            self.main.debug("Registers::mmRead: test2: virt mmAddr {0:#010x}; ret {1:s}; dataSize {2:d}", mmAddr, repr(ret), dataSize)
        return ret
    cdef signed long int mmReadValueSigned(self, unsigned int mmAddr, unsigned char dataSize, Segment segment, unsigned char allowOverride) except? BITMASK_BYTE:
        cdef unsigned char i
        cdef unsigned int physAddr
        cdef signed long int ret = 0
        physAddr = self.mmGetRealAddr(mmAddr, dataSize, segment, allowOverride, False)
        if (self.protectedModeOn and self.pagingOn and PAGE_DIRECTORY_LENGTH-(physAddr&0xfff) < dataSize):
            for i in range(dataSize):
                ret |= <signed long int>self.mmReadValueUnsignedByte(mmAddr+i, segment, allowOverride)<<(i<<3)
            if (dataSize == OP_SIZE_BYTE):
                return <signed char>ret
            elif (dataSize == OP_SIZE_WORD):
                return <signed short>ret
            elif (dataSize == OP_SIZE_DWORD):
                return <signed int>ret
            return <signed long int>ret
        ret = self.main.mm.mmPhyReadValueSigned(physAddr, dataSize)
        if (self.main.debugEnabled):
            self.main.debug("Registers::mmReadValueSigned: virt mmAddr {0:#010x}; ret {1:#010x}; dataSize {2:d}", mmAddr, ret, dataSize)
        return ret
    cdef unsigned char mmReadValueUnsignedByte(self, unsigned int mmAddr, Segment segment, unsigned char allowOverride) except? BITMASK_BYTE:
        cdef unsigned char ret
        ret = self.main.mm.mmPhyReadValueUnsignedByte(self.mmGetRealAddr(mmAddr, OP_SIZE_BYTE, segment, allowOverride, False))
        if (self.main.debugEnabled):
            self.main.debug("Registers::mmReadValueUnsignedByte: virt mmAddr {0:#010x}; ret {1:#010x}; dataSize {2:d}", mmAddr, ret, OP_SIZE_BYTE)
        return ret
    cdef unsigned short mmReadValueUnsignedWord(self, unsigned int mmAddr, Segment segment, unsigned char allowOverride) except? BITMASK_BYTE:
        cdef unsigned short ret
        cdef unsigned int physAddr
        physAddr = self.mmGetRealAddr(mmAddr, OP_SIZE_WORD, segment, allowOverride, False)
        if (self.protectedModeOn and self.pagingOn and PAGE_DIRECTORY_LENGTH-(physAddr&0xfff) < OP_SIZE_WORD):
            ret = <unsigned short>self.mmReadValueUnsignedByte(mmAddr, segment, allowOverride)
            ret |= <unsigned short>self.mmReadValueUnsignedByte(mmAddr+1, segment, allowOverride)<<8
            return ret
        ret = self.main.mm.mmPhyReadValueUnsignedWord(physAddr)
        if (self.main.debugEnabled):
            self.main.debug("Registers::mmReadValueUnsignedWord: virt mmAddr {0:#010x}; ret {1:#010x}; dataSize {2:d}", mmAddr, ret, OP_SIZE_WORD)
        return ret
    cdef unsigned int mmReadValueUnsignedDword(self, unsigned int mmAddr, Segment segment, unsigned char allowOverride) except? BITMASK_BYTE:
        cdef unsigned int ret, physAddr
        physAddr = self.mmGetRealAddr(mmAddr, OP_SIZE_DWORD, segment, allowOverride, False)
        if (self.protectedModeOn and self.pagingOn and PAGE_DIRECTORY_LENGTH-(physAddr&0xfff) < OP_SIZE_DWORD):
            ret = <unsigned int>self.mmReadValueUnsignedByte(mmAddr, segment, allowOverride)
            ret |= <unsigned int>self.mmReadValueUnsignedByte(mmAddr+1, segment, allowOverride)<<8
            ret |= <unsigned int>self.mmReadValueUnsignedByte(mmAddr+2, segment, allowOverride)<<16
            ret |= <unsigned int>self.mmReadValueUnsignedByte(mmAddr+3, segment, allowOverride)<<24
            return ret
        ret = self.main.mm.mmPhyReadValueUnsignedDword(physAddr)
        if (self.main.debugEnabled):
            self.main.debug("Registers::mmReadValueUnsignedDword: virt mmAddr {0:#010x}; ret {1:#010x}; dataSize {2:d}", mmAddr, ret, OP_SIZE_DWORD)
        return ret
    cdef unsigned long int mmReadValueUnsignedQword(self, unsigned int mmAddr, Segment segment, unsigned char allowOverride) except? BITMASK_BYTE:
        cdef unsigned int physAddr
        cdef unsigned long int ret
        physAddr = self.mmGetRealAddr(mmAddr, OP_SIZE_QWORD, segment, allowOverride, False)
        if (self.protectedModeOn and self.pagingOn and PAGE_DIRECTORY_LENGTH-(physAddr&0xfff) < OP_SIZE_QWORD):
            ret = <unsigned long int>self.mmReadValueUnsignedByte(mmAddr, segment, allowOverride)
            ret |= <unsigned long int>self.mmReadValueUnsignedByte(mmAddr+1, segment, allowOverride)<<8
            ret |= <unsigned long int>self.mmReadValueUnsignedByte(mmAddr+2, segment, allowOverride)<<16
            ret |= <unsigned long int>self.mmReadValueUnsignedByte(mmAddr+3, segment, allowOverride)<<24
            ret |= <unsigned long int>self.mmReadValueUnsignedByte(mmAddr+4, segment, allowOverride)<<32
            ret |= <unsigned long int>self.mmReadValueUnsignedByte(mmAddr+5, segment, allowOverride)<<40
            ret |= <unsigned long int>self.mmReadValueUnsignedByte(mmAddr+6, segment, allowOverride)<<48
            ret |= <unsigned long int>self.mmReadValueUnsignedByte(mmAddr+7, segment, allowOverride)<<56
            return ret
        ret = self.main.mm.mmPhyReadValueUnsignedQword(physAddr)
        if (self.main.debugEnabled):
            self.main.debug("Registers::mmReadValueUnsignedQword: virt mmAddr {0:#010x}; ret {1:#010x}; dataSize {2:d}", mmAddr, ret, OP_SIZE_QWORD)
        return ret
    cdef unsigned long int mmReadValueUnsigned(self, unsigned int mmAddr, unsigned char dataSize, Segment segment, unsigned char allowOverride) except? BITMASK_BYTE:
        cdef unsigned char i
        cdef unsigned int physAddr
        cdef unsigned long int ret = 0
        physAddr = self.mmGetRealAddr(mmAddr, dataSize, segment, allowOverride, False)
        if (self.protectedModeOn and self.pagingOn and PAGE_DIRECTORY_LENGTH-(physAddr&0xfff) < dataSize):
            for i in range(dataSize):
                ret |= <unsigned long int>self.mmReadValueUnsignedByte(mmAddr+i, segment, allowOverride)<<(i<<3)
            return ret
        ret = self.main.mm.mmPhyReadValueUnsigned(physAddr, dataSize)
        if (self.main.debugEnabled):
            self.main.debug("Registers::mmReadValueUnsigned: virt mmAddr {0:#010x}; ret {1:#010x}; dataSize {2:d}", mmAddr, ret, dataSize)
        return ret
    cdef unsigned char mmWrite(self, unsigned int mmAddr, bytes data, unsigned int dataSize, Segment segment, unsigned char allowOverride) except BITMASK_BYTE:
        cdef unsigned char retVal
        cdef unsigned int tempSize, physAddr
        physAddr = self.mmGetRealAddr(mmAddr, dataSize, segment, allowOverride, True)
        if (self.protectedModeOn and self.pagingOn and PAGE_DIRECTORY_LENGTH-(physAddr&0xfff) < dataSize):
            if (not dataSize):
                return True
            while (dataSize > 0):
                tempSize = min(dataSize, PAGE_DIRECTORY_LENGTH)
                if (((mmAddr&0xfff)+tempSize) > PAGE_DIRECTORY_LENGTH):
                    tempSize -= ((mmAddr&0xfff)+tempSize) - PAGE_DIRECTORY_LENGTH
                if (self.main.debugEnabled):
                    self.main.debug("Registers::mmWrite: test1: mmAddr {0:#010x}; data {1:s}; dataSize {2:d}; tempSize {3:d}", mmAddr, repr(data), dataSize, tempSize)
                physAddr = self.mmGetRealAddr(mmAddr, tempSize, segment, allowOverride, True)
                retVal = self.main.mm.mmPhyWrite(physAddr, data, tempSize)
                if (dataSize <= tempSize):
                    break
                mmAddr += tempSize
                dataSize -= tempSize
                data = data[tempSize:]
            return retVal
        if (self.main.debugEnabled):
            self.main.debug("Registers::mmWrite: test2: virt mmAddr {0:#010x}; data {1:s}; dataSize {2:d}", mmAddr, repr(data), dataSize)
        retVal = self.main.mm.mmPhyWrite(physAddr, data, dataSize)
        self.checkCache(mmAddr, dataSize)
        return retVal
    cdef unsigned char mmWriteValue(self, unsigned int mmAddr, unsigned long int data, unsigned char dataSize, Segment segment, unsigned char allowOverride) except BITMASK_BYTE:
        cdef unsigned char retVal, i
        cdef unsigned int physAddr
        physAddr = self.mmGetRealAddr(mmAddr, dataSize, segment, allowOverride, True)
        if (self.main.debugEnabled):
            self.main.debug("Registers::mmWriteValue: virt mmAddr {0:#010x}; data {1:#010x}; dataSize {2:d}", mmAddr, data, dataSize)
        if (self.protectedModeOn and self.pagingOn and PAGE_DIRECTORY_LENGTH-(physAddr&0xfff) < dataSize):
            for i in range(dataSize):
                self.mmWriteValue(mmAddr+i, <unsigned char>data, OP_SIZE_BYTE, segment, allowOverride)
                data >>= 8
            return True
        retVal = self.main.mm.mmPhyWriteValue(physAddr, data, dataSize)
        self.checkCache(mmAddr, dataSize)
        return retVal
    cdef unsigned long int mmWriteValueWithOp(self, unsigned int mmAddr, unsigned long int data, unsigned char dataSize, Segment segment, unsigned char allowOverride, unsigned char valueOp) except? BITMASK_BYTE:
        cdef unsigned long int oldData
        if (valueOp != OPCODE_SAVE):
            if (valueOp == OPCODE_NEG):
                data = (-data)
            elif (valueOp == OPCODE_NOT):
                data = (~data)
            else:
                oldData = self.mmReadValueUnsigned(mmAddr, dataSize, segment, allowOverride)
                if (valueOp == OPCODE_ADD):
                    data = (oldData+data)
                elif (valueOp in (OPCODE_ADC, OPCODE_SBB)):
                    data += self.cf
                    if (valueOp == OPCODE_ADC):
                        data = (oldData+data)
                    else:
                        data = (oldData-data)
                elif (valueOp == OPCODE_SUB):
                    data = (oldData-data)
                elif (valueOp == OPCODE_AND):
                    data = (oldData&data)
                elif (valueOp == OPCODE_OR):
                    data = (oldData|data)
                elif (valueOp == OPCODE_XOR):
                    data = (oldData^data)
                else:
                    self.main.exitError("Registers::mmWriteValueWithOp: unknown valueOp {0:d}.", valueOp)
        if (self.main.debugEnabled):
            self.main.debug("Registers::mmWriteValueWithOp: virt mmAddr {0:#010x}; data {1:#010x}; dataSize {2:d}", mmAddr, data, dataSize)
        self.mmWriteValue(mmAddr, data, dataSize, segment, allowOverride)
        return data
    cdef unsigned char switchTSS16(self) except BITMASK_BYTE:
        cdef unsigned int baseAddress
        cdef GdtEntry gdtEntry
        self.main.notice("Registers::switchTSS16: TODO? (savedEip: {0:#010x}, savedCs: {1:#06x})", self.main.cpu.savedEip, self.main.cpu.savedCs)
        baseAddress = self.mmGetRealAddr(0, 1, (<Segment>self.segments.tss), False, False)
        if (((baseAddress&0xfff)+TSS_MIN_16BIT_HARD_LIMIT) > 0xfff):
            self.main.exitError("Registers::switchTSS16: TSS is over page boundary!")
            return False
        self.segments.ldtr = self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_16BIT_LDT_SEG_SEL)
        if (self.segments.ldtr):
            gdtEntry = <GdtEntry>self.segments.gdt.getEntry(self.segments.ldtr&0xfff8)
            if (gdtEntry is None):
                self.main.notice("Registers::switchTSS16: gdtEntry is invalid, mark LDTR as invalid.")
                (<Gdt>self.segments.ldt).loadTablePosition(0, 0)
            else:
                (<Gdt>self.segments.ldt).loadTablePosition(gdtEntry.base, gdtEntry.limit)
        else:
            (<Gdt>self.segments.ldt).loadTablePosition(0, 0)
        self.segWriteSegment((<Segment>self.segments.cs), self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_16BIT_CS))
        self.regWriteWord(CPU_REGISTER_IP, self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_16BIT_IP))
        self.segWriteSegment((<Segment>self.segments.ss), self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_16BIT_SS))
        self.regWriteWord(CPU_REGISTER_SP, self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_16BIT_SP))
        self.regWriteWordFlags(self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_16BIT_FLAGS))
        self.segWriteSegment((<Segment>self.segments.ds), self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_16BIT_DS))
        self.segWriteSegment((<Segment>self.segments.es), self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_16BIT_ES))
        self.regWriteWord(CPU_REGISTER_AX, self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_16BIT_AX))
        self.regWriteWord(CPU_REGISTER_CX, self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_16BIT_CX))
        self.regWriteWord(CPU_REGISTER_DX, self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_16BIT_DX))
        self.regWriteWord(CPU_REGISTER_BX, self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_16BIT_BX))
        self.regWriteWord(CPU_REGISTER_BP, self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_16BIT_BP))
        self.regWriteWord(CPU_REGISTER_SI, self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_16BIT_SI))
        self.regWriteWord(CPU_REGISTER_DI, self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_16BIT_DI))

        self.regOrDword(CPU_REGISTER_CR0, CR0_FLAG_TS)
        return True
    cdef unsigned char saveTSS16(self) except BITMASK_BYTE:
        cdef unsigned int baseAddress
        self.main.notice("Registers::saveTSS16: TODO? (savedEip: {0:#010x}, savedCs: {1:#06x})", self.main.cpu.savedEip, self.main.cpu.savedCs)
        baseAddress = self.mmGetRealAddr(0, 1, (<Segment>self.segments.tss), False, True)
        if (((baseAddress&0xfff)+TSS_MIN_16BIT_HARD_LIMIT) > 0xfff):
            self.main.exitError("Registers::saveTSS16: TSS is over page boundary!")
            return False
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_16BIT_AX, self.regReadUnsignedWord(CPU_REGISTER_AX), OP_SIZE_WORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_16BIT_CX, self.regReadUnsignedWord(CPU_REGISTER_CX), OP_SIZE_WORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_16BIT_DX, self.regReadUnsignedWord(CPU_REGISTER_DX), OP_SIZE_WORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_16BIT_BX, self.regReadUnsignedWord(CPU_REGISTER_BX), OP_SIZE_WORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_16BIT_BP, self.regReadUnsignedWord(CPU_REGISTER_BP), OP_SIZE_WORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_16BIT_SI, self.regReadUnsignedWord(CPU_REGISTER_SI), OP_SIZE_WORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_16BIT_DI, self.regReadUnsignedWord(CPU_REGISTER_DI), OP_SIZE_WORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_16BIT_ES, self.segRead(CPU_SEGMENT_ES), OP_SIZE_WORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_16BIT_CS, self.segRead(CPU_SEGMENT_CS), OP_SIZE_WORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_16BIT_DS, self.segRead(CPU_SEGMENT_DS), OP_SIZE_WORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_16BIT_IP, self.regReadUnsignedWord(CPU_REGISTER_IP), OP_SIZE_WORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_16BIT_FLAGS, self.readFlags(), OP_SIZE_WORD)

        self.main.mm.mmPhyWriteValue(baseAddress + TSS_16BIT_SP, self.regReadUnsignedWord(CPU_REGISTER_SP), OP_SIZE_WORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_16BIT_SS, self.segRead(CPU_SEGMENT_SS), OP_SIZE_WORD)
        return True
    cdef unsigned char switchTSS32(self) except BITMASK_BYTE:
        cdef unsigned int baseAddress
        cdef GdtEntry gdtEntry
        self.main.notice("Registers::switchTSS32: TODO? (savedEip: {0:#010x}, savedCs: {1:#06x})", self.main.cpu.savedEip, self.main.cpu.savedCs)
        self.main.cpu.cpuDump()
        self.main.notice("Registers::switchTSS32: TODO? (getCPL(): {0:d}; cpl: {1:d})", self.getCPL(), self.cpl)
        baseAddress = self.mmGetRealAddr(0, 1, (<Segment>self.segments.tss), False, False)
        if (((baseAddress&0xfff)+TSS_MIN_32BIT_HARD_LIMIT) > 0xfff):
            self.main.exitError("Registers::switchTSS32: TSS is over page boundary!")
            return False
        if (self.protectedModeOn and self.pagingOn):
            self.regWriteDword(CPU_REGISTER_CR3, self.main.mm.mmPhyReadValueUnsignedDword(baseAddress + TSS_32BIT_CR3))
        self.segments.ldtr = self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_32BIT_LDT_SEG_SEL)
        if (self.segments.ldtr):
            gdtEntry = <GdtEntry>self.segments.gdt.getEntry(self.segments.ldtr&0xfff8)
            if (gdtEntry is None):
                self.main.notice("Registers::switchTSS32: gdtEntry is invalid, mark LDTR as invalid.")
                (<Gdt>self.segments.ldt).loadTablePosition(0, 0)
            else:
                (<Gdt>self.segments.ldt).loadTablePosition(gdtEntry.base, gdtEntry.limit)
        else:
            (<Gdt>self.segments.ldt).loadTablePosition(0, 0)
        self.segWriteSegment((<Segment>self.segments.cs), self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_32BIT_CS))
        self.regWriteDword(CPU_REGISTER_EIP, self.main.mm.mmPhyReadValueUnsignedDword(baseAddress + TSS_32BIT_EIP))
        self.segWriteSegment((<Segment>self.segments.ss), self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_32BIT_SS))
        self.regWriteDword(CPU_REGISTER_ESP, self.main.mm.mmPhyReadValueUnsignedDword(baseAddress + TSS_32BIT_ESP))
        self.regWriteDwordEflags(self.main.mm.mmPhyReadValueUnsignedDword(baseAddress + TSS_32BIT_EFLAGS))
        self.segWriteSegment((<Segment>self.segments.ds), self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_32BIT_DS))
        self.segWriteSegment((<Segment>self.segments.es), self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_32BIT_ES))
        self.segWriteSegment((<Segment>self.segments.fs), self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_32BIT_FS))
        self.segWriteSegment((<Segment>self.segments.gs), self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_32BIT_GS))
        self.regWriteDword(CPU_REGISTER_EAX, self.main.mm.mmPhyReadValueUnsignedDword(baseAddress + TSS_32BIT_EAX))
        self.regWriteDword(CPU_REGISTER_ECX, self.main.mm.mmPhyReadValueUnsignedDword(baseAddress + TSS_32BIT_ECX))
        self.regWriteDword(CPU_REGISTER_EDX, self.main.mm.mmPhyReadValueUnsignedDword(baseAddress + TSS_32BIT_EDX))
        self.regWriteDword(CPU_REGISTER_EBX, self.main.mm.mmPhyReadValueUnsignedDword(baseAddress + TSS_32BIT_EBX))
        self.regWriteDword(CPU_REGISTER_EBP, self.main.mm.mmPhyReadValueUnsignedDword(baseAddress + TSS_32BIT_EBP))
        self.regWriteDword(CPU_REGISTER_ESI, self.main.mm.mmPhyReadValueUnsignedDword(baseAddress + TSS_32BIT_ESI))
        self.regWriteDword(CPU_REGISTER_EDI, self.main.mm.mmPhyReadValueUnsignedDword(baseAddress + TSS_32BIT_EDI))

        self.regOrDword(CPU_REGISTER_CR0, CR0_FLAG_TS)
        self.main.cpu.cpuDump()
        self.main.notice("Registers::switchTSS32: TODO? (getCPL(): {0:d}; cpl: {1:d})", self.getCPL(), self.cpl)
        if ((self.main.mm.mmPhyReadValueUnsignedByte(baseAddress + TSS_32BIT_T_FLAG) & 1) != 0):
            self.main.notice("Registers::switchTSS32: Debug")
            raise HirnwichseException(CPU_EXCEPTION_DB)
        return True
    cdef unsigned char saveTSS32(self) except BITMASK_BYTE:
        cdef unsigned int baseAddress
        self.main.notice("Registers::saveTSS32: TODO? (savedEip: {0:#010x}, savedCs: {1:#06x})", self.main.cpu.savedEip, self.main.cpu.savedCs)
        self.main.cpu.cpuDump()
        self.main.notice("Registers::saveTSS32: TODO? (getCPL(): {0:d}; cpl: {1:d})", self.getCPL(), self.cpl)
        baseAddress = self.mmGetRealAddr(0, 1, (<Segment>self.segments.tss), False, True)
        if (((baseAddress&0xfff)+TSS_MIN_32BIT_HARD_LIMIT) > 0xfff):
            self.main.exitError("Registers::saveTSS32: TSS is over page boundary!")
            return False
        #fp=open("info_10.bin","wb")
        #fp.write(self.main.mm.mmPhyRead(baseAddress, 104))
        #fp.flush()
        #fp.close()
        #self.main.debugEnabled = True
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_32BIT_EAX, self.regReadUnsignedDword(CPU_REGISTER_EAX), OP_SIZE_DWORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_32BIT_ECX, self.regReadUnsignedDword(CPU_REGISTER_ECX), OP_SIZE_DWORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_32BIT_EDX, self.regReadUnsignedDword(CPU_REGISTER_EDX), OP_SIZE_DWORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_32BIT_EBX, self.regReadUnsignedDword(CPU_REGISTER_EBX), OP_SIZE_DWORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_32BIT_EBP, self.regReadUnsignedDword(CPU_REGISTER_EBP), OP_SIZE_DWORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_32BIT_ESI, self.regReadUnsignedDword(CPU_REGISTER_ESI), OP_SIZE_DWORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_32BIT_EDI, self.regReadUnsignedDword(CPU_REGISTER_EDI), OP_SIZE_DWORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_32BIT_ES, self.segRead(CPU_SEGMENT_ES), OP_SIZE_WORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_32BIT_CS, self.segRead(CPU_SEGMENT_CS), OP_SIZE_WORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_32BIT_DS, self.segRead(CPU_SEGMENT_DS), OP_SIZE_WORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_32BIT_FS, self.segRead(CPU_SEGMENT_FS), OP_SIZE_WORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_32BIT_GS, self.segRead(CPU_SEGMENT_GS), OP_SIZE_WORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_32BIT_EIP, self.regReadUnsignedDword(CPU_REGISTER_EIP), OP_SIZE_DWORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_32BIT_EFLAGS, self.readFlags(), OP_SIZE_DWORD)

        self.main.mm.mmPhyWriteValue(baseAddress + TSS_32BIT_ESP, self.regReadUnsignedDword(CPU_REGISTER_ESP), OP_SIZE_DWORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_32BIT_SS, self.segRead(CPU_SEGMENT_SS), OP_SIZE_WORD)
        #fp=open("info_11.bin","wb")
        #fp.write(self.main.mm.mmPhyRead(baseAddress, 104))
        #fp.flush()
        #fp.close()
        return True
    cdef void run(self):
        self.segments = Segments(self, self.main)
        self.segments.run()


