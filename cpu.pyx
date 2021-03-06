
#cython: language_level=3, boundscheck=False, wraparound=False, cdivision=True, profile=False, c_string_type=bytes

include "globals.pxi"
include "cpu_globals.pxi"

from sys import exit #, stdout, stderr
from time import sleep #, time
from traceback import print_exc


class HirnwichseException(Exception):
    pass


cdef class Cpu:
    def __init__(self, Hirnwichse main):
        self.main = main
    cdef inline void reset(self):
        self.savedCs  = 0xf000
        self.savedEip = 0xfff0
        self.cpuHalted = self.debugHalt = self.debugSingleStep = self.INTR = self.HRQ = False
        self.debugHalt = self.main.debugHalt
        self.savedSs = self.savedEsp = self.cycles = self.lasttime = 0
        self.operSize = self.addrSize = 0
        self.repPrefix = 0
        self.segmentOverridePrefix = NULL
        self.registers.reset()
    #cdef inline void saveCurrentInstPointer(self):
    #    self.savedCs  = self.registers.regs[CPU_SEGMENT_BASE+CPU_SEGMENT_CS]._union.word._union.rx
    #    self.savedEip = self.registers.regs[CPU_REGISTER_EIP]._union.dword.erx
    #    self.savedSs  = self.registers.regs[CPU_SEGMENT_BASE+CPU_SEGMENT_SS]._union.word._union.rx
    #    self.savedEsp = self.registers.regs[CPU_REGISTER_ESP]._union.dword.erx
    cdef void handleAsyncEvent(self):
        cdef uint8_t irqVector, oldIF
        # This is only for IRQs! (exceptions will use cpu.exception)
        oldIF = self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.if_flag
        if (self.INTR and oldIF):
            irqVector = (<Pic>self.main.platform.pic).IAC()
            self.opcodes.interrupt(irqVector)
        elif (self.HRQ):
            (<IsaDma>self.main.platform.isadma).raiseHLDA()
        if (not ((self.INTR and oldIF) or self.HRQ)):
            self.asyncEvent = False
            self.cpuHalted = False
        return
    cdef int exception(self, uint8_t exceptionId, int32_t errorCode=-1) except BITMASK_BYTE_CONST:
        #self.main.debugEnabled = True
        if (exceptionId in CPU_EXCEPTIONS_FAULT_GROUP):
            self.registers.segWriteSegment(&self.registers.segments.cs, self.savedCs)
            self.registers.regWriteDword(CPU_REGISTER_EIP, self.savedEip)
        self.registers.segWriteSegment(&self.registers.segments.ss, self.savedSs)
        self.registers.regs[CPU_REGISTER_ESP]._union.dword.erx = self.savedEsp
        #elif (exceptionId in CPU_EXCEPTIONS_TRAP_GROUP):
        #    self.savedEip = <uint32_t>(self.savedEip+1)
        IF COMP_DEBUG:
            if (exceptionId == CPU_EXCEPTION_UD):
                self.main.notice("CPU::exception: UD: Opcode not found. (opcode: 0x%02x; EIP: 0x%04x, CS: 0x%04x)", self.opcode, self.savedEip, self.savedCs)
            else:
                self.main.notice("CPU::exception: Handle exception %u. (opcode: 0x%02x; EIP: 0x%04x, CS: 0x%04x)", exceptionId, self.opcode, self.savedEip, self.savedCs)
            self.main.notice("Running exception_1.0: exceptionId: 0x%02x, errorCode: 0x%02x", exceptionId, errorCode)
            self.cpuDump()
        if (exceptionId in CPU_EXCEPTIONS_FAULT_GROUP and exceptionId != CPU_EXCEPTION_DB):
            self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.rf = True
        elif (exceptionId in CPU_EXCEPTIONS_TRAP_GROUP and self.repPrefix):
            self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.rf = True
        IF COMP_DEBUG:
            self.main.notice("Running exception_1.1: exceptionId: 0x%02x, errorCode: 0x%02x", exceptionId, errorCode)
            self.cpuDump()
        if (exceptionId in CPU_EXCEPTIONS_WITH_ERRORCODE):
            if (errorCode == -1):
                self.main.exitError("CPU exception: errorCode should be set, is -1.")
                return True
            self.opcodes.interrupt(exceptionId, errorCode)
        else:
            self.opcodes.interrupt(exceptionId)
        IF COMP_DEBUG:
            self.main.notice("Running exception_2: exceptionId: 0x%02x, errorCode: 0x%02x", exceptionId, errorCode)
            self.cpuDump()
        #if (exceptionId == CPU_EXCEPTION_GP and self.opcode == 0xcf and self.savedEip == 0x80139a2c and self.savedCs == 0x0008):
        #    self.main.debugEnabledTest = self.main.debugEnabled = True
        #if (exceptionId == CPU_EXCEPTION_GP and self.opcode == 0x8a and self.savedEip == 0x310a and self.savedCs == 0x17ff):
        #    self.main.debugEnabledTest = self.main.debugEnabled = True
        #if (exceptionId == CPU_EXCEPTION_GP and self.opcode == 0xae):
        #    self.main.notice("Running exception_3: sleep()")
        #    stdout.flush()
        #    stderr.flush()
        #    #sleep(3600)
        #    exit()
        return True
    cdef int handleException(self, object exception) except BITMASK_BYTE_CONST:
        cdef uint8_t exceptionId
        cdef int32_t errorCode
        #if (self.savedCs == 0x70 and self.savedEip == 0x3b2):
        #if (self.savedCs == 0x70 and self.savedEip == 0x382):
        #    self.main.debugEnabled = True
        #if (self.savedCs == 0xfcbf and self.savedEip == 0x2f27 and self.registers.regs[CPU_REGISTER_ESI]._union.dword.erx == 0xc10f30bc):
        #if (self.savedCs == 0xfcb2 and self.savedEip == 0x2ff7 and self.registers.regs[CPU_REGISTER_ESI]._union.dword.erx == 0xc10f30bc):
        #if (self.savedCs == 0x70 and self.savedEip == 0x0382):
        #if (self.savedCs == 0xc000 and self.savedEip == 0x152):
        #    self.main.debugEnabledTest = self.main.debugEnabled = True
        #if (self.savedCs == 0x8 and self.savedEip == 0x808b5d6b):
        #    self.main.debugEnabledTest = self.main.debugEnabled = True
        #if (self.savedCs == 0x137 and self.savedEip == 0x7fcf1025):
        #    self.main.debugEnabledTest = self.main.debugEnabled = True
        #if (self.savedCs == 0x17cf and self.savedEip == 0x56ad):
        #    self.main.debugEnabledTest = self.main.debugEnabled = True
        if (len(exception.args) not in (1, 2)):
            self.main.exitError('ERROR: exception argument length not in (1, 2); is %u', len(exception.args))
            return True
        errorCode = -1
        if (len(exception.args) == 2):
            if (not isinstance(exception.args[1], int)):
                #self.main.exitError('ERROR: errorCode not a int; type is %s', type(exception.args[1]))
                self.main.exitError('ERROR: errorCode not a int')
                return True
            errorCode = exception.args[1]
        if (not isinstance(exception.args[0], int)):
            #self.main.exitError('ERROR: exceptionId not a int; type is %s', type(exception.args[0]))
            self.main.exitError('ERROR: exceptionId not a int')
            return True
        exceptionId = exception.args[0]
        return self.exception(exceptionId, errorCode)
    cdef void cpuDump(self) nogil:
        self.main.notice("EAX: 0x%08x, ECX: 0x%08x", self.registers.regs[CPU_REGISTER_EAX]._union.dword.erx, \
          self.registers.regs[CPU_REGISTER_ECX]._union.dword.erx)
        self.main.notice("EDX: 0x%08x, EBX: 0x%08x", self.registers.regs[CPU_REGISTER_EDX]._union.dword.erx, \
          self.registers.regs[CPU_REGISTER_EBX]._union.dword.erx)
        self.main.notice("ESP: 0x%08x, EBP: 0x%08x", self.registers.regs[CPU_REGISTER_ESP]._union.dword.erx, \
          self.registers.regs[CPU_REGISTER_EBP]._union.dword.erx)
        self.main.notice("ESI: 0x%08x, EDI: 0x%08x", self.registers.regs[CPU_REGISTER_ESI]._union.dword.erx, \
          self.registers.regs[CPU_REGISTER_EDI]._union.dword.erx)
        self.main.notice("EIP: 0x%08x, EFLAGS: 0x%08x", self.registers.regs[CPU_REGISTER_EIP]._union.dword.erx, \
          self.registers.regs[CPU_REGISTER_EFLAGS]._union.dword.erx)
        self.main.notice("CS: 0x%04x, SS: 0x%04x", self.registers.regs[CPU_SEGMENT_BASE+CPU_SEGMENT_CS]._union.word._union.rx, \
          self.registers.regs[CPU_SEGMENT_BASE+CPU_SEGMENT_SS]._union.word._union.rx)
        self.main.notice("DS: 0x%04x, ES: 0x%04x", self.registers.regs[CPU_SEGMENT_BASE+CPU_SEGMENT_DS]._union.word._union.rx, \
          self.registers.regs[CPU_SEGMENT_BASE+CPU_SEGMENT_ES]._union.word._union.rx)
        self.main.notice("FS: 0x%04x, GS: 0x%04x", self.registers.regs[CPU_SEGMENT_BASE+CPU_SEGMENT_FS]._union.word._union.rx, \
          self.registers.regs[CPU_SEGMENT_BASE+CPU_SEGMENT_GS]._union.word._union.rx)
        self.main.notice("LDTR: 0x%04x, LTR: 0x%04x", self.registers.ldtr, (<Segment>self.registers.segments.tss).segmentIndex)
        self.main.notice("CR0: 0x%08x, CR2: 0x%08x", self.registers.regs[CPU_REGISTER_CR0]._union.dword.erx, \
          self.registers.regs[CPU_REGISTER_CR2]._union.dword.erx)
        self.main.notice("CR3: 0x%08x, CR4: 0x%08x", self.registers.regs[CPU_REGISTER_CR3]._union.dword.erx, \
          self.registers.regs[CPU_REGISTER_CR4]._union.dword.erx)
        self.main.notice("DR0: 0x%08x, DR1: 0x%08x", self.registers.regs[CPU_REGISTER_DR0]._union.dword.erx, \
          self.registers.regs[CPU_REGISTER_DR1]._union.dword.erx)
        self.main.notice("DR2: 0x%08x, DR3: 0x%08x", self.registers.regs[CPU_REGISTER_DR2]._union.dword.erx, \
          self.registers.regs[CPU_REGISTER_DR3]._union.dword.erx)
        self.main.notice("DR6: 0x%08x, DR7: 0x%08x", self.registers.regs[CPU_REGISTER_DR6]._union.dword.erx, \
          self.registers.regs[CPU_REGISTER_DR7]._union.dword.erx)
        self.main.notice("savedCS: 0x%04x, savedSS: 0x%04x", self.savedCs, self.savedSs)
        self.main.notice("savedEIP: 0x%08x, savedESP: 0x%08x", self.savedEip, self.savedEsp)
        #self.main.notice("CS.limit: 0x%04x, SS.limit: 0x%04x", (<Segment>self.registers.segments.cs).gdtEntry.limit, \
        #  (<Segment>self.registers.segments.ss).gdtEntry.limit)
        #self.main.notice("DS.limit: 0x%04x, ES.limit: 0x%04x", (<Segment>self.registers.segments.ds).gdtEntry.limit, \
        #  (<Segment>self.registers.segments.es).gdtEntry.limit)
        #self.main.notice("FS.limit: 0x%04x, GS.limit: 0x%04x", (<Segment>self.registers.segments.fs).gdtEntry.limit, \
        #  (<Segment>self.registers.segments.gs).gdtEntry.limit)
        self.main.notice("Opcode: 0x%02x\n\n", self.opcode)
    cdef int doInfiniteCycles(self) except BITMASK_BYTE_CONST:
        cdef uint8_t count
        cdef uint64_t oldCycles = 0, temptime
        try:
            while (not self.main.quitEmu):
            #while (not self.main.quitEmu and ((self.cycles>>CPU_CLOCK_TICK_SHIFT) < 22000000)):
                if (self.cpuHalted and self.main.exitIfCpuHalted):
                    self.main.quitFunc()
                    exit(1)
                    return True
                elif ((self.debugHalt and not self.debugSingleStep) or (self.cpuHalted and not self.main.exitIfCpuHalted)):
                    if (self.asyncEvent and not self.registers.ssInhibit):
                        self.repPrefix = 0
                        self.segmentOverridePrefix = NULL
                        #self.saveCurrentInstPointer()
                        self.savedCs  = self.registers.regs[CPU_SEGMENT_BASE+CPU_SEGMENT_CS]._union.word._union.rx
                        self.savedEip = self.registers.regs[CPU_REGISTER_EIP]._union.dword.erx
                        self.savedSs  = self.registers.regs[CPU_SEGMENT_BASE+CPU_SEGMENT_SS]._union.word._union.rx
                        self.savedEsp = self.registers.regs[CPU_REGISTER_ESP]._union.dword.erx
                        self.operSize = self.addrSize = self.codeSegSize
                        self.handleAsyncEvent()
                    else:
                        self.registers.ssInhibit = False
                        #sleep(0.1) # lowering it to 0.1 because "why not?"
                        sleep(0.02)
                    if (self.main.platform.vga and self.main.platform.vga.ui): # this "if"-statement needs to be here because of the reactos boot menu
                        self.main.platform.vga.ui.handleEventsWithoutWaiting()
                    continue
                count = 0
                if (self.debugHalt and self.debugSingleStep):
                    self.debugSingleStep = False
                #self.registers.reloadCpuCache()
                self.cycles += CPU_CLOCK_TICK
                self.repPrefix = 0
                self.segmentOverridePrefix = NULL
                #self.saveCurrentInstPointer()
                self.savedCs  = self.registers.regs[CPU_SEGMENT_BASE+CPU_SEGMENT_CS]._union.word._union.rx
                self.savedEip = self.registers.regs[CPU_REGISTER_EIP]._union.dword.erx
                self.savedSs  = self.registers.regs[CPU_SEGMENT_BASE+CPU_SEGMENT_SS]._union.word._union.rx
                self.savedEsp = self.registers.regs[CPU_REGISTER_ESP]._union.dword.erx
                #if (not (<uint16_t>self.cycles)):
                #if (not (<uint16_t>self.cycles) and not (<uint16_t>(self.cycles>>1))):
                #if (not (<uint16_t>self.cycles) and not (<uint16_t>(self.cycles>>4))):
                #if (not (<uint16_t>self.cycles) and not (<uint16_t>(self.cycles>>5))):
                #if (not (<uint16_t>self.cycles) and not (<uint16_t>(self.cycles>>6))):
                #if (not (<uint16_t>self.cycles) and not (<uint16_t>(self.cycles>>8))):
                #if (not (<uint16_t>self.cycles) and not (<uint16_t>(self.cycles>>16))):
                #if (not (self.cycles&<unsigned int>0xffffff)):
                if (not (self.cycles&<unsigned int>0xffff) or (self.INTR and self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.if_flag)):
                #if (not (self.cycles&<unsigned int>0xffffff) or (self.INTR and self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.if_flag)):
                #if (not (self.cycles&<unsigned int>0x1ffffff) or (self.INTR and self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.if_flag)):
                    if (self.main.platform.vga and self.main.platform.vga.ui):
                        self.main.platform.vga.ui.handleEventsWithoutWaiting()
                    #temptime = ttime(NULL)*100
                    #if (temptime - self.lasttime >= 20):
                    temptime = ttime(NULL)
                    if (temptime - self.lasttime >= 1):
                    #IF 1:
                        #self.main.notice("CPU::doCycle: cycles: 0x%08x", self.cycles)
                        self.main.notice("CPU::doCycle: Thousand IPS: %u", (((self.cycles-oldCycles)>>CPU_CLOCK_TICK_SHIFT)/(temptime - self.lasttime))/1000)
                        if (self.main.platform.vga and self.main.platform.vga.ui):
                            self.main.platform.vga.ui.handleEventsWithoutWaiting()
                        self.lasttime = temptime
                        oldCycles = self.cycles
                try:
                    #if (self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.df):
                    #    self.main.notice("CPU::doCycle: DF-flag isn't fully supported yet!")
                    if (self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.tf):
                        self.main.notice("CPU::doCycle: TF-flag isn't fully supported yet! Opcode: 0x%02x; EIP: 0x%04x, CS: 0x%04x", self.opcode, self.savedEip, self.savedCs)
                        self.cpuDump()
                    self.operSize = self.addrSize = self.codeSegSize
                    if (not self.registers.ssInhibit):
                        if (self.asyncEvent):
                            self.handleAsyncEvent()
                            continue
                        elif (self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.tf):
                            self.registers.ssInhibit = True
                        # handle dr0-3 here
                    else:
                        self.registers.ssInhibit = False
                        if (self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.tf):
                            self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.tf = False
                            raise HirnwichseException(CPU_EXCEPTION_DB)
                            #continue
                    self.opcode = self.registers.getCurrentOpcodeAddUnsignedByte()
                    while (self.opcode in OPCODE_PREFIXES):
                        count += 1
                        if (count >= 16):
                            raise HirnwichseException(CPU_EXCEPTION_UD)
                        elif (self.opcode == OPCODE_PREFIX_OP):
                            if (self.codeSegSize == OP_SIZE_WORD):
                                self.operSize = OP_SIZE_DWORD
                            else:
                                self.operSize = OP_SIZE_WORD
                        elif (self.opcode == OPCODE_PREFIX_ADDR):
                            if (self.codeSegSize == OP_SIZE_WORD):
                                self.addrSize = OP_SIZE_DWORD
                            else:
                                self.addrSize = OP_SIZE_WORD
                        elif (self.opcode in OPCODE_PREFIX_REPS):
                            self.repPrefix = self.opcode
                        elif (self.opcode == OPCODE_PREFIX_CS):
                            self.segmentOverridePrefix = &self.registers.segments.cs
                        elif (self.opcode == OPCODE_PREFIX_SS):
                            self.segmentOverridePrefix = &self.registers.segments.ss
                        elif (self.opcode == OPCODE_PREFIX_DS):
                            self.segmentOverridePrefix = &self.registers.segments.ds
                        elif (self.opcode == OPCODE_PREFIX_ES):
                            self.segmentOverridePrefix = &self.registers.segments.es
                        elif (self.opcode == OPCODE_PREFIX_FS):
                            self.segmentOverridePrefix = &self.registers.segments.fs
                        elif (self.opcode == OPCODE_PREFIX_GS):
                            self.segmentOverridePrefix = &self.registers.segments.gs
                        ### TODO: I don't think, that we ever need lockPrefix.
                        #elif (self.opcode == OPCODE_PREFIX_LOCK):
                        #    self.main.notice("CPU::parsePrefixes: LOCK-prefix is selected! (unimplemented, bad things may happen.)")
                        self.opcode = self.registers.getCurrentOpcodeAddUnsignedByte()
                    self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.rf = False
                    #if (self.savedCs == 0x0 and self.savedEip == 0x7c00):
                    #    self.main.debugEnabledTest = self.main.debugEnabled = True
                    if (self.main.debugEnabled):
                    #if (self.main.debugEnabled or self.main.debugEnabledTest):
                    #IF 1:
                        self.main.notice("Current Opcode: 0x%02x; It's EIP: 0x%02x, CS: 0x%02x", self.opcode, self.savedEip, self.savedCs)
                        #self.cpuDump()
                    if (not self.opcodes.executeOpcode(self.opcode)):
                        self.main.notice("Opcode not found. (opcode: 0x%02x; EIP: 0x%02x, CS: 0x%02x)", self.opcode, self.savedEip, self.savedCs)
                        raise HirnwichseException(CPU_EXCEPTION_UD)
                except HirnwichseException as exception: # exception
                    IF COMP_DEBUG:
                        self.main.notice("Cpu::doCycle: testexc1")
                    #stdout.flush()
                    #print_exc()
                    #stderr.flush()
                    try:
                        self.handleException(exception) # execute exception handler
                    except HirnwichseException as exception: # exception
                        IF COMP_DEBUG:
                            #self.main.notice("Cpu::doCycle: testexc2; repr==%s", repr(exception.args))
                            self.main.notice("Cpu::doCycle: testexc2")
                        try:
                            self.exception(CPU_EXCEPTION_DF, 0) # exec DF double fault
                        except HirnwichseException as exception: # exception
                            IF COMP_DEBUG:
                                self.main.notice("Cpu::doCycle: testexc3")
                            if (self.main.exitOnTripleFault):
                                self.main.exitError("CPU::doCycle: TRIPLE FAULT! exit.")
                            else:
                                self.main.notice("CPU::doCycle: TRIPLE FAULT! reset.")
                                self.cpu.reset()
                        except:
                            print_exc()
                            self.main.exitError('doCycle: exception1 while handling opcode, exiting... (opcode: 0x%02x)', self.opcode)
                    except:
                        print_exc()
                        self.main.exitError('doCycle: exception2 while handling opcode, exiting... (opcode: 0x%02x)', self.opcode)
                except:
                    print_exc()
                    self.main.exitError('doCycle: exception3 while handling opcode, exiting... (opcode: 0x%02x)', self.opcode)
            #exit(0)
        except:
            print_exc()
            self.main.exitError('doInfiniteCycles: exception, exiting...')
        return True
    cdef int run(self, uint8_t infiniteCycles) except BITMASK_BYTE_CONST:
        self.registers = Registers(self.main)
        self.opcodes = Opcodes(self.main, self)
        self.opcodes.registers = self.registers
        self.registers.run()
        self.opcodes.run()
        self.reset()
        if (infiniteCycles):
            return self.doInfiniteCycles()
        return True
    ###

