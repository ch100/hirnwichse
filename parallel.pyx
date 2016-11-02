
#cython: language_level=3, boundscheck=False, wraparound=False, cdivision=True, profile=False, c_string_type=bytes

include "globals.pxi"


cdef class Parallel:
    def __init__(self, Hirnwichse main):
        self.main = main
    cdef void reset(self):
        pass
    cdef uint32_t inPort(self, uint16_t ioPortAddr, uint8_t dataSize) nogil:
        if (dataSize == OP_SIZE_BYTE):
            pass
        else:
            with gil:
                self.main.exitError("inPort: port {0:#04x} with dataSize {1:d} not supported.", (ioPortAddr, dataSize))
        return BITMASK_BYTE
    cdef void outPort(self, uint16_t ioPortAddr, uint32_t data, uint8_t dataSize) nogil:
        if (dataSize == OP_SIZE_BYTE):
            pass
        else:
            with gil:
                self.main.exitError("outPort: port {0:#04x} with dataSize {1:d} not supported. (data: {2:#06x})", (ioPortAddr, dataSize, data))
        return
    cdef void run(self):
        pass


