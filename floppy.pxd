
from cmos cimport Cmos
from isadma cimport IsaDma, IsaDmaChannel, DmaReadFromMem, DmaWriteToMem
from pic cimport Pic


cdef class FloppyMedia:
    cdef public FloppyDrive floppyDrive
    cdef public unsigned char tracks, heads, sectorsPerTrack, mediaType
    cdef public unsigned long sectors
    cdef setDataForMedia(self, unsigned char mediaType)


cdef class FloppyDrive:
    cpdef public object main, fp
    cdef public FloppyController controller
    cdef public FloppyMedia media
    cdef public bytes filename
    cdef public unsigned char driveId, isLoaded, isWriteProtected, DIR, cylinder, head, sector, eot
    cdef unsigned long ChsToSector(self, unsigned char cylinder, unsigned char head, unsigned char sector)
    cdef unsigned char getDiskType(self, unsigned long size)
    cdef loadDrive(self, bytes filename)
    cdef bytes readBytes(self, unsigned long offset, unsigned long size)
    cdef bytes readSectors(self, unsigned long sector, unsigned long count) # count in sectors
    cdef writeSectors(self, unsigned long sector, bytes data)


cdef class FloppyController:
    cpdef public object main
    cdef public Floppy fdc
    cdef bytes command, result, fdcBuffer
    cdef public tuple drive
    cdef unsigned char controllerId, msr, DOR, st0, st1, st2, st3, TC, resetSensei, pendingIrq, dataRate, multiTrack
    cdef unsigned long fdcBufferIndex
    cdef reset(self, unsigned char hwReset)
    cdef bytes floppyXfer(self, unsigned char drive, unsigned long offset, unsigned long size, unsigned char toFloppy)
    cdef addCommand(self, unsigned char command)
    cdef addToCommand(self, unsigned char command)
    cdef addToResult(self, unsigned char result)
    cdef clearCommand(self)
    cdef clearResult(self)
    cdef setDor(self, unsigned char data)
    cdef setMsr(self, unsigned char data)
    cdef doCmdReset(self)
    cdef resetChangeline(self)
    cdef incrementSector(self)
    cdef getTC(self)
    cdef handleResult(self)
    cdef handleIdle(self)
    cdef handleCommand(self)
    cdef writeToDrive(self, unsigned char data)
    cdef unsigned char readFromDrive(self)
    cdef raiseFloppyIrq(self)
    cdef lowerFloppyIrq(self)
    cdef unsigned long inPort(self, unsigned short ioPortAddr, unsigned char dataSize)
    cdef outPort(self, unsigned short ioPortAddr, unsigned long data, unsigned char dataSize)
    cdef run(self)

cdef class Floppy:
    cpdef public object main
    cdef Cmos cmos
    cdef Pic pic
    cdef IsaDma isaDma
    cdef public tuple controller
    cdef initObjsToNull(self)
    cdef setupDMATransfer(self, FloppyController ctrl)
    cdef unsigned long inPort(self, unsigned short ioPortAddr, unsigned char dataSize)
    cdef outPort(self, unsigned short ioPortAddr, unsigned long data, unsigned char dataSize)
    cdef run(self)



