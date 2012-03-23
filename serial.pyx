
include "globals.pxi"


cdef class Serial:
    def __init__(self, object main):
        self.main = main
    cdef unsigned int inPort(self, unsigned short ioPortAddr, unsigned char dataSize):
        if (dataSize == OP_SIZE_BYTE):
            pass
        else:
            self.main.exitError("inPort: dataSize {0:d} not supported.", dataSize)
        return BITMASK_BYTE
    cdef void outPort(self, unsigned short ioPortAddr, unsigned int data, unsigned char dataSize):
        if (dataSize == OP_SIZE_BYTE):
            pass
        else:
            self.main.exitError("outPort: dataSize {0:d} not supported.", dataSize)
        return
    cdef void run(self):
        pass


