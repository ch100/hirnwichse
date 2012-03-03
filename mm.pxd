
from misc cimport Misc
from libc.stdlib cimport calloc, malloc, free
from libc.string cimport strncpy, memcpy, memset, memmove


cdef class MmArea:
    cpdef object main
    cdef Mm mm
    cdef unsigned char mmReadOnly
    cdef unsigned long mmBaseAddr, mmAreaSize
    cdef unsigned long long mmEndAddr
    cdef char *mmAreaData
    cdef void mmResetAreaData(self)
    cpdef mmFreeAreaData(self)
    cdef void mmSetReadOnly(self, unsigned char mmReadOnly)
    cdef bytes mmAreaRead(self, unsigned long mmAddr, unsigned long dataSize)
    cdef void mmAreaWrite(self, unsigned long mmAddr, char *data, unsigned long dataSize)
    cdef void mmAreaCopy(self, unsigned long destAddr, unsigned long srcAddr, unsigned long dataSize)
    cpdef run(self)


cdef class Mm:
    cpdef object main
    cdef list mmAreas
    cdef void mmAddArea(self, unsigned long mmBaseAddr, unsigned long mmAreaSize, unsigned char mmReadOnly, MmArea mmAreaObject)
    cdef unsigned char mmDelArea(self, unsigned long mmBaseAddr)
    cdef MmArea mmGetSingleArea(self, unsigned long mmAddr, unsigned long dataSize)
    cdef list mmGetAreas(self, unsigned long mmAddr, unsigned long dataSize)
    cdef bytes mmPhyRead(self, unsigned long mmAddr, unsigned long dataSize)
    cdef long long mmPhyReadValueSigned(self, unsigned long mmAddr, unsigned char dataSize)
    cdef unsigned long long mmPhyReadValueUnsigned(self, unsigned long mmAddr, unsigned char dataSize)
    cdef void mmPhyWrite(self, unsigned long mmAddr, bytes data, unsigned long dataSize)
    cdef unsigned long long mmPhyWriteValue(self, unsigned long mmAddr, unsigned long long data, unsigned char dataSize)
    cdef void mmPhyCopy(self, unsigned long destAddr, unsigned long srcAddr, unsigned long dataSize)

cdef class ConfigSpace:
    cpdef object main
    cdef char *csData
    cdef unsigned long csSize
    cdef void csResetData(self)
    cpdef csFreeData(self)
    cdef bytes csRead(self, unsigned long offset, unsigned long size)
    cdef void csWrite(self, unsigned long offset, bytes data, unsigned long size)
    cdef void csCopy(self, unsigned long destOffset, unsigned long srcOffset, unsigned long size)
    cdef unsigned long long csReadValueUnsigned(self, unsigned long offset, unsigned char size)
    cdef unsigned long long csReadValueUnsignedBE(self, unsigned long offset, unsigned char size)
    cdef long long csReadValueSigned(self, unsigned long offset, unsigned char size)
    cdef long long csReadValueSignedBE(self, unsigned long offset, unsigned char size)
    cdef unsigned long long csWriteValue(self, unsigned long offset, unsigned long long data, unsigned char size)
    cdef unsigned long long csWriteValueBE(self, unsigned long offset, unsigned long long data, unsigned char size)
    cdef unsigned long long csAddValue(self, unsigned long offset, unsigned long long data, unsigned char size)
    cdef unsigned long long csSubValue(self, unsigned long offset, unsigned long long data, unsigned char size)
    cpdef run(self)







