
from sys import exc_info
from atexit import register
import numpy
import pygame

include "globals.pxi"

cdef class PygameUI:
    def __init__(self, object vga, object main):
        self.vga  = vga
        self.main = main
        self.display, self.screen = None, None
        self.screenSize = 720, 400
    cpdef initPygame(self):
        pygame.display.init()
        pygame.display.set_caption('ChEmu - THE x86 Emulator written in Python. (c) 2011-2012 by Christian Inci')
        self.display = pygame.display.set_mode(self.screenSize)
        self.screen = pygame.Surface(self.screenSize)
        register(self.quitFunc)
        pygame.event.set_blocked([ pygame.ACTIVEEVENT, pygame.MOUSEMOTION, pygame.MOUSEBUTTONDOWN, pygame.MOUSEBUTTONUP,\
                                   pygame.JOYAXISMOTION, pygame.JOYBALLMOTION, pygame.JOYHATMOTION, pygame.JOYBUTTONDOWN,\
                                   pygame.JOYBUTTONUP, pygame.VIDEORESIZE, pygame.USEREVENT ])
        self.setRepeatRate(500, 10)
    cpdef quitFunc(self):
        try:
            pygame.display.quit()
        except pygame.error:
            print(exc_info())
        except (SystemExit, KeyboardInterrupt):
            print(exc_info())
            self.main.quitEmu = True
            self.main.exitError('quitFunc: (SystemExit, KeyboardInterrupt) exception, exiting...)', exitNow=True)
        except:
            print(exc_info())
        self.main.quitEmu = True
        self.main.quitFunc()
    cpdef object getCharRect(self, unsigned char x, unsigned char y):
        try:
            return pygame.Rect((UI_CHAR_WIDTH*x, self.charSize[1]*y), self.charSize)
        except pygame.error:
            print(exc_info())
        except (SystemExit, KeyboardInterrupt):
            print(exc_info())
            self.main.quitEmu = True
            self.main.exitError('getCharRect: (SystemExit, KeyboardInterrupt) exception, exiting...)', exitNow=True)
        except:
            print(exc_info())
        return None
    cdef tuple getColor(self, unsigned char color):
        if (color == 0x0): # black
            return (0, 0, 0)
        elif (color == 0x1): # blue
            return (0, 0, 0xa8)
        elif (color == 0x2): # green
            return (0, 0xa8, 0)
        elif (color == 0x3): # cyan
            return (0, 0xa8, 0xa8)
        elif (color == 0x4): # red
            return (0xa8, 0, 0)
        elif (color == 0x5): # magenta
            return (0xa8, 0, 0xa8)
        elif (color == 0x6): # brown
            return (0xa8, 0x57, 0)
        elif (color == 0x7): # light gray
            return (0xa8, 0xa8, 0xa8)
        elif (color == 0x8): # dark gray
            return (0x57, 0x57, 0x57)
        elif (color == 0x9): # light blue
            return (0x57, 0x57, 0xff)
        elif (color == 0xa): # light green
            return (0x57, 0xff, 0x57)
        elif (color == 0xb): # light cyan
            return (0x57, 0xff, 0xff)
        elif (color == 0xc): # light red
            return (0xff, 0x57, 0x57)
        elif (color == 0xd): # light magenta
            return (0xff, 0x57, 0xff)
        elif (color == 0xe): # yellow
            return (0xff, 0xff, 0x57)
        elif (color == 0xf): # white
            return (0xff, 0xff, 0xff)
        else:
            self.main.exitError('pygameUI: invalid color used. (color: {0:d})', color)
    cdef unsigned int getColorInteger(self, unsigned char color):
        cdef unsigned int returnColor = 0x000000ff
        cdef tuple colorTuple = self.getColor(color)
        returnColor |= colorTuple[0]<<24
        returnColor |= colorTuple[1]<<16
        returnColor |= colorTuple[2]<<8
        return returnColor
    cpdef object getBlankChar(self, tuple bgColor):
        cpdef object blankSurface
        blankSurface = pygame.Surface(self.charSize)
        blankSurface.fill(bgColor)
        return blankSurface
    cpdef object putChar(self, unsigned char x, unsigned char y, unsigned char character, unsigned char colors): # returns rect
        cpdef object newRect, newBack, newChar, charArray
        cdef bytes charData
        cdef list lineData
        cdef tuple fgColor, bgColor
        cdef unsigned int i, fgColorInteger
        try:
            newRect = self.getCharRect(x, y)
            fgColor, bgColor = self.getColor(colors&0xf), self.getColor((colors&0xf0)>>4)
            fgColorInteger = self.getColorInteger(colors&0xf)
            newBack = self.getBlankChar(bgColor)
            # It's not a good idea to render the character if fgColor == bgColor,
            #   as it wouldn't be readable.
            if (fgColor != bgColor and character != 0x20 and character != 0x00 and chr(character).isprintable()):
                i = character*self.charSize[1]
                charData = self.fontData[i:i+self.charSize[1]]
                charArray = numpy.zeros((self.charSize[1], UI_CHAR_WIDTH), dtype=numpy.uint32)
                for i in range(len(charData)):
                    lineData = list('{0:08b}'.format(charData[i]))
                    charArray[i] = lineData
                charArray *= fgColorInteger
                newChar = pygame.surfarray.make_surface(charArray.transpose(None))
                newBack.blit(newChar, ( (0, 0), self.charSize ))
            self.screen.blit(newBack, newRect)
            return newRect
        except pygame.error:
            print(exc_info())
        except (SystemExit, KeyboardInterrupt):
            print(exc_info())
            self.main.quitEmu = True
            self.main.exitError('putChar: (SystemExit, KeyboardInterrupt) exception, exiting...)', exitNow=True)
        except:
            print(exc_info())
    cpdef setRepeatRate(self, unsigned short delay, unsigned short interval):
        pygame.key.set_repeat(delay, interval)
    cdef unsigned char keyToScancode(self, unsigned short key):
        if (key == pygame.K_LCTRL):
            return 0x00
        elif (key == pygame.K_LSHIFT):
            return 0x01
        elif (key == pygame.K_F1):
            return 0x02
        elif (key == pygame.K_F2):
            return 0x03
        elif (key == pygame.K_F3):
            return 0x04
        elif (key == pygame.K_F4):
            return 0x05
        elif (key == pygame.K_F5):
            return 0x06
        elif (key == pygame.K_F6):
            return 0x07
        elif (key == pygame.K_F7):
            return 0x08
        elif (key == pygame.K_F8):
            return 0x09
        elif (key == pygame.K_F9):
            return 0x0a
        elif (key == pygame.K_F10):
            return 0x0b
        elif (key == pygame.K_F11):
            return 0x0c
        elif (key == pygame.K_F12):
            return 0x0d
        elif (key == pygame.K_RCTRL):
            return 0x0e
        elif (key == pygame.K_RSHIFT):
            return 0x0f
        elif (key == pygame.K_CAPSLOCK):
            return 0x10
        elif (key == pygame.K_NUMLOCK):
            return 0x11
        elif (key == pygame.K_LALT):
            return 0x12
        elif (key == pygame.K_RALT):
            return 0x13
        elif (key == pygame.K_a):
            return 0x14
        elif (key == pygame.K_b):
            return 0x15
        elif (key == pygame.K_c):
            return 0x16
        elif (key == pygame.K_d):
            return 0x17
        elif (key == pygame.K_e):
            return 0x18
        elif (key == pygame.K_f):
            return 0x19
        elif (key == pygame.K_g):
            return 0x1a
        elif (key == pygame.K_h):
            return 0x1b
        elif (key == pygame.K_i):
            return 0x1c
        elif (key == pygame.K_j):
            return 0x1d
        elif (key == pygame.K_k):
            return 0x1e
        elif (key == pygame.K_l):
            return 0x1f
        elif (key == pygame.K_m):
            return 0x20
        elif (key == pygame.K_n):
            return 0x21
        elif (key == pygame.K_o):
            return 0x22
        elif (key == pygame.K_p):
            return 0x23
        elif (key == pygame.K_q):
            return 0x24
        elif (key == pygame.K_r):
            return 0x25
        elif (key == pygame.K_s):
            return 0x26
        elif (key == pygame.K_t):
            return 0x27
        elif (key == pygame.K_u):
            return 0x28
        elif (key == pygame.K_v):
            return 0x29
        elif (key == pygame.K_w):
            return 0x2a
        elif (key == pygame.K_x):
            return 0x2b
        elif (key == pygame.K_y):
            return 0x2c
        elif (key == pygame.K_z):
            return 0x2d
        elif (key == pygame.K_0):
            return 0x2e
        elif (key == pygame.K_1):
            return 0x2f
        elif (key == pygame.K_2):
            return 0x30
        elif (key == pygame.K_3):
            return 0x31
        elif (key == pygame.K_4):
            return 0x32
        elif (key == pygame.K_5):
            return 0x33
        elif (key == pygame.K_6):
            return 0x34
        elif (key == pygame.K_7):
            return 0x35
        elif (key == pygame.K_8):
            return 0x36
        elif (key == pygame.K_9):
            return 0x37
        elif (key == pygame.K_ESCAPE):
            return 0x38
        elif (key == pygame.K_SPACE):
            return 0x39
        elif (key == pygame.K_QUOTE):
            return 0x3a
        elif (key == pygame.K_COMMA):
            return 0x3b
        elif (key == pygame.K_PERIOD):
            return 0x3c
        elif (key == pygame.K_SLASH):
            return 0x3d
        elif (key == pygame.K_SEMICOLON):
            return 0x3e
        elif (key == pygame.K_EQUALS):
            return 0x3f
        elif (key == pygame.K_LEFTBRACKET):
            return 0x40
        elif (key == pygame.K_BACKSLASH):
            return 0x41
        elif (key == pygame.K_RIGHTBRACKET):
            return 0x42
        elif (key == pygame.K_MINUS):
            return 0x43
        elif (key == pygame.K_BACKQUOTE):
            return 0x44
        elif (key == pygame.K_BACKSPACE):
            return 0x45
        elif (key == pygame.K_RETURN):
            return 0x46
        elif (key == pygame.K_TAB):
            return 0x47
        #elif (key == pygame.K_BACKSLASH): # left backslash??
        #    return 0x48
        elif (key == pygame.K_PRINT):
            return 0x49
        elif (key == pygame.K_SCROLLOCK):
            return 0x4a
        elif (key == pygame.K_PAUSE):
            return 0x4b
        elif (key == pygame.K_INSERT):
            return 0x4c
        elif (key == pygame.K_DELETE):
            return 0x4d
        elif (key == pygame.K_HOME):
            return 0x4e
        elif (key == pygame.K_END):
            return 0x4f
        elif (key == pygame.K_PAGEUP):
            return 0x50
        elif (key == pygame.K_PAGEDOWN):
            return 0x51
        elif (key == pygame.K_KP_PLUS):
            return 0x52
        elif (key == pygame.K_KP_MINUS):
            return 0x53
        #elif (key == pygame.K_KP_END):
        #    return 0x54
        #elif (key == pygame.K_KP_DOWN):
        #    return 0x55
        #elif (key == pygame.K_KP_PAGEDOWN):
        #    return 0x56
        #elif (key == pygame.K_KP_LEFT):
        #    return 0x57
        #elif (key == pygame.K_KP_RIGHT):
        #    return 0x58
        #elif (key == pygame.K_KP_HOME):
        #    return 0x59
        #elif (key == pygame.K_KP_UP):
        #    return 0x5a
        #elif (key == pygame.K_KP_PAGEUP):
        #    return 0x5b
        #elif (key == pygame.K_KP_INSERT):
        #    return 0x5c
        #elif (key == pygame.K_KP_DELETE):
        #    return 0x5d
        elif (key == pygame.K_KP5):
            return 0x5e
        elif (key == pygame.K_UP):
            return 0x5f
        elif (key == pygame.K_DOWN):
            return 0x60
        elif (key == pygame.K_LEFT):
            return 0x61
        elif (key == pygame.K_RIGHT):
            return 0x62
        elif (key == pygame.K_KP_ENTER):
            return 0x63
        elif (key == pygame.K_KP_MULTIPLY):
            return 0x64
        elif (key == pygame.K_KP_DIVIDE):
            return 0x65
        elif (key == pygame.K_LSUPER):
            return 0x66
        elif (key == pygame.K_RSUPER):
            return 0x67
        elif (key == pygame.K_MENU):
            return 0x68
        elif (key == pygame.K_SYSREQ): # OR SYSRQ?
            return 0x69
        elif (key == pygame.K_BREAK):
            return 0x6a
        self.main.notice("keyToScancode: unknown key. (keyId: {0:d}, keyName: {1:s})", key, repr(pygame.key.name(key)))
        return 0xff
    cpdef handleEvent(self, object event):
        try:
            if (event.type == pygame.QUIT):
                self.quitFunc()
            elif (event.type == pygame.VIDEOEXPOSE):
                self.updateScreen(list())
            elif (event.type == pygame.KEYDOWN):
                (<PS2>self.main.platform.ps2).keySend(self.keyToScancode(event.key), False)
            elif (event.type == pygame.KEYUP):
                (<PS2>self.main.platform.ps2).keySend(self.keyToScancode(event.key), True)
            else:
                self.main.notice("PygameUI::handleEvent: event.type == {0:d}", event.type)
        except pygame.error:
            print(exc_info())
        except (SystemExit, KeyboardInterrupt):
            print(exc_info())
            self.main.quitEmu = True
            self.main.exitError('handleEvent: (SystemExit, KeyboardInterrupt) exception, exiting...)', exitNow=True)
        except:
            print(exc_info())
    cpdef updateScreen(self, list rectList):
        try:
            if (self.display and self.screen and not self.main.quitEmu):
                self.display.blit(self.screen, ((0, 0), self.screenSize))
            pygame.display.update(rectList)
        except pygame.error:
            print(exc_info())
        except (SystemExit, KeyboardInterrupt):
            print(exc_info())
            self.main.quitEmu = True
            self.main.exitError('updateScreen: (SystemExit, KeyboardInterrupt) exception, exiting...)', exitNow=True)
        except:
            print(exc_info())
    cpdef handleEvents(self):
        cpdef object event
        cpdef list eventList
        try:
            while (not self.main.quitEmu):
                ##event = pygame.event.wait()
                eventList = pygame.event.get()
                for event in eventList:
                    self.handleEvent(event)
                pygame.time.delay(200)
        except pygame.error:
            print(exc_info())
        except (SystemExit, KeyboardInterrupt):
            print(exc_info())
            self.main.quitEmu = True
            self.main.exitError('handleEvents: (SystemExit, KeyboardInterrupt) exception, exiting...)', exitNow=True)
        except:
            print(exc_info())
    cpdef pumpEvents(self):
        try:
            pygame.event.pump()
        except pygame.error:
            self.main.quitEmu = True
    cpdef run(self):
        self.initPygame()
        (<Misc>self.main.misc).createThread(self.handleEvents, True)


