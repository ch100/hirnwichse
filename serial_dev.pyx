
#cython: language_level=3, boundscheck=False, wraparound=False, cdivision=True, profile=True

include "globals.pxi"

from time import sleep
from atexit import register
from os import remove
from os.path import exists
import socket, serial as seriallib

cdef class SerialPort:
    def __init__(self, Serial serial, unsigned char serialIndex):
        self.serial = serial
        self.main = self.serial.main
        self.serialIndex = serialIndex
        if (not self.serialIndex):
            self.serialFilename = self.main.serial1Filename
        else:
            self.serialFilename = self.main.serial2Filename
        if (not (self.serialIndex & 1)):
            self.irq = 4
        else:
            self.irq = 3
        self.sock = self.fp = None
        self.dlab = self.isDev = False
        self.dataBits = 3
        self.stopBits = 0
        self.parity = 0
        self.divisor = 1 # 12
        self.interruptEnableRegister = self.modemControlRegister = self.oldModemStatusRegister = self.scratchRegister = 0
        self.lineStatusRegister = 0x60
        self.interruptIdentificationFifoControl = 0x2
        self.data = bytes()
        if (len(self.serialFilename) > 0):
            if (self.serialFilename.startswith(b"socket:")):
                self.serialFilename = self.serialFilename[7:]
                if (exists(self.serialFilename)):
                    remove(self.serialFilename)
                self.sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
                self.sock.bind(self.serialFilename)
                self.sock.listen(1)
                self.fp, addr = self.sock.accept()
            elif (self.serialFilename.startswith(b"serial:")):
                self.serialFilename = self.serialFilename[7:]
                self.isDev = True
                if (exists(self.serialFilename)):
                    self.fp = seriallib.Serial(port=self.serialFilename.decode())
                    self.setBits()
                    self.main.notice("SerialPort::__init__: \"serial:serialFilename\" does exist. (self.serialFilename: {0:s})", self.serialFilename.decode())
                else:
                    self.main.exitError("SerialPort::__init__: \"serial:serialFilename\" doesn't exist. (self.serialFilename: {0:s})", self.serialFilename.decode())
            else:
                self.fp = open(self.serialFilename, "w+b")
    cdef void reset(self):
        pass
    cpdef setFlags(self):
        self.lineStatusRegister &= ~0x1
        if (not len(self.data)):
            self.readData()
        if (self.isDev):
            self.lineStatusRegister &= ~0x60
            if (not self.fp.outWaiting()):
                if (self.interruptEnableRegister & 0x2):
                    self.raiseIrq() # write irq
                    self.interruptIdentificationFifoControl = 0x2
                self.lineStatusRegister |= 0x60
            if (self.fp.inWaiting()):
                if (self.interruptEnableRegister & 0x1):
                    self.raiseIrq() # read irq
                    self.interruptIdentificationFifoControl = 0x4
                self.lineStatusRegister |= 0x1
        if (len(self.data) > 0):
            self.lineStatusRegister |= 0x1
    cpdef setBits(self):
        cdef unsigned char tempVal
        if (self.isDev):
            self.fp.baudrate = 115200//self.divisor
            if (self.parity & 1):
                tempVal = self.parity >> 1
                if (not tempVal):
                    self.fp.parity = seriallib.PARITY_ODD
                elif (tempVal == 1):
                    self.fp.parity = seriallib.PARITY_EVEN
                elif (tempVal == 2):
                    self.fp.parity = seriallib.PARITY_MARK
                elif (tempVal == 3):
                    self.fp.parity = seriallib.PARITY_SPACE
            else:
                self.fp.parity = seriallib.PARITY_NONE
            if (self.stopBits & 1):
                if (self.dataBits): # dataBits != FIVEBITS
                    self.fp.stopbits = seriallib.STOPBITS_TWO
                else:
                    self.fp.stopbits = seriallib.STOPBITS_ONE_POINT_FIVE
            else:
                self.fp.stopbits = seriallib.STOPBITS_ONE
            self.fp.bytesize = 5+self.dataBits
    cpdef handleIrqs(self):
        if (self.fp is None):
            return
        while (not self.main.quitEmu):
            self.setFlags()
            sleep(1)
    cpdef quitFunc(self):
        if (self.sock is not None):
            self.sock.close()
            if (exists(self.serialFilename)):
                remove(self.serialFilename)
        elif (self.fp):
            self.fp.close()
    cdef void raiseIrq(self):
        if (self.modemControlRegister & 0x8):
            self.main.notice("SerialPort::raiseIrq: raiseIrq enabled (self.serialIndex {0:d})", self.serialIndex)
            (<Pic>self.main.platform.pic).raiseIrq(self.irq)
        else:
            self.main.notice("SerialPort::raiseIrq: raiseIrq disabled (self.serialIndex {0:d})", self.serialIndex)
    cdef void readData(self):
        cdef bytes tempData
        if (self.fp is not None):
            if (not self.modemControlRegister & 0x10):
                if (self.sock is not None):
                    try:
                        tempData = self.fp.recv(1, socket.MSG_DONTWAIT | socket.MSG_PEEK)
                        if (len(tempData) > 0):
                            self.data += self.fp.recv(1)
                    except BlockingIOError:
                        pass
                elif (self.isDev):
                    if (self.fp.inWaiting() > 0):
                        self.data += self.fp.read(1)
                else:
                    self.data += self.fp.read(1)
            #usleep(100000)
            #usleep(round(1.0e6/(115200.0/self.divisor)))
            if ((self.interruptEnableRegister & 0x1) and len(self.data) > 0):
                self.raiseIrq() # read irq
                self.interruptIdentificationFifoControl = 0x4
    cdef void writeData(self, bytes data):
        cdef unsigned int retlen
        if (self.fp is not None):
            if (len(data) > 0):
                self.lineStatusRegister &= ~0x60
                self.main.notice("SerialPort{0:d}::writeData: write string: {1:s}", self.serialIndex, repr(data.decode()))
                if (self.modemControlRegister & 0x10):
                    self.data += data
                else:
                    if (self.sock is not None):
                        retlen = self.fp.send(data)
                    else:
                        retlen = self.fp.write(data)
                        self.fp.flush()
                #usleep(100000)
                #usleep(round(1.0e6/(115200.0/self.divisor)))
                if (self.isDev):
                    if (self.fp.outWaiting()):
                        self.lineStatusRegister |= 0x60
                elif (retlen <= len(data)):
                    self.lineStatusRegister |= 0x60
                #if (1):
                #self.lineStatusRegister |= 0x60
                if (self.isDev):
                    if (self.interruptEnableRegister & 0x2 and not self.fp.outWaiting()):
                        self.raiseIrq() # write irq
                        self.interruptIdentificationFifoControl = 0x2
                else:
                    if (self.interruptEnableRegister & 0x2):
                        self.raiseIrq() # write irq
                        self.interruptIdentificationFifoControl = 0x2
    cdef unsigned int inPort(self, unsigned short ioPortAddr, unsigned char dataSize):
        cdef unsigned char ret = BITMASK_BYTE
        cdef bytes tempData
        if (self.fp is None):
            self.main.notice("SerialPort::inPort_4: fp is None")
            return ret
        elif (dataSize == OP_SIZE_BYTE):
            if (ioPortAddr == 0):
                if (self.dlab): # low byte divisor
                    self.main.notice("SerialPort::inPort_5: get divisor low")
                    return (self.divisor & BITMASK_BYTE)
                else:
                    self.main.notice("SerialPort::inPort_8: read character")
                    if (not len(self.data)):
                        self.readData()
                    if (len(self.data) > 0):
                        ret = self.data[0]
                        self.main.notice("SerialPort{0:d}::inPort_3: read character: {1:s}, {2:#04x}", self.serialIndex, repr(chr(ret)), ret)
                        if (len(self.data) > 1):
                            self.data = self.data[1:]
                        else:
                            self.data = bytes()
                    #else:
                    #    ret = 0
            elif (ioPortAddr == 1):
                if (self.dlab): # high byte divisor
                    self.main.notice("SerialPort::inPort_6: get divisor high")
                    return (self.divisor >> 8)
                else:
                    self.main.notice("SerialPort::inPort_7: get interruptEnableRegister")
                    return self.interruptEnableRegister
            elif (ioPortAddr == 2):
                (<Pic>self.main.platform.pic).lowerIrq(self.irq)
                if (not self.interruptIdentificationFifoControl):
                    self.interruptIdentificationFifoControl = 0x1
                return self.interruptIdentificationFifoControl
            elif (ioPortAddr == 3):
                return ((self.dlab << 7) | (self.parity << 3) | (self.stopBits << 2) | (self.dataBits))
            elif (ioPortAddr == 4):
                return self.modemControlRegister
            elif (ioPortAddr == 5):
                self.setFlags()
                return self.lineStatusRegister
            elif (ioPortAddr == 6):
                ret = 0
                if (self.isDev):
                    ret |= (self.fp.getCD() != 0) << 7
                    ret |= (self.fp.getRI() != 0) << 6
                    ret |= (self.fp.getDSR() != 0) << 5
                    ret |= (self.fp.getCTS() != 0) << 4
                    if (not ((self.oldModemStatusRegister >> 7) & 1) and ((ret >> 7) & 1)):
                        ret |= 1 << 3
                    if (((self.oldModemStatusRegister >> 6) & 1) and not ((ret >> 6) & 1)): # RI is reversed
                        ret |= 1 << 2
                    if (not ((self.oldModemStatusRegister >> 5) & 1) and ((ret >> 5) & 1)):
                        ret |= 1 << 1
                    if (not ((self.oldModemStatusRegister >> 4) & 1) and ((ret >> 4) & 1)):
                        ret |= 1
                self.oldModemStatusRegister = ret
                return ret
            elif (ioPortAddr == 7):
                return self.scratchRegister
            else:
                self.main.exitError("SerialPort::inPort_1: port {0:#04x} with dataSize {1:d} not supported.", ioPortAddr, dataSize)
        else:
            self.main.exitError("SerialPort::inPort_2: port {0:#04x} with dataSize {1:d} not supported.", ioPortAddr, dataSize)
        return ret
    cdef void outPort(self, unsigned short ioPortAddr, unsigned int data, unsigned char dataSize):
        if (self.fp is None):
            self.main.notice("SerialPort::outPort_4: fp is None")
            return
        elif (dataSize == OP_SIZE_BYTE):
            if (ioPortAddr == 0):
                if (self.dlab): # low byte divisor
                    self.main.notice("SerialPort::outPort_3: set divisor low")
                    self.divisor &= 0xff00
                    self.divisor |= data
                    self.setBits()
                else:
                    self.main.notice("SerialPort{0:d}::outPort: write character: {1:s}, {2:#04x}", self.serialIndex, repr(chr(data)), data)
                    self.writeData(bytes([data]))
            elif (ioPortAddr == 1):
                if (self.dlab): # high byte divisor
                    self.main.notice("SerialPort::outPort_4: set divisor high")
                    self.divisor &= 0x00ff
                    self.divisor |= (data<<8)
                    self.setBits()
                else:
                    self.main.notice("SerialPort::outPort_5: set interruptEnableRegister")
                    self.interruptEnableRegister = data
            elif (ioPortAddr == 2):
                if (data & 1):
                    if (data & 2):
                        self.data = bytes()
                        data &= ~2
                    data &= ~4
                    self.interruptIdentificationFifoControl = data
            elif (ioPortAddr == 3):
                self.dataBits = (data & 3)
                self.stopBits = ((data >> 2) & 1)
                self.parity = ((data >> 3) & 7)
                self.dlab = ((data >> 7) & 1)
                self.setBits()
                if (self.isDev):
                    self.fp.setBreak((data >> 6) & 1)
            elif (ioPortAddr == 4):
                self.modemControlRegister = data
                if (self.isDev):
                    self.fp.setRTS((self.modemControlRegister >> 1) & 1)
                    self.fp.setDTR(self.modemControlRegister & 1)
            elif (ioPortAddr == 7):
                self.scratchRegister = data
            else:
                self.main.exitError("SerialPort::outPort_1: port {0:#04x} with dataSize {1:d} not supported. (data: {2:#06x})", ioPortAddr, dataSize, data)
        else:
            self.main.exitError("SerialPort::outPort_2: port {0:#04x} with dataSize {1:d} not supported. (data: {2:#06x})", ioPortAddr, dataSize, data)
        return
    cdef void run(self):
        if (self.fp is not None):
            self.main.misc.createThread(self.handleIrqs, True)
        if (self.sock is not None):
            register(self.quitFunc)


cdef class Serial:
    def __init__(self, Hirnwichse main):
        self.main = main
        self.ports = (SerialPort(self, 0), SerialPort(self, 1))
    cdef void reset(self):
        cdef SerialPort port
        for port in self.ports:
            port.reset()
    cdef unsigned int inPort(self, unsigned short ioPortAddr, unsigned char dataSize):
        cdef SerialPort port
        cdef unsigned int ret = BITMASK_BYTE
        self.main.notice("Serial::inPort_1: port {0:#04x} dataSize {1:d}.", ioPortAddr, dataSize)
        if (dataSize == OP_SIZE_BYTE):
            if (ioPortAddr in SERIAL1_PORTS):
                port = self.ports[0]
                ret = port.inPort(ioPortAddr-SERIAL1_PORTS[0], dataSize)
            elif (ioPortAddr in SERIAL2_PORTS):
                port = self.ports[1]
                ret = port.inPort(ioPortAddr-SERIAL2_PORTS[0], dataSize)
            else:
                self.main.exitError("Serial::inPort_2: port {0:#04x} with dataSize {1:d} not supported.", ioPortAddr, dataSize)
                return ret
        elif (dataSize == OP_SIZE_WORD):
            ret = self.inPort(ioPortAddr, OP_SIZE_BYTE)
            ret |= self.inPort(ioPortAddr+1, OP_SIZE_BYTE)<<8
        else:
            self.main.exitError("Serial::inPort_3: port {0:#04x} with dataSize {1:d} not supported.", ioPortAddr, dataSize)
            return ret
        self.main.notice("Serial::inPort_4: port {0:#04x} data {1:#04x} dataSize {2:d}.", ioPortAddr, ret, dataSize)
        return ret
    cdef void outPort(self, unsigned short ioPortAddr, unsigned int data, unsigned char dataSize):
        cdef SerialPort port
        self.main.notice("Serial::outPort_1: port {0:#04x} data {1:#04x} dataSize {2:d}.", ioPortAddr, data, dataSize)
        if (dataSize == OP_SIZE_BYTE):
            if (ioPortAddr in SERIAL1_PORTS):
                port = self.ports[0]
                port.outPort(ioPortAddr-SERIAL1_PORTS[0], data, dataSize)
            elif (ioPortAddr in SERIAL2_PORTS):
                port = self.ports[1]
                port.outPort(ioPortAddr-SERIAL2_PORTS[0], data, dataSize)
            else:
                self.main.exitError("Serial::outPort_2: port {0:#04x} with dataSize {1:d} not supported. (data: {2:#06x})", ioPortAddr, dataSize, data)
        elif (dataSize == OP_SIZE_WORD):
            self.outPort(ioPortAddr, <unsigned char>data, OP_SIZE_BYTE)
            self.outPort(ioPortAddr+1, <unsigned char>(data>>8), OP_SIZE_BYTE)
        else:
            self.main.exitError("Serial::outPort_3: port {0:#04x} with dataSize {1:d} not supported. (data: {2:#06x})", ioPortAddr, dataSize, data)
        return
    cdef void run(self):
        cdef SerialPort port
        for port in self.ports:
            port.run()


