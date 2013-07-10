
from misc cimport Misc
from libc.stdlib cimport calloc, malloc, free
from libc.string cimport strncpy, memcpy, memset, memmove

include "globals.pxi"

ctypedef fused unsigned_value_types:
    unsigned char
    unsigned short
    unsigned int
    unsigned long int

ctypedef unsigned char unsigned_char
ctypedef unsigned short unsigned_short
ctypedef unsigned int unsigned_int
ctypedef unsigned long int unsigned_long_int


ctypedef bytes (*MmAreaReadType)(self, MmArea, unsigned int, unsigned int)
ctypedef void (*MmAreaWriteType)(self, MmArea, unsigned int, char *, unsigned int)

cdef class MmArea:
    cdef unsigned char readOnly, valid
    cdef unsigned int start, end
    cdef char *data
    cdef object readClass
    cdef object writeClass
    cdef MmAreaReadType readHandler
    cdef MmAreaWriteType writeHandler


cdef class Mm:
    cpdef object main
    cdef list mmAreas
    cdef MmArea mmAddArea(self, unsigned int mmBaseAddr, unsigned char mmReadOnly)
    cdef void mmMallocArea(self, MmArea mmArea, unsigned char clearByte)
    cdef void mmDelArea(self, unsigned int mmAddr)
    cdef MmArea mmGetArea(self, unsigned int mmAddr)
    cdef list mmGetAreas(self, unsigned int mmAddr, unsigned int dataSize)
    cdef void mmSetReadOnly(self, unsigned int mmAddr, unsigned char mmReadOnly)
    cdef inline char *mmGetDataPointer(self, MmArea mmArea, unsigned int offset):
        if (not mmArea.valid or mmArea.data is NULL):
            self.main.exitError("Mm::mmGetDataPointer: not mmArea.(valid/data). (address: {0:#010x}; savedEip: {1:#010x}; savedCs: {2:#06x})", mmArea.start+offset, self.main.cpu.savedEip, self.main.cpu.savedCs)
            return NULL
        return <char*>(mmArea.data+offset)
    cdef bytes mmAreaRead(self, MmArea mmArea, unsigned int offset, unsigned int dataSize)
    cdef void mmAreaWrite(self, MmArea mmArea, unsigned int offset, char *data, unsigned int dataSize)
    cdef bytes mmPhyRead(self, unsigned int mmAddr, unsigned int dataSize)
    cdef signed char mmPhyReadValueSignedByte(self, unsigned int mmAddr)
    cdef signed short mmPhyReadValueSignedWord(self, unsigned int mmAddr)
    cdef signed int mmPhyReadValueSignedDword(self, unsigned int mmAddr)
    cdef signed long int mmPhyReadValueSignedQword(self, unsigned int mmAddr)
    cdef signed long int mmPhyReadValueSigned(self, unsigned int mmAddr, unsigned char dataSize)
    cdef unsigned char mmPhyReadValueUnsignedByte(self, unsigned int mmAddr)
    cdef unsigned short mmPhyReadValueUnsignedWord(self, unsigned int mmAddr)
    cdef unsigned int mmPhyReadValueUnsignedDword(self, unsigned int mmAddr)
    cdef unsigned long int mmPhyReadValueUnsignedQword(self, unsigned int mmAddr)
    cdef unsigned long int mmPhyReadValueUnsigned(self, unsigned int mmAddr, unsigned char dataSize)
    cdef unsigned char mmPhyWrite(self, unsigned int mmAddr, bytes data, unsigned int dataSize)
    cdef unsigned char mmPhyWriteValueSize(self, unsigned int mmAddr, unsigned_value_types data)
    cdef unsigned char mmPhyWriteValue(self, unsigned int mmAddr, unsigned long int data, unsigned char dataSize)
    cdef void mmPhyCopy(self, unsigned int destAddr, unsigned int srcAddr, unsigned int dataSize)
    cdef unsigned int mmGetAbsoluteAddressForInterrupt(self, unsigned char intNum)

cdef class ConfigSpace:
    cpdef object main
    cdef char *csData
    cdef unsigned char clearByte
    cdef unsigned int csSize
    cdef void csResetData(self, unsigned char clearByte = ?)
    cpdef csFreeData(self)
    cdef bytes csRead(self, unsigned int offset, unsigned int size)
    cdef void csWrite(self, unsigned int offset, bytes data, unsigned int size)
    cdef unsigned long int csReadValueUnsigned(self, unsigned int offset, unsigned char size)
    cdef unsigned long int csReadValueUnsignedBE(self, unsigned int offset, unsigned char size)
    cdef signed long int csReadValueSigned(self, unsigned int offset, unsigned char size)
    cdef signed long int csReadValueSignedBE(self, unsigned int offset, unsigned char size)
    cdef unsigned long int csWriteValue(self, unsigned int offset, unsigned long int data, unsigned char size)
    cdef unsigned long int csWriteValueBE(self, unsigned int offset, unsigned long int data, unsigned char size)
    cdef unsigned long int csAddValue(self, unsigned int offset, unsigned long int data, unsigned char size)
    cdef unsigned long int csSubValue(self, unsigned int offset, unsigned long int data, unsigned char size)







