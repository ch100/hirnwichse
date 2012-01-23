

cdef class PS2:
    cpdef public object main, _pyroDaemon
    cpdef public str _pyroId
    cdef public unsigned char ppcbT2Both, ppcbT2Out, kbdClockEnabled
    cdef unsigned char lastUsedPort, needWriteBytes, lastKbcCmdByte, lastKbCmdByte, irq1Requested, allowIrq1, sysf, \
                        translateScancodes, currentScancodesSet, scanningEnabled, outb, batInProgress, timerPending
    cdef bytes outBuffer
    cdef resetInternals(self, unsigned char powerUp)
    cdef initDevice(self)
    cdef appendToOutBytesJustAppend(self, bytes data)
    cdef appendToOutBytes(self, bytes data)
    cdef appendToOutBytesImm(self, bytes data)
    cdef appendToOutBytesDoIrq(self, bytes data)
    cpdef setKeyboardRepeatRate(self, unsigned char data)
    cpdef keySend(self, unsigned char keyId, unsigned char keyUp)
    cdef unsigned long inPort(self, unsigned short ioPortAddr, unsigned char dataSize)
    cdef outPort(self, unsigned short ioPortAddr, unsigned long data, unsigned char dataSize)
    cdef setKbdClockEnable(self, unsigned char value)
    cpdef activateTimer(self)
    cpdef unsigned char periodic(self, unsigned char usecDelta)
    cpdef timerFunc(self)
    cpdef initThread(self)
    cpdef run(self)


