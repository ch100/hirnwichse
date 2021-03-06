
#cython: language_level=3, boundscheck=False, wraparound=False, cdivision=True, profile=False, c_string_type=bytes

include "globals.pxi"

from sys import argv, exit
from argparse import ArgumentParser
from atexit import register
from traceback import print_exc

cdef extern from "Python.h":
    bytes PyBytes_FromStringAndSize(char *, Py_ssize_t)


cdef class Hirnwichse:
    def __init__(self):
        self.quitEmu = False
        self.exitOnTripleFault = True
        register(self.quitFunc, self)
        #self.run(True)
    cdef void parseArgs(self):
        self.parser = ArgumentParser(description='Hirnwichse: a x86 emulator in python.')
        self.parser.add_argument('--bios', dest='biosFilename', action='store', type=str, default='bios.bin', help='bios filename')
        self.parser.add_argument('--vgabios', dest='vgaBiosFilename', action='store', type=str, default='vgabios.bin', help='vgabios filename')
        self.parser.add_argument('-m', dest='memSize', action='store', type=int, default=64, help='memSize in MB')
        self.parser.add_argument('-L', dest='romPath', action='store', type=str, default='./bios', help='romPath')
        self.parser.add_argument('-x', dest='exitIfCpuHalted', action='store_true', default=False, help='Exit if CPU if halted')
        self.parser.add_argument('--debug', dest='debugEnabled', action='store_true', default=False, help='Debug.')
        self.parser.add_argument('--debugHalt', dest='debugHalt', action='store_true', default=False, help='Start with halted CPU')
        self.parser.add_argument('--fda', dest='fdaFilename', action='store', type=str, default='floppy0.img', help='fdaFilename')
        self.parser.add_argument('--fdb', dest='fdbFilename', action='store', type=str, default='floppy1.img', help='fdbFilename')
        self.parser.add_argument('--hda', dest='hdaFilename', action='store', type=str, default='hd0.img', help='hdaFilename')
        self.parser.add_argument('--hdb', dest='hdbFilename', action='store', type=str, default='hd1.img', help='hdbFilename')
        self.parser.add_argument('--cdrom1', dest='cdrom1Filename', action='store', type=str, default='cdrom1.iso', help='cdrom1Filename')
        self.parser.add_argument('--cdrom2', dest='cdrom2Filename', action='store', type=str, default='cdrom2.iso', help='cdrom2Filename')
        self.parser.add_argument('--serial1', dest='serial1Filename', action='store', type=str, default='', help='serial1Filename')
        self.parser.add_argument('--serial2', dest='serial2Filename', action='store', type=str, default='', help='serial2Filename')
        self.parser.add_argument('--serial3', dest='serial3Filename', action='store', type=str, default='', help='serial3Filename')
        self.parser.add_argument('--serial4', dest='serial4Filename', action='store', type=str, default='', help='serial4Filename')
        self.parser.add_argument('--boot', dest='bootFrom', action='store', type=int, default=BOOT_FROM_FD, help='bootFrom (0==none, 1==FD, 2==HD, 3==CD)')
        self.parser.add_argument('--noUI', dest='noUI', action='store_true', default=False, help='Disable UI.')
        self.parser.add_argument('--fdaType', dest='fdaType', action='store', type=int, default=4, help='fdaType: 0==auto detect; 1==360K; 2==1.2M; 3==720K; 4==1.44M; 5==2.88M')
        self.parser.add_argument('--fdbType', dest='fdbType', action='store', type=int, default=4, help='fdbType: 0==auto detect; 1==360K; 2==1.2M; 3==720K; 4==1.44M; 5==2.88M')
        self.cmdArgs = self.parser.parse_args(argv[1:])

        self.exitIfCpuHalted = self.cmdArgs.exitIfCpuHalted
        self.debugEnabled    = self.cmdArgs.debugEnabled
        self.debugEnabledTest    = self.cmdArgs.debugEnabled
        self.debugHalt    = self.cmdArgs.debugHalt
        self.noUI    = self.cmdArgs.noUI
        self.romPath = self.cmdArgs.romPath.encode() # default: './bios'
        self.biosFilename = self.cmdArgs.biosFilename.encode() # filename, default: 'bios.bin'
        self.vgaBiosFilename = self.cmdArgs.vgaBiosFilename.encode() # filename, default: 'vgabios.bin'
        self.fdaFilename = self.cmdArgs.fdaFilename.encode() # default: 'floppy0.img'
        self.fdbFilename = self.cmdArgs.fdbFilename.encode() # default: 'floppy1.img'
        self.hdaFilename = self.cmdArgs.hdaFilename.encode() # default: 'hd0.img'
        self.hdbFilename = self.cmdArgs.hdbFilename.encode() # default: 'hd1.img'
        self.cdrom1Filename = self.cmdArgs.cdrom1Filename.encode() # default: 'cdrom1.iso'
        self.cdrom2Filename = self.cmdArgs.cdrom2Filename.encode() # default: 'cdrom2.iso'
        self.serial1Filename = self.cmdArgs.serial1Filename.encode() # default: ''
        self.serial2Filename = self.cmdArgs.serial2Filename.encode() # default: ''
        self.serial3Filename = self.cmdArgs.serial3Filename.encode() # default: ''
        self.serial4Filename = self.cmdArgs.serial4Filename.encode() # default: ''
        self.bootFrom = self.cmdArgs.bootFrom # default: BOOT_FROM_FD
        self.fdaType    = self.cmdArgs.fdaType # default: 4
        self.fdbType    = self.cmdArgs.fdbType # default: 4
        self.memSize = self.cmdArgs.memSize
        #self.debugEnabledTest = False
        #self.debugEnabled = False
    cdef void quitFunc(self) nogil:
        self.quitEmu = True
        #with gil:
        #    fp=open("mmdump_1","wb")
        #    fp.write(PyBytes_FromStringAndSize( self.mm.data, <Py_ssize_t>4*1024))
        #    fp.flush()
        #    fp.close()
    cdef void exitError(self, char *msg, ...) nogil:
        cdef va_list args
        cdef char msgBuf[1024]
        va_start(args, msg)
        strcpy(msgBuf, b"ERROR: ");
        strcat(msgBuf, msg);
        strcat(msgBuf, b"\n");
        vprintf(msgBuf, args)
        va_end(args)
        fflush(stdout)
        self.cpu.cpuDump()
        self.quitFunc()
        exitt(1)
    cdef void debug(self, char *msg, ...) nogil:
        cdef va_list args
        cdef char msgBuf[1024]
        if (self.debugEnabled):
            va_start(args, msg)
            strcpy(msgBuf, b"DEBUG: ");
            strcat(msgBuf, msg);
            strcat(msgBuf, b"\n");
            vprintf(msgBuf, args)
            va_end(args)
    cdef void notice(self, char *msg, ...) nogil:
        cdef va_list args
        cdef char msgBuf[1024]
        va_start(args, msg)
        strcpy(msgBuf, b"NOTICE: ");
        strcat(msgBuf, msg);
        strcat(msgBuf, b"\n");
        vprintf(msgBuf, args)
        va_end(args)
        fflush(stdout)
    cdef void reset(self, uint8_t resetHardware):
        self.cpu.reset()
        if (resetHardware):
            self.platform.resetDevices()
    cpdef void run(self, uint8_t infiniteCycles):
        try:
            self.parseArgs()
            self.misc = Misc(self)
            self.mm = Mm(self)
            self.platform = Platform(self)
            self.cpu = Cpu(self)
            self.platform.run()
            self.cpu.run(infiniteCycles)
        except:
            print_exc()
            exit(1)
        ###



