
from libc.stdint cimport *
from cpython.ref cimport PyObject, Py_INCREF

from hirnwichse_main cimport Hirnwichse
from cmos cimport Cmos
from pic cimport Pic
from mm cimport ConfigSpace
from pci cimport Pci, PciDevice

cdef class AtaDrive:
    cdef object fp
    cdef AtaController ataController
    cdef ConfigSpace configSpace
    cdef uint8_t driveId, driveType, isLoaded, isWriteProtected, isLocked, sectorShift, senseKey, senseAsc
    cdef uint16_t sectorSize, driveCode
    cdef uint64_t sectors
    cdef bytes filename
    cdef uint64_t ChsToSector(self, uint32_t cylinder, uint8_t head, uint8_t sector) nogil
    cdef inline void writeValue(self, uint8_t index, uint16_t value) nogil
    cdef void reset(self) nogil
    cdef void loadDrive(self, bytes filename)
    cdef bytes readBytes(self, uint64_t offset, uint32_t size)
    cdef inline bytes readSectors(self, uint64_t sector, uint32_t count) # count in sectors
    cdef void writeBytes(self, uint64_t offset, uint32_t size, bytes data)
    cdef inline void writeSectors(self, uint64_t sector, uint32_t count, bytes data)
    cdef void run(self) nogil


cdef class AtaController:
    cdef Ata ata
    cdef PyObject *drive[2]
    cdef bytes result, data
    cdef uint8_t controllerId, driveId, useLBA, useLBA48, irqEnabled, HOB, doReset, driveBusy, resetInProgress, driveReady, \
        errorRegister, drq, seekComplete, err, irq, cmd, sector, head, sectorCountFlipFlop, sectorHighFlipFlop, sectorMiddleFlipFlop, \
        sectorLowFlipFlop, indexPulse, indexPulseCount, features, sectorCountByte, multipleSectors, busmasterCommand, busmasterStatus, mdmaMode, udmaMode
    cdef uint32_t sectorCount, cylinder, busmasterAddress
    cdef uint64_t lba
    cdef void setSignature(self, uint8_t driveId) nogil
    cdef void reset(self, uint8_t swReset) nogil
    cdef inline void LbaToCHS(self) nogil
    cdef void convertToLBA28(self) nogil
    cdef void raiseAtaIrq(self, uint8_t withDRQ, uint8_t doIRQ) nogil
    cdef void lowerAtaIrq(self) nogil
    cdef void abortCommand(self) nogil
    cdef void errorCommand(self, uint8_t errorRegister) nogil
    cdef void nopCommand(self) nogil
    cdef void handlePacket(self)
    cdef void handleBusmaster(self)
    cdef uint32_t inPort(self, uint16_t ioPortAddr, uint8_t dataSize) nogil
    cdef void outPort(self, uint16_t ioPortAddr, uint32_t data, uint8_t dataSize) nogil
    cdef void run(self)


cdef class Ata:
    cdef Hirnwichse main
    cdef PyObject *controller[2]
    cdef PciDevice pciDevice
    cdef uint32_t base4Addr
    cdef void reset(self) nogil
    cdef uint8_t isBusmaster(self, uint16_t ioPortAddr) nogil
    cdef uint32_t inPort(self, uint16_t ioPortAddr, uint8_t dataSize) nogil
    cdef void outPort(self, uint16_t ioPortAddr, uint32_t data, uint8_t dataSize) nogil
    cdef void run(self)


