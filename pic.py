import misc

class Pic:
    def __init__(self, main):
        self.main = main
    def inPort(self, ioPortAddr, dataSize):
        if (dataSize == misc.OP_SIZE_8BIT):
            pass
        else:
            self.main.exitError("inPort: dataSize {0:d} not supported.", dataSize)
        return 0
    def outPort(self, ioPortAddr, data, dataSize):
        if (dataSize == misc.OP_SIZE_8BIT):
            pass
        else:
            self.main.exitError("outPort: dataSize {0:d} not supported.", dataSize)
        return
    def run(self):
        self.main.platform.addReadHandlers((0x20, 0x21, 0xa0, 0xa1), self.inPort)
        self.main.platform.addWriteHandlers((0x20, 0x21, 0xa0, 0xa1), self.outPort)


