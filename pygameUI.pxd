from ps2 cimport PS2


cdef class PygameUI:
    cpdef object main, vga
    cpdef object display, screen, font
    cdef tuple screenSize, fontSize
    cdef unsigned short screenWidth, screenHeight, fontWidth, fontHeight
    cpdef initPygame(self)
    cpdef quitFunc(self)
    cpdef object getCharRect(self, unsigned char x, unsigned char y)
    cdef tuple getColor(self, unsigned char color)
    cpdef object getBlankChar(self, tuple bgColor)
    cpdef object putChar(self, unsigned char x, unsigned char y, str char, unsigned char colors) # returns rect
    cpdef setRepeatRate(self, unsigned short delay, unsigned short interval)
    cdef unsigned char keyToScancode(self, unsigned short key)
    cpdef handleEvent(self, object event)
    cpdef updateScreen(self, list rectList)
    cpdef handleEvents(self)
    cpdef run(self)


