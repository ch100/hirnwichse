
from misc cimport Misc
from mm cimport Mm
from X86Platform cimport Platform
from cpu cimport Cpu


cdef class Hirnwichse:
    cpdef object parser, cmdArgs
    cdef Misc misc
    cdef Mm mm
    cdef Platform platform
    cdef Cpu cpu
    cdef unsigned char quitEmu, debugEnabled, exitIfCpuHalted, noUI, exitOnTripleFault, fdaType, fdbType, debugHalt, bootFrom, debugEnabledTest
    cdef unsigned int memSize
    cdef bytes romPath, biosFilename, vgaBiosFilename, fdaFilename, fdbFilename, hdaFilename, hdbFilename, cdrom1Filename, cdrom2Filename, serial1Filename, serial2Filename
    cpdef parseArgs(self)
    cpdef quitFunc(self)
    cpdef reset(self, unsigned char resetHardware)
    cpdef run(self)



