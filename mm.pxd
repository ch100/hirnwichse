
include "globals.pxi"

from libc.stdint cimport *
from libc.stdlib cimport malloc, free, exit as exitt
from libc.string cimport memcpy, memset


from hirnwichse_main cimport Hirnwichse

cdef class Mm:
    cdef Hirnwichse main
    cdef char *data
    cdef char *pciData
    cdef char *romData
    cdef char *tempData
    cdef char *vgaRomData
    cdef uint8_t ignoreRomWrite
    cdef uint64_t memSizeBytes
    cdef void quitFunc(self)
    cdef void mmClear(self, uint32_t mmAddr, uint8_t clearByte, uint32_t dataSize) nogil
    cdef char *mmPhyRead(self, uint32_t mmAddr, uint32_t dataSize) nogil
    cdef int64_t mmPhyReadValueSigned(self, uint32_t mmAddr, uint8_t dataSize) nogil
    cdef uint8_t mmPhyReadValueUnsignedByte(self, uint32_t mmAddr) nogil
    cdef uint16_t mmPhyReadValueUnsignedWord(self, uint32_t mmAddr) nogil
    cdef uint32_t mmPhyReadValueUnsignedDword(self, uint32_t mmAddr) nogil
    cdef uint64_t mmPhyReadValueUnsignedQword(self, uint32_t mmAddr) nogil
    cdef uint64_t mmPhyReadValueUnsigned(self, uint32_t mmAddr, uint8_t dataSize) nogil
    cdef uint8_t mmPhyWrite(self, uint32_t mmAddr, char *data, uint32_t dataSize) nogil
    cdef uint8_t mmPhyWriteValue(self, uint32_t mmAddr, uint64_t data, uint8_t dataSize) nogil

cdef class ConfigSpace:
    cdef Hirnwichse main
    cdef char *csData
    cdef uint8_t clearByte
    cdef uint32_t csSize
    cdef void quitFunc(self)
    cdef void csResetData(self, uint8_t clearByte) nogil
    cdef void csResetAddr(self, uint32_t offset, uint8_t clearByte, uint8_t size) nogil
    cdef bytes csRead(self, uint32_t offset, uint32_t size)
    cdef void csWrite(self, uint32_t offset, char *data, uint32_t size) nogil
    cdef uint8_t csReadValueUnsignedByte(self, uint32_t offset) nogil
    cdef uint32_t csReadValueUnsignedDword(self, uint32_t offset) nogil
    cdef uint64_t csReadValueUnsigned(self, uint32_t offset, uint8_t size) nogil
    cdef int64_t csReadValueSigned(self, uint32_t offset, uint8_t size) nogil
    cdef void csWriteValueByte(self, uint32_t offset, uint8_t data) nogil
    cdef void csWriteValueWord(self, uint32_t offset, uint16_t data) nogil
    cdef void csWriteValueDword(self, uint32_t offset, uint32_t data) nogil
    cdef void csWriteValueQword(self, uint32_t offset, uint64_t data) nogil
    cdef void csWriteValue(self, uint32_t offset, uint64_t data, uint8_t size) nogil


