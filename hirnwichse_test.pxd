
from libc.string cimport memcpy
from cpython.ref cimport PyObject

cdef class IdtEntry:
    pass

cdef class HirnwichseTest:
    cdef unsigned char cf, pf, af, zf, sf, tf, if_flag, df, of, iopl, \
                        nt, rf, vm, ac, vif, vip, id
    cdef void func1(self)
    cdef void func2(self, unsigned char var1)
    cdef void func3(self)
    cdef void func4(self, unsigned int flags)
    cdef void func5(self)
    cdef int func6(self) nogil
    cpdef run(self)



