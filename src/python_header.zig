// https://github.com/ziglang/zig/issues/1499
//
// Hey, parcero! If you’re going to work on this file, make sure you follow these rules:
// 1. Clearly define your types: Whenever you use a function, ensure the parameters are properly specified to maintain some type-safety.
// 2. The use of [*c] is not allowed: In other words, don’t even think about including [*c] here, because we don’t want to see it.
// 3. Use optional pointers: If you’re returning functions or need pointers, make sure they’re optional to keep the code secure and avoid confusion.

const std = @import("std");
const builtin = @import("builtin");

pub const __off_t = c_long;
pub const __off64_t = c_long;
pub const _IO_lock_t = anyopaque;
pub extern fn __assert_fail(__assertion: ?*const u8, __file: ?*const u8, __line: c_uint, __function: ?*const u8) noreturn;
pub extern fn __assert_perror_fail(__errnum: c_int, __file: ?*const u8, __line: c_uint, __function: ?*const u8) noreturn;
pub extern fn __assert(__assertion: ?*const u8, __file: ?*const u8, __line: c_int) noreturn;
pub const struct___va_list_tag_3 = extern struct {
    gp_offset: c_uint = @import("std").mem.zeroes(c_uint),
    fp_offset: c_uint = @import("std").mem.zeroes(c_uint),
    overflow_arg_area: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
    reg_save_area: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
};
pub const struct__IO_codecvt = opaque {};
pub const struct__IO_wide_data = opaque {};
pub const struct__IO_marker = opaque {};
pub const struct__IO_FILE = extern struct {
    _flags: c_int = @import("std").mem.zeroes(c_int),
    _IO_read_ptr: ?*u8 = @import("std").mem.zeroes(?*u8),
    _IO_read_end: ?*u8 = @import("std").mem.zeroes(?*u8),
    _IO_read_base: ?*u8 = @import("std").mem.zeroes(?*u8),
    _IO_write_base: ?*u8 = @import("std").mem.zeroes(?*u8),
    _IO_write_ptr: ?*u8 = @import("std").mem.zeroes(?*u8),
    _IO_write_end: ?*u8 = @import("std").mem.zeroes(?*u8),
    _IO_buf_base: ?*u8 = @import("std").mem.zeroes(?*u8),
    _IO_buf_end: ?*u8 = @import("std").mem.zeroes(?*u8),
    _IO_save_base: ?*u8 = @import("std").mem.zeroes(?*u8),
    _IO_backup_base: ?*u8 = @import("std").mem.zeroes(?*u8),
    _IO_save_end: ?*u8 = @import("std").mem.zeroes(?*u8),
    _markers: ?*struct__IO_marker = @import("std").mem.zeroes(?*struct__IO_marker),
    _chain: ?*struct__IO_FILE = @import("std").mem.zeroes(?*struct__IO_FILE),
    _fileno: c_int = @import("std").mem.zeroes(c_int),
    _flags2: c_int = @import("std").mem.zeroes(c_int),
    _old_offset: __off_t = @import("std").mem.zeroes(__off_t),
    _cur_column: c_ushort = @import("std").mem.zeroes(c_ushort),
    _vtable_offset: i8 = @import("std").mem.zeroes(i8),
    _shortbuf: [1]u8 = @import("std").mem.zeroes([1]u8),
    _lock: ?*_IO_lock_t = @import("std").mem.zeroes(?*_IO_lock_t),
    _offset: __off64_t = @import("std").mem.zeroes(__off64_t),
    _codecvt: ?*struct__IO_codecvt = @import("std").mem.zeroes(?*struct__IO_codecvt),
    _wide_data: ?*struct__IO_wide_data = @import("std").mem.zeroes(?*struct__IO_wide_data),
    _freeres_list: ?*struct__IO_FILE = @import("std").mem.zeroes(?*struct__IO_FILE),
    _freeres_buf: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
    _prevchain: ?*?*struct__IO_FILE = @import("std").mem.zeroes(?*?*struct__IO_FILE),
    _mode: c_int = @import("std").mem.zeroes(c_int),
    _unused2: [20]u8 = @import("std").mem.zeroes([20]u8),
};
pub const __FILE = struct__IO_FILE;
pub const FILE = struct__IO_FILE;
pub const wchar_t = c_int;
pub const pthread_key_t = c_uint;
pub const __pid_t = c_int;
pub const pid_t = __pid_t;

pub const __time_t = c_long;
pub const time_t = __time_t;
pub const __syscall_slong_t = c_long;
pub const struct_timespec = extern struct {
    tv_sec: __time_t = @import("std").mem.zeroes(__time_t),
    tv_nsec: __syscall_slong_t = @import("std").mem.zeroes(__syscall_slong_t),
};
pub const __timer_t = ?*anyopaque;
pub const timer_t = __timer_t;

pub const __clockid_t = c_int;
pub const clockid_t = __clockid_t;
pub const __clock_t = c_long;
pub const clock_t = __clock_t;

pub const struct_tm = extern struct {
    tm_sec: c_int = @import("std").mem.zeroes(c_int),
    tm_min: c_int = @import("std").mem.zeroes(c_int),
    tm_hour: c_int = @import("std").mem.zeroes(c_int),
    tm_mday: c_int = @import("std").mem.zeroes(c_int),
    tm_mon: c_int = @import("std").mem.zeroes(c_int),
    tm_year: c_int = @import("std").mem.zeroes(c_int),
    tm_wday: c_int = @import("std").mem.zeroes(c_int),
    tm_yday: c_int = @import("std").mem.zeroes(c_int),
    tm_isdst: c_int = @import("std").mem.zeroes(c_int),
    tm_gmtoff: c_long = @import("std").mem.zeroes(c_long),
    tm_zone: ?*const u8 = @import("std").mem.zeroes(?*const u8),
};

pub const struct___locale_data_5 = opaque {};
pub const struct___locale_struct = extern struct {
    __locales: [13]?*struct___locale_data_5 = @import("std").mem.zeroes([13]?*struct___locale_data_5),
    __ctype_b: ?*const c_ushort = @import("std").mem.zeroes(?*const c_ushort),
    __ctype_tolower: ?*const c_int = @import("std").mem.zeroes(?*const c_int),
    __ctype_toupper: ?*const c_int = @import("std").mem.zeroes(?*const c_int),
    __names: [13]?*const u8 = @import("std").mem.zeroes([13]?*const u8),
};
pub const __locale_t = ?*struct___locale_struct;
pub const locale_t = __locale_t;

pub const __sigset_t = extern struct {
    __val: [16]c_ulong = @import("std").mem.zeroes([16]c_ulong),
};
pub const sigset_t = __sigset_t;

pub const Py_uintptr_t = usize;
pub const Py_intptr_t = isize;
pub const Py_ssize_t = isize;
pub const Py_hash_t = Py_ssize_t;
pub const Py_uhash_t = usize;
pub const Py_ssize_clean_t = Py_ssize_t;
pub extern fn PyMem_Malloc(size: usize) ?*anyopaque;
pub extern fn PyMem_Calloc(nelem: usize, elsize: usize) ?*anyopaque;
pub extern fn PyMem_Realloc(ptr: ?*anyopaque, new_size: usize) ?*anyopaque;
pub extern fn PyMem_Free(ptr: ?*anyopaque) void;
pub extern fn PyMem_RawMalloc(size: usize) ?*anyopaque;
pub extern fn PyMem_RawCalloc(nelem: usize, elsize: usize) ?*anyopaque;
pub extern fn PyMem_RawRealloc(ptr: ?*anyopaque, new_size: usize) ?*anyopaque;
pub extern fn PyMem_RawFree(ptr: ?*anyopaque) void;
pub const PYMEM_DOMAIN_RAW: c_int = 0;
pub const PYMEM_DOMAIN_MEM: c_int = 1;
pub const PYMEM_DOMAIN_OBJ: c_int = 2;
pub const PyMemAllocatorDomain = c_uint;
pub const PYMEM_ALLOCATOR_NOT_SET: c_int = 0;
pub const PYMEM_ALLOCATOR_DEFAULT: c_int = 1;
pub const PYMEM_ALLOCATOR_DEBUG: c_int = 2;
pub const PYMEM_ALLOCATOR_MALLOC: c_int = 3;
pub const PYMEM_ALLOCATOR_MALLOC_DEBUG: c_int = 4;
pub const PYMEM_ALLOCATOR_PYMALLOC: c_int = 5;
pub const PYMEM_ALLOCATOR_PYMALLOC_DEBUG: c_int = 6;
pub const PYMEM_ALLOCATOR_MIMALLOC: c_int = 7;
pub const PYMEM_ALLOCATOR_MIMALLOC_DEBUG: c_int = 8;
pub const PyMemAllocatorName = c_uint;
pub const PyMemAllocatorEx = extern struct {
    ctx: ?*anyopaque = std.mem.zeroes(?*anyopaque),
    malloc: ?*const fn (?*anyopaque, usize) callconv(.c) ?*anyopaque = std.mem.zeroes(?*const fn (?*anyopaque, usize) callconv(.c) ?*anyopaque),
    calloc: ?*const fn (?*anyopaque, usize, usize) callconv(.c) ?*anyopaque = std.mem.zeroes(?*const fn (?*anyopaque, usize, usize) callconv(.c) ?*anyopaque),
    realloc: ?*const fn (?*anyopaque, ?*anyopaque, usize) callconv(.c) ?*anyopaque = std.mem.zeroes(?*const fn (?*anyopaque, ?*anyopaque, usize) callconv(.c) ?*anyopaque),
    free: ?*const fn (?*anyopaque, ?*anyopaque) callconv(.c) void = std.mem.zeroes(?*const fn (?*anyopaque, ?*anyopaque) callconv(.c) void),
};
pub extern fn PyMem_GetAllocator(domain: PyMemAllocatorDomain, allocator: ?*PyMemAllocatorEx) void;
pub extern fn PyMem_SetAllocator(domain: PyMemAllocatorDomain, allocator: ?*PyMemAllocatorEx) void;
pub extern fn PyMem_SetupDebugHooks() void;
const union_unnamed_11 = extern union {
    ob_refcnt: Py_ssize_t,
    ob_refcnt_split: [2]u32,
};
pub const destructor = ?*const fn (?*PyObject) callconv(.c) void;
pub const getattrfunc = ?*const fn (?*PyObject, ?*u8) callconv(.c) ?*PyObject;
pub const setattrfunc = ?*const fn (?*PyObject, ?*u8, ?*PyObject) callconv(.c) c_int;
pub const reprfunc = ?*const fn (?*PyObject) callconv(.c) ?*PyObject;
pub const hashfunc = ?*const fn (?*PyObject) callconv(.c) Py_hash_t;
pub const ternaryfunc = ?*const fn (?*PyObject, ?*PyObject, ?*PyObject) callconv(.c) ?*PyObject;
pub const getattrofunc = ?*const fn (?*PyObject, ?*PyObject) callconv(.c) ?*PyObject;
pub const setattrofunc = ?*const fn (?*PyObject, ?*PyObject, ?*PyObject) callconv(.c) c_int;
pub const visitproc = ?*const fn (?*PyObject, ?*anyopaque) callconv(.c) c_int;
pub const traverseproc = ?*const fn (?*PyObject, visitproc, ?*anyopaque) callconv(.c) c_int;
pub const inquiry = ?*const fn (?*PyObject) callconv(.c) c_int;
pub const richcmpfunc = ?*const fn (?*PyObject, ?*PyObject, c_int) callconv(.c) ?*PyObject;
pub const getiterfunc = ?*const fn (?*PyObject) callconv(.c) ?*PyObject;
pub const iternextfunc = ?*const fn (?*PyObject) callconv(.c) ?*PyObject;
pub const PyCFunction = ?*const fn (?*PyObject, ?*PyObject) callconv(.c) ?*PyObject;
pub const struct_PyMethodDef = extern struct {
    ml_name: ?[*]const u8,
    ml_meth: PyCFunction,
    ml_flags: c_int,
    ml_doc: ?[*]const u8,
};
pub const PyMethodDef = struct_PyMethodDef;
pub const struct_PyMemberDef = extern struct {
    name: ?[*]const u8,
    type: c_int = std.mem.zeroes(c_int),
    offset: Py_ssize_t = std.mem.zeroes(Py_ssize_t),
    flags: c_int = std.mem.zeroes(c_int),
    doc: ?[*]const u8,
};
pub const PyMemberDef = struct_PyMemberDef;
pub const getter = ?*const fn (?*PyObject, ?*anyopaque) callconv(.c) ?*PyObject;
pub const setter = ?*const fn (?*PyObject, ?*PyObject, ?*anyopaque) callconv(.c) c_int;
pub const struct_PyGetSetDef = extern struct {
    name: ?*const u8 = std.mem.zeroes(?*const u8),
    get: getter = std.mem.zeroes(getter),
    set: setter = std.mem.zeroes(setter),
    doc: ?*const u8 = std.mem.zeroes(?*const u8),
    closure: ?*anyopaque = std.mem.zeroes(?*anyopaque),
};
pub const PyGetSetDef = struct_PyGetSetDef;
pub const descrgetfunc = ?*const fn (?*PyObject, ?*PyObject, ?*PyObject) callconv(.c) ?*PyObject;
pub const descrsetfunc = ?*const fn (?*PyObject, ?*PyObject, ?*PyObject) callconv(.c) c_int;
pub const initproc = ?*const fn (?*PyObject, ?*PyObject, ?*PyObject) callconv(.c) c_int;
pub const allocfunc = ?*const fn (?*PyTypeObject, Py_ssize_t) callconv(.c) ?*PyObject;
pub const newfunc = ?*const fn (?*PyTypeObject, ?*PyObject, ?*PyObject) callconv(.c) ?*PyObject;
pub const freefunc = ?*const fn (?*anyopaque) callconv(.c) void;
pub const vectorcallfunc = ?*const fn (?*PyObject, ?*const ?*PyObject, usize, ?*PyObject) callconv(.c) ?*PyObject;
pub const struct__typeobject = extern struct {
    ob_base: PyVarObject = std.mem.zeroes(PyVarObject),
    tp_name: [*]const u8,
    tp_basicsize: Py_ssize_t = std.mem.zeroes(Py_ssize_t),
    tp_itemsize: Py_ssize_t = std.mem.zeroes(Py_ssize_t),
    tp_dealloc: destructor = std.mem.zeroes(destructor),
    tp_vectorcall_offset: Py_ssize_t = std.mem.zeroes(Py_ssize_t),
    tp_getattr: getattrfunc = std.mem.zeroes(getattrfunc),
    tp_setattr: setattrfunc = std.mem.zeroes(setattrfunc),
    tp_as_async: ?*PyAsyncMethods = std.mem.zeroes(?*PyAsyncMethods),
    tp_repr: reprfunc = std.mem.zeroes(reprfunc),
    tp_as_number: ?*PyNumberMethods = std.mem.zeroes(?*PyNumberMethods),
    tp_as_sequence: ?*PySequenceMethods = std.mem.zeroes(?*PySequenceMethods),
    tp_as_mapping: ?*PyMappingMethods = std.mem.zeroes(?*PyMappingMethods),
    tp_hash: hashfunc = std.mem.zeroes(hashfunc),
    tp_call: ternaryfunc = std.mem.zeroes(ternaryfunc),
    tp_str: reprfunc = std.mem.zeroes(reprfunc),
    tp_getattro: getattrofunc = std.mem.zeroes(getattrofunc),
    tp_setattro: setattrofunc = std.mem.zeroes(setattrofunc),
    tp_as_buffer: ?*PyBufferProcs = std.mem.zeroes(?*PyBufferProcs),
    tp_flags: c_ulong = std.mem.zeroes(c_ulong),
    tp_doc: [*]const u8,
    tp_traverse: traverseproc = std.mem.zeroes(traverseproc),
    tp_clear: inquiry = std.mem.zeroes(inquiry),
    tp_richcompare: richcmpfunc = std.mem.zeroes(richcmpfunc),
    tp_weaklistoffset: Py_ssize_t = std.mem.zeroes(Py_ssize_t),
    tp_iter: getiterfunc = std.mem.zeroes(getiterfunc),
    tp_iternext: iternextfunc = std.mem.zeroes(iternextfunc),
    tp_methods: ?[*]PyMethodDef,
    tp_members: ?[*]PyMemberDef,
    tp_getset: ?*PyGetSetDef = std.mem.zeroes(?*PyGetSetDef),
    tp_base: ?*PyTypeObject = std.mem.zeroes(?*PyTypeObject),
    tp_dict: ?*PyObject = std.mem.zeroes(?*PyObject),
    tp_descr_get: descrgetfunc = std.mem.zeroes(descrgetfunc),
    tp_descr_set: descrsetfunc = std.mem.zeroes(descrsetfunc),
    tp_dictoffset: Py_ssize_t = std.mem.zeroes(Py_ssize_t),
    tp_init: initproc = std.mem.zeroes(initproc),
    tp_alloc: allocfunc = std.mem.zeroes(allocfunc),
    tp_new: newfunc = std.mem.zeroes(newfunc),
    tp_free: freefunc = std.mem.zeroes(freefunc),
    tp_is_gc: inquiry = std.mem.zeroes(inquiry),
    tp_bases: ?*PyObject = std.mem.zeroes(?*PyObject),
    tp_mro: ?*PyObject = std.mem.zeroes(?*PyObject),
    tp_cache: ?*PyObject = std.mem.zeroes(?*PyObject),
    tp_subclasses: ?*anyopaque = std.mem.zeroes(?*anyopaque),
    tp_weaklist: ?*PyObject = std.mem.zeroes(?*PyObject),
    tp_del: destructor = std.mem.zeroes(destructor),
    tp_version_tag: c_uint = std.mem.zeroes(c_uint),
    tp_finalize: destructor = std.mem.zeroes(destructor),
    tp_vectorcall: vectorcallfunc = std.mem.zeroes(vectorcallfunc),
    tp_watched: u8 = std.mem.zeroes(u8),
    tp_versions_used: u16 = std.mem.zeroes(u16),
};
pub const PyTypeObject = struct__typeobject;
pub const struct__object = extern struct {
    unnamed_0: union_unnamed_11 = std.mem.zeroes(union_unnamed_11),
    ob_type: ?*PyTypeObject = std.mem.zeroes(?*PyTypeObject),
};
pub const PyObject = struct__object;
pub const struct_PyModuleDef_Base = extern struct {
    ob_base: PyObject = std.mem.zeroes(PyObject),
    m_init: ?*const fn () callconv(.c) ?*PyObject = std.mem.zeroes(?*const fn () callconv(.c) ?*PyObject),
    m_index: Py_ssize_t = std.mem.zeroes(Py_ssize_t),
    m_copy: ?*PyObject = std.mem.zeroes(?*PyObject),
};
pub const PyModuleDef_Base = struct_PyModuleDef_Base;
pub const struct_PyModuleDef_Slot = extern struct {
    slot: c_int = std.mem.zeroes(c_int),
    value: ?*anyopaque = std.mem.zeroes(?*anyopaque),
};
pub const PyModuleDef_Slot = struct_PyModuleDef_Slot;
pub const struct_PyModuleDef = extern struct {
    m_base: PyModuleDef_Base = std.mem.zeroes(PyModuleDef_Base),
    m_name: [*]const u8,
    m_doc: [*]const u8,
    m_size: Py_ssize_t = std.mem.zeroes(Py_ssize_t),
    m_methods: ?*PyMethodDef = std.mem.zeroes(?*PyMethodDef),
    m_slots: ?*PyModuleDef_Slot = std.mem.zeroes(?*PyModuleDef_Slot),
    m_traverse: traverseproc = std.mem.zeroes(traverseproc),
    m_clear: inquiry = std.mem.zeroes(inquiry),
    m_free: freefunc = std.mem.zeroes(freefunc),
};
pub const PyModuleDef = struct_PyModuleDef;
pub const digit = u32;
pub const struct__PyLongValue = extern struct {
    lv_tag: usize = std.mem.zeroes(usize),
    ob_digit: [1]digit = std.mem.zeroes([1]digit),
};
pub const _PyLongValue = struct__PyLongValue;
pub const struct__longobject = extern struct {
    ob_base: PyObject = std.mem.zeroes(PyObject),
    long_value: _PyLongValue = std.mem.zeroes(_PyLongValue),
};
pub const PyLongObject = struct__longobject;
pub const struct_PyCodeObject = extern struct {
    ob_base: PyVarObject = std.mem.zeroes(PyVarObject),
    co_consts: ?*PyObject = std.mem.zeroes(?*PyObject),
    co_names: ?*PyObject = std.mem.zeroes(?*PyObject),
    co_exceptiontable: ?*PyObject = std.mem.zeroes(?*PyObject),
    co_flags: c_int = std.mem.zeroes(c_int),
    co_argcount: c_int = std.mem.zeroes(c_int),
    co_posonlyargcount: c_int = std.mem.zeroes(c_int),
    co_kwonlyargcount: c_int = std.mem.zeroes(c_int),
    co_stacksize: c_int = std.mem.zeroes(c_int),
    co_firstlineno: c_int = std.mem.zeroes(c_int),
    co_nlocalsplus: c_int = std.mem.zeroes(c_int),
    co_framesize: c_int = std.mem.zeroes(c_int),
    co_nlocals: c_int = std.mem.zeroes(c_int),
    co_ncellvars: c_int = std.mem.zeroes(c_int),
    co_nfreevars: c_int = std.mem.zeroes(c_int),
    co_version: u32 = std.mem.zeroes(u32),
    co_localsplusnames: ?*PyObject = std.mem.zeroes(?*PyObject),
    co_localspluskinds: ?*PyObject = std.mem.zeroes(?*PyObject),
    co_filename: ?*PyObject = std.mem.zeroes(?*PyObject),
    co_name: ?*PyObject = std.mem.zeroes(?*PyObject),
    co_qualname: ?*PyObject = std.mem.zeroes(?*PyObject),
    co_linetable: ?*PyObject = std.mem.zeroes(?*PyObject),
    co_weakreflist: ?*PyObject = std.mem.zeroes(?*PyObject),
    co_executors: ?*_PyExecutorArray = std.mem.zeroes(?*_PyExecutorArray),
    _co_cached: ?*_PyCoCached = std.mem.zeroes(?*_PyCoCached),
    _co_instrumentation_version: usize = std.mem.zeroes(usize),
    _co_monitoring: ?*_PyCoMonitoringData = std.mem.zeroes(?*_PyCoMonitoringData),
    _co_firsttraceable: c_int = std.mem.zeroes(c_int),
    co_extra: ?*anyopaque = std.mem.zeroes(?*anyopaque),
    co_code_adaptive: [1]u8 = std.mem.zeroes([1]u8),
};
pub const PyCodeObject = struct_PyCodeObject;
pub const struct__frame = opaque {};
pub const PyFrameObject = struct__frame;
pub const PyThreadState = opaque {};
pub const struct__is = opaque {};
pub const PyInterpreterState = struct__is;
// /usr/include/python3.13/cpython/pystate.h:76:22: warning: struct demoted to opaque type - has bitfield
const struct_unnamed_12 = opaque {};
pub const struct__PyInterpreterFrame = opaque {};
pub const Py_tracefunc = ?*const fn (?*PyObject, ?*PyFrameObject, c_int, ?*PyObject) callconv(.c) c_int;
pub const struct__err_stackitem = extern struct {
    exc_value: ?*PyObject = std.mem.zeroes(?*PyObject),
    previous_item: ?*struct__err_stackitem = std.mem.zeroes(?*struct__err_stackitem),
};
pub const _PyErr_StackItem = struct__err_stackitem;
pub const struct__stack_chunk = extern struct {
    previous: ?*struct__stack_chunk = std.mem.zeroes(?*struct__stack_chunk),
    size: usize = std.mem.zeroes(usize),
    top: usize = std.mem.zeroes(usize),
    data: [1]?*PyObject = std.mem.zeroes([1]?*PyObject),
};
pub const _PyStackChunk = struct__stack_chunk;
pub const Py_buffer = extern struct {
    buf: ?*anyopaque = std.mem.zeroes(?*anyopaque),
    obj: ?*PyObject = std.mem.zeroes(?*PyObject),
    len: Py_ssize_t = std.mem.zeroes(Py_ssize_t),
    itemsize: Py_ssize_t = std.mem.zeroes(Py_ssize_t),
    readonly: c_int = std.mem.zeroes(c_int),
    ndim: c_int = std.mem.zeroes(c_int),
    format: ?*u8 = std.mem.zeroes(?*u8),
    shape: ?*Py_ssize_t = std.mem.zeroes(?*Py_ssize_t),
    strides: ?*Py_ssize_t = std.mem.zeroes(?*Py_ssize_t),
    suboffsets: ?*Py_ssize_t = std.mem.zeroes(?*Py_ssize_t),
    internal: ?*anyopaque = std.mem.zeroes(?*anyopaque),
};
pub const getbufferproc = ?*const fn (?*PyObject, ?*Py_buffer, c_int) callconv(.c) c_int;
pub const releasebufferproc = ?*const fn (?*PyObject, ?*Py_buffer) callconv(.c) void;
pub extern fn PyObject_CheckBuffer(obj: ?*PyObject) c_int;
pub extern fn PyObject_GetBuffer(obj: ?*PyObject, view: ?*Py_buffer, flags: c_int) c_int;
pub extern fn PyBuffer_GetPointer(view: ?*const Py_buffer, indices: ?*const Py_ssize_t) ?*anyopaque;
pub extern fn PyBuffer_SizeFromFormat(format: ?*const u8) Py_ssize_t;
pub extern fn PyBuffer_ToContiguous(buf: ?*anyopaque, view: ?*const Py_buffer, len: Py_ssize_t, order: u8) c_int;
pub extern fn PyBuffer_FromContiguous(view: ?*const Py_buffer, buf: ?*const anyopaque, len: Py_ssize_t, order: u8) c_int;
pub extern fn PyObject_CopyData(dest: ?*PyObject, src: ?*PyObject) c_int;
pub extern fn PyBuffer_IsContiguous(view: ?*const Py_buffer, fort: u8) c_int;
pub extern fn PyBuffer_FillContiguousStrides(ndims: c_int, shape: ?*Py_ssize_t, strides: ?*Py_ssize_t, itemsize: c_int, fort: u8) void;
pub extern fn PyBuffer_FillInfo(view: ?*Py_buffer, o: ?*PyObject, buf: ?*anyopaque, len: Py_ssize_t, readonly: c_int, flags: c_int) c_int;
pub extern fn PyBuffer_Release(view: ?*Py_buffer) void;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:15:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:14:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_add_int(arg_obj: ?*c_int, arg_value: c_int) callconv(.c) c_int;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:19:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:18:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_add_int8(arg_obj: ?*i8, arg_value: i8) callconv(.c) i8;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:23:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:22:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_add_int16(arg_obj: ?*i16, arg_value: i16) callconv(.c) i16;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:27:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:26:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_add_int32(arg_obj: ?*i32, arg_value: i32) callconv(.c) i32;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:31:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:30:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_add_int64(arg_obj: ?*i64, arg_value: i64) callconv(.c) i64;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:35:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:34:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_add_intptr(arg_obj: ?*isize, arg_value: isize) callconv(.c) isize;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:39:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:38:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_add_uint(arg_obj: ?*c_uint, arg_value: c_uint) callconv(.c) c_uint;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:43:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:42:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_add_uint8(arg_obj: ?*u8, arg_value: u8) callconv(.c) u8;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:47:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:46:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_add_uint16(arg_obj: ?*u16, arg_value: u16) callconv(.c) u16;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:51:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:50:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_add_uint32(arg_obj: ?*u32, arg_value: u32) callconv(.c) u32;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:55:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:54:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_add_uint64(arg_obj: ?*u64, arg_value: u64) callconv(.c) u64;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:59:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:58:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_add_uintptr(arg_obj: ?*usize, arg_value: usize) callconv(.c) usize;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:63:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:62:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_add_ssize(arg_obj: ?*Py_ssize_t, arg_value: Py_ssize_t) callconv(.c) Py_ssize_t;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:70:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:69:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_compare_exchange_int(arg_obj: ?*c_int, arg_expected: ?*c_int, arg_desired: c_int) callconv(.c) c_int;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:75:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:74:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_compare_exchange_int8(arg_obj: ?*i8, arg_expected: ?*i8, arg_desired: i8) callconv(.c) c_int;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:80:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:79:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_compare_exchange_int16(arg_obj: ?*i16, arg_expected: ?*i16, arg_desired: i16) callconv(.c) c_int;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:85:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:84:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_compare_exchange_int32(arg_obj: ?*i32, arg_expected: ?*i32, arg_desired: i32) callconv(.c) c_int;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:90:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:89:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_compare_exchange_int64(arg_obj: ?*i64, arg_expected: ?*i64, arg_desired: i64) callconv(.c) c_int;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:95:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:94:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_compare_exchange_intptr(arg_obj: ?*isize, arg_expected: ?*isize, arg_desired: isize) callconv(.c) c_int;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:100:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:99:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_compare_exchange_uint(arg_obj: ?*c_uint, arg_expected: ?*c_uint, arg_desired: c_uint) callconv(.c) c_int;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:105:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:104:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_compare_exchange_uint8(arg_obj: ?*u8, arg_expected: ?*u8, arg_desired: u8) callconv(.c) c_int;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:110:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:109:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_compare_exchange_uint16(arg_obj: ?*u16, arg_expected: ?*u16, arg_desired: u16) callconv(.c) c_int;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:115:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:114:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_compare_exchange_uint32(arg_obj: ?*u32, arg_expected: ?*u32, arg_desired: u32) callconv(.c) c_int;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:120:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:119:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_compare_exchange_uint64(arg_obj: ?*u64, arg_expected: ?*u64, arg_desired: u64) callconv(.c) c_int;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:125:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:124:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_compare_exchange_uintptr(arg_obj: ?*usize, arg_expected: ?*usize, arg_desired: usize) callconv(.c) c_int;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:130:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:129:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_compare_exchange_ssize(arg_obj: ?*Py_ssize_t, arg_expected: ?*Py_ssize_t, arg_desired: Py_ssize_t) callconv(.c) c_int;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:135:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:134:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_compare_exchange_ptr(arg_obj: ?*anyopaque, arg_expected: ?*anyopaque, arg_desired: ?*anyopaque) callconv(.c) c_int;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:143:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:142:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_exchange_int(arg_obj: ?*c_int, arg_value: c_int) callconv(.c) c_int;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:147:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:146:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_exchange_int8(arg_obj: ?*i8, arg_value: i8) callconv(.c) i8;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:151:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:150:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_exchange_int16(arg_obj: ?*i16, arg_value: i16) callconv(.c) i16;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:155:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:154:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_exchange_int32(arg_obj: ?*i32, arg_value: i32) callconv(.c) i32;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:159:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:158:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_exchange_int64(arg_obj: ?*i64, arg_value: i64) callconv(.c) i64;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:163:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:162:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_exchange_intptr(arg_obj: ?*isize, arg_value: isize) callconv(.c) isize;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:167:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:166:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_exchange_uint(arg_obj: ?*c_uint, arg_value: c_uint) callconv(.c) c_uint;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:171:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:170:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_exchange_uint8(arg_obj: ?*u8, arg_value: u8) callconv(.c) u8;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:175:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:174:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_exchange_uint16(arg_obj: ?*u16, arg_value: u16) callconv(.c) u16;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:179:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:178:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_exchange_uint32(arg_obj: ?*u32, arg_value: u32) callconv(.c) u32;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:183:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:182:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_exchange_uint64(arg_obj: ?*u64, arg_value: u64) callconv(.c) u64;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:187:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:186:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_exchange_uintptr(arg_obj: ?*usize, arg_value: usize) callconv(.c) usize;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:191:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:190:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_exchange_ssize(arg_obj: ?*Py_ssize_t, arg_value: Py_ssize_t) callconv(.c) Py_ssize_t;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:195:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:194:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_exchange_ptr(arg_obj: ?*anyopaque, arg_value: ?*anyopaque) callconv(.c) ?*anyopaque;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:202:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:201:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_and_uint8(arg_obj: ?*u8, arg_value: u8) callconv(.c) u8;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:206:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:205:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_and_uint16(arg_obj: ?*u16, arg_value: u16) callconv(.c) u16;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:210:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:209:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_and_uint32(arg_obj: ?*u32, arg_value: u32) callconv(.c) u32;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:214:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:213:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_and_uint64(arg_obj: ?*u64, arg_value: u64) callconv(.c) u64;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:218:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:217:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_and_uintptr(arg_obj: ?*usize, arg_value: usize) callconv(.c) usize;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:225:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:224:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_or_uint8(arg_obj: ?*u8, arg_value: u8) callconv(.c) u8;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:229:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:228:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_or_uint16(arg_obj: ?*u16, arg_value: u16) callconv(.c) u16;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:233:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:232:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_or_uint32(arg_obj: ?*u32, arg_value: u32) callconv(.c) u32;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:237:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:236:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_or_uint64(arg_obj: ?*u64, arg_value: u64) callconv(.c) u64;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:241:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:240:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_or_uintptr(arg_obj: ?*usize, arg_value: usize) callconv(.c) usize;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:248:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:247:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_load_int(arg_obj: ?*const c_int) callconv(.c) c_int;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:252:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:251:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_load_int8(arg_obj: ?*const i8) callconv(.c) i8;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:256:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:255:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_load_int16(arg_obj: ?*const i16) callconv(.c) i16;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:260:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:259:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_load_int32(arg_obj: ?*const i32) callconv(.c) i32;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:264:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:263:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_load_int64(arg_obj: ?*const i64) callconv(.c) i64;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:268:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:267:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_load_intptr(arg_obj: ?*const isize) callconv(.c) isize;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:272:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:271:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_load_uint8(arg_obj: ?*const u8) callconv(.c) u8;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:276:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:275:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_load_uint16(arg_obj: ?*const u16) callconv(.c) u16;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:280:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:279:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_load_uint32(arg_obj: ?*const u32) callconv(.c) u32;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:284:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:283:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_load_uint64(arg_obj: ?*const u64) callconv(.c) u64;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:288:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:287:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_load_uintptr(arg_obj: ?*const usize) callconv(.c) usize;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:292:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:291:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_load_uint(arg_obj: ?*const c_uint) callconv(.c) c_uint;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:296:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:295:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_load_ssize(arg_obj: ?*const Py_ssize_t) callconv(.c) Py_ssize_t;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:300:18: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:299:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_load_ptr(arg_obj: ?*const anyopaque) callconv(.c) ?*anyopaque;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:307:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:306:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_load_int_relaxed(arg_obj: ?*const c_int) callconv(.c) c_int;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:311:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:310:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_load_int8_relaxed(arg_obj: ?*const i8) callconv(.c) i8;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:315:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:314:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_load_int16_relaxed(arg_obj: ?*const i16) callconv(.c) i16;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:319:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:318:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_load_int32_relaxed(arg_obj: ?*const i32) callconv(.c) i32;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:323:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:322:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_load_int64_relaxed(arg_obj: ?*const i64) callconv(.c) i64;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:327:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:326:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_load_intptr_relaxed(arg_obj: ?*const isize) callconv(.c) isize;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:331:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:330:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_load_uint8_relaxed(arg_obj: ?*const u8) callconv(.c) u8;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:335:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:334:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_load_uint16_relaxed(arg_obj: ?*const u16) callconv(.c) u16;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:339:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:338:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_load_uint32_relaxed(arg_obj: ?*const u32) callconv(.c) u32;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:343:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:342:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_load_uint64_relaxed(arg_obj: ?*const u64) callconv(.c) u64;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:347:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:346:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_load_uintptr_relaxed(arg_obj: ?*const usize) callconv(.c) usize;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:351:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:350:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_load_uint_relaxed(arg_obj: ?*const c_uint) callconv(.c) c_uint;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:355:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:354:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_load_ssize_relaxed(arg_obj: ?*const Py_ssize_t) callconv(.c) Py_ssize_t;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:359:18: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:358:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_load_ptr_relaxed(arg_obj: ?*const anyopaque) callconv(.c) ?*anyopaque;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:363:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:362:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_load_ullong_relaxed(arg_obj: ?*const c_ulonglong) callconv(.c) c_ulonglong;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:370:3: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:369:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_store_int(arg_obj: ?*c_int, arg_value: c_int) callconv(.c) void;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:374:3: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:373:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_store_int8(arg_obj: ?*i8, arg_value: i8) callconv(.c) void;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:378:3: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:377:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_store_int16(arg_obj: ?*i16, arg_value: i16) callconv(.c) void;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:382:3: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:381:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_store_int32(arg_obj: ?*i32, arg_value: i32) callconv(.c) void;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:386:3: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:385:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_store_int64(arg_obj: ?*i64, arg_value: i64) callconv(.c) void;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:390:3: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:389:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_store_intptr(arg_obj: ?*isize, arg_value: isize) callconv(.c) void;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:394:3: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:393:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_store_uint8(arg_obj: ?*u8, arg_value: u8) callconv(.c) void;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:398:3: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:397:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_store_uint16(arg_obj: ?*u16, arg_value: u16) callconv(.c) void;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:402:3: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:401:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_store_uint32(arg_obj: ?*u32, arg_value: u32) callconv(.c) void;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:406:3: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:405:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_store_uint64(arg_obj: ?*u64, arg_value: u64) callconv(.c) void;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:410:3: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:409:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_store_uintptr(arg_obj: ?*usize, arg_value: usize) callconv(.c) void;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:414:3: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:413:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_store_uint(arg_obj: ?*c_uint, arg_value: c_uint) callconv(.c) void;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:418:3: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:417:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_store_ptr(arg_obj: ?*anyopaque, arg_value: ?*anyopaque) callconv(.c) void;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:422:3: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:421:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_store_ssize(arg_obj: ?*Py_ssize_t, arg_value: Py_ssize_t) callconv(.c) void;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:429:3: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:428:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_store_int_relaxed(arg_obj: ?*c_int, arg_value: c_int) callconv(.c) void;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:433:3: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:432:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_store_int8_relaxed(arg_obj: ?*i8, arg_value: i8) callconv(.c) void;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:437:3: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:436:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_store_int16_relaxed(arg_obj: ?*i16, arg_value: i16) callconv(.c) void;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:441:3: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:440:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_store_int32_relaxed(arg_obj: ?*i32, arg_value: i32) callconv(.c) void;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:445:3: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:444:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_store_int64_relaxed(arg_obj: ?*i64, arg_value: i64) callconv(.c) void;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:449:3: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:448:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_store_intptr_relaxed(arg_obj: ?*isize, arg_value: isize) callconv(.c) void;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:453:3: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:452:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_store_uint8_relaxed(arg_obj: ?*u8, arg_value: u8) callconv(.c) void;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:457:3: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:456:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_store_uint16_relaxed(arg_obj: ?*u16, arg_value: u16) callconv(.c) void;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:461:3: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:460:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_store_uint32_relaxed(arg_obj: ?*u32, arg_value: u32) callconv(.c) void;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:465:3: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:464:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_store_uint64_relaxed(arg_obj: ?*u64, arg_value: u64) callconv(.c) void;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:469:3: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:468:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_store_uintptr_relaxed(arg_obj: ?*usize, arg_value: usize) callconv(.c) void;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:473:3: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:472:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_store_uint_relaxed(arg_obj: ?*c_uint, arg_value: c_uint) callconv(.c) void;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:477:3: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:476:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_store_ptr_relaxed(arg_obj: ?*anyopaque, arg_value: ?*anyopaque) callconv(.c) void;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:481:3: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:480:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_store_ssize_relaxed(arg_obj: ?*Py_ssize_t, arg_value: Py_ssize_t) callconv(.c) void;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:486:3: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:484:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_store_ullong_relaxed(arg_obj: ?*c_ulonglong, arg_value: c_ulonglong) callconv(.c) void;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:493:18: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:492:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_load_ptr_acquire(arg_obj: ?*const anyopaque) callconv(.c) ?*anyopaque;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:497:21: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:496:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_load_uintptr_acquire(arg_obj: ?*const usize) callconv(.c) usize;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:501:3: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:500:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_store_ptr_release(arg_obj: ?*anyopaque, arg_value: ?*anyopaque) callconv(.c) void;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:505:3: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:504:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_store_uintptr_release(arg_obj: ?*usize, arg_value: usize) callconv(.c) void;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:513:3: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:512:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_store_ssize_release(arg_obj: ?*Py_ssize_t, arg_value: Py_ssize_t) callconv(.c) void;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:509:3: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:508:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_store_int_release(arg_obj: ?*c_int, arg_value: c_int) callconv(.c) void;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:517:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:516:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_load_int_acquire(arg_obj: ?*const c_int) callconv(.c) c_int;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:521:3: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:520:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_store_uint32_release(arg_obj: ?*u32, arg_value: u32) callconv(.c) void;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:525:3: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:524:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_store_uint64_release(arg_obj: ?*u64, arg_value: u64) callconv(.c) void;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:529:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:528:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_load_uint64_acquire(arg_obj: ?*const u64) callconv(.c) u64;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:533:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:532:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_load_uint32_acquire(arg_obj: ?*const u32) callconv(.c) u32;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:537:10: warning: TODO implement translation of stmt class AtomicExprClass

// /usr/include/python3.13/cpython/pyatomic_gcc.h:536:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_load_ssize_acquire(arg_obj: ?*const Py_ssize_t) callconv(.c) Py_ssize_t;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:543:3: warning: TODO implement function '__atomic_thread_fence' in std.zig.c_builtins

// /usr/include/python3.13/cpython/pyatomic_gcc.h:542:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_fence_seq_cst() callconv(.c) void;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:547:3: warning: TODO implement function '__atomic_thread_fence' in std.zig.c_builtins

// /usr/include/python3.13/cpython/pyatomic_gcc.h:546:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_fence_acquire() callconv(.c) void;
// /usr/include/python3.13/cpython/pyatomic_gcc.h:551:3: warning: TODO implement function '__atomic_thread_fence' in std.zig.c_builtins

// /usr/include/python3.13/cpython/pyatomic_gcc.h:550:1: warning: unable to translate function, demoted to extern
pub extern fn _Py_atomic_fence_release() callconv(.c) void;
pub const struct_PyMutex = extern struct {
    _bits: u8 = std.mem.zeroes(u8),
};
pub const PyMutex = struct_PyMutex;
pub extern fn PyMutex_Lock(m: ?*PyMutex) void;
pub extern fn PyMutex_Unlock(m: ?*PyMutex) void;
pub fn _PyMutex_Lock(arg_m: ?*PyMutex) callconv(.c) void {
    var m = arg_m;
    _ = &m;
    var expected: u8 = 0;
    _ = &expected;
    if (!(_Py_atomic_compare_exchange_uint8(&m.*._bits, &expected, @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 1)))))) != 0)) {
        PyMutex_Lock(m);
    }
}
pub fn _PyMutex_Unlock(arg_m: ?*PyMutex) callconv(.c) void {
    var m = arg_m;
    _ = &m;
    var expected: u8 = 1;
    _ = &expected;
    if (!(_Py_atomic_compare_exchange_uint8(&m.*._bits, &expected, @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 0)))))) != 0)) {
        PyMutex_Unlock(m);
    }
}
pub const PyVarObject = extern struct {
    ob_base: PyObject = std.mem.zeroes(PyObject),
    ob_size: Py_ssize_t = std.mem.zeroes(Py_ssize_t),
};
pub extern fn Py_Is(x: ?*PyObject, y: ?*PyObject) c_int;
pub fn Py_REFCNT(arg_ob: ?*PyObject) callconv(.c) Py_ssize_t {
    var ob = arg_ob;
    _ = &ob;
    return ob.*.unnamed_0.ob_refcnt;
}
pub fn Py_TYPE(arg_ob: ?*PyObject) callconv(.c) ?*PyTypeObject {
    var ob = arg_ob;
    _ = &ob;
    return ob.?.ob_type;
}
pub extern var PyLong_Type: PyTypeObject;
pub extern var PyBool_Type: PyTypeObject;
pub inline fn _Py_IsImmortal(arg_op: ?*PyObject) c_int {
    var op = arg_op;
    _ = &op;
    return @intFromBool(@as(i32, @bitCast(@as(c_int, @truncate(op.*.unnamed_0.ob_refcnt)))) < @as(c_int, 0));
}
pub fn Py_IS_TYPE(arg_ob: ?*PyObject, arg_type: ?*PyTypeObject) callconv(.c) c_int {
    var ob = arg_ob;
    _ = &ob;
    var @"type" = arg_type;
    _ = &@"type";
    return @intFromBool(Py_TYPE(ob) == @"type");
}
pub extern fn _Py_SetRefcnt(ob: ?*PyObject, refcnt: Py_ssize_t) void;
pub fn Py_SET_REFCNT(arg_ob: ?*PyObject, arg_refcnt: Py_ssize_t) callconv(.c) void {
    var ob = arg_ob;
    _ = &ob;
    var refcnt = arg_refcnt;
    _ = &refcnt;
    if (_Py_IsImmortal(ob) != 0) {
        return;
    }
    ob.*.unnamed_0.ob_refcnt = refcnt;
}
pub fn Py_SET_TYPE(arg_ob: ?*PyObject, arg_type: ?*PyTypeObject) callconv(.c) void {
    var ob = arg_ob;
    _ = &ob;
    var @"type" = arg_type;
    _ = &@"type";
    ob.*.ob_type = @"type";
}
pub const unaryfunc = ?*const fn (?*PyObject) callconv(.c) ?*PyObject;
pub const binaryfunc = ?*const fn (?*PyObject, ?*PyObject) callconv(.c) ?*PyObject;
pub const lenfunc = ?*const fn (?*PyObject) callconv(.c) Py_ssize_t;
pub const ssizeargfunc = ?*const fn (?*PyObject, Py_ssize_t) callconv(.c) ?*PyObject;
pub const ssizessizeargfunc = ?*const fn (?*PyObject, Py_ssize_t, Py_ssize_t) callconv(.c) ?*PyObject;
pub const ssizeobjargproc = ?*const fn (?*PyObject, Py_ssize_t, ?*PyObject) callconv(.c) c_int;
pub const ssizessizeobjargproc = ?*const fn (?*PyObject, Py_ssize_t, Py_ssize_t, ?*PyObject) callconv(.c) c_int;
pub const objobjargproc = ?*const fn (?*PyObject, ?*PyObject, ?*PyObject) callconv(.c) c_int;
pub const objobjproc = ?*const fn (?*PyObject, ?*PyObject) callconv(.c) c_int;
pub const PyType_Slot = extern struct {
    slot: c_int = std.mem.zeroes(c_int),
    pfunc: ?*anyopaque = std.mem.zeroes(?*anyopaque),
};
pub const PyType_Spec = extern struct {
    name: ?*const u8 = std.mem.zeroes(?*const u8),
    basicsize: c_int = std.mem.zeroes(c_int),
    itemsize: c_int = std.mem.zeroes(c_int),
    flags: c_uint = std.mem.zeroes(c_uint),
    slots: ?*PyType_Slot = std.mem.zeroes(?*PyType_Slot),
};
pub extern fn PyType_FromSpec(?*PyType_Spec) ?*PyObject;
pub extern fn PyType_FromSpecWithBases(?*PyType_Spec, ?*PyObject) ?*PyObject;
pub extern fn PyType_GetSlot(?*PyTypeObject, c_int) ?*anyopaque;
pub extern fn PyType_FromModuleAndSpec(?*PyObject, ?*PyType_Spec, ?*PyObject) ?*PyObject;
pub extern fn PyType_GetModule(?*PyTypeObject) ?*PyObject;
pub extern fn PyType_GetModuleState(?*PyTypeObject) ?*anyopaque;
pub extern fn PyType_GetName(?*PyTypeObject) ?*PyObject;
pub extern fn PyType_GetQualName(?*PyTypeObject) ?*PyObject;
pub extern fn PyType_GetFullyQualifiedName(@"type": ?*PyTypeObject) ?*PyObject;
pub extern fn PyType_GetModuleName(@"type": ?*PyTypeObject) ?*PyObject;
pub extern fn PyType_FromMetaclass(?*PyTypeObject, ?*PyObject, ?*PyType_Spec, ?*PyObject) ?*PyObject;
pub extern fn PyObject_GetTypeData(obj: ?*PyObject, cls: ?*PyTypeObject) ?*anyopaque;
pub extern fn PyType_GetTypeDataSize(cls: ?*PyTypeObject) Py_ssize_t;
pub extern fn PyType_IsSubtype(?*PyTypeObject, ?*PyTypeObject) c_int;
pub fn PyObject_TypeCheck(arg_ob: ?*PyObject, arg_type: ?*PyTypeObject) callconv(.c) c_int {
    var ob = arg_ob;
    _ = &ob;
    var @"type" = arg_type;
    _ = &@"type";
    return @intFromBool((Py_IS_TYPE(ob, @"type") != 0) or (PyType_IsSubtype(Py_TYPE(ob), @"type") != 0));
}
pub extern var PyType_Type: PyTypeObject;
pub extern var PyBaseObject_Type: PyTypeObject;
pub extern var PySuper_Type: PyTypeObject;
pub extern fn PyType_GetFlags(?*PyTypeObject) c_ulong;
pub extern fn PyType_Ready(?*PyTypeObject) c_int;
pub extern fn PyType_GenericAlloc(?*PyTypeObject, Py_ssize_t) ?*PyObject;
pub extern fn PyType_GenericNew(?*PyTypeObject, ?*PyObject, ?*PyObject) ?*PyObject;
pub extern fn PyType_ClearCache() c_uint;
pub extern fn PyType_Modified(?*PyTypeObject) void;
pub extern fn PyObject_Repr(?*PyObject) ?*PyObject;
pub extern fn PyObject_Str(?*PyObject) ?*PyObject;
pub extern fn PyObject_ASCII(?*PyObject) ?*PyObject;
pub extern fn PyObject_Bytes(?*PyObject) ?*PyObject;
pub extern fn PyObject_RichCompare(?*PyObject, ?*PyObject, c_int) ?*PyObject;
pub extern fn PyObject_RichCompareBool(?*PyObject, ?*PyObject, c_int) c_int;
pub extern fn PyObject_GetAttrString(?*PyObject, [*]const u8) ?*PyObject;
pub extern fn PyObject_SetAttrString(?*PyObject, [*]const u8, ?*PyObject) c_int;
pub extern fn PyObject_DelAttrString(v: ?*PyObject, name: ?*const u8) c_int;
pub extern fn PyObject_HasAttrString(?*PyObject, ?*const u8) c_int;
pub extern fn PyObject_GetAttr(?*PyObject, ?*PyObject) ?*PyObject;
pub extern fn PyObject_GetOptionalAttr(?*PyObject, ?*PyObject, ?*?*PyObject) c_int;
pub extern fn PyObject_GetOptionalAttrString(?*PyObject, ?*const u8, ?*?*PyObject) c_int;
pub extern fn PyObject_SetAttr(?*PyObject, ?*PyObject, ?*PyObject) c_int;
pub extern fn PyObject_DelAttr(v: ?*PyObject, name: ?*PyObject) c_int;
pub extern fn PyObject_HasAttr(?*PyObject, ?*PyObject) c_int;
pub extern fn PyObject_HasAttrWithError(?*PyObject, ?*PyObject) c_int;
pub extern fn PyObject_HasAttrStringWithError(?*PyObject, ?*const u8) c_int;
pub extern fn PyObject_SelfIter(?*PyObject) ?*PyObject;
pub extern fn PyObject_GenericGetAttr(?*PyObject, ?*PyObject) ?*PyObject;
pub extern fn PyObject_GenericSetAttr(?*PyObject, ?*PyObject, ?*PyObject) c_int;
pub extern fn PyObject_GenericSetDict(?*PyObject, ?*PyObject, ?*anyopaque) c_int;
pub extern fn PyObject_Hash(?*PyObject) Py_hash_t;
pub extern fn PyObject_HashNotImplemented(?*PyObject) Py_hash_t;
pub extern fn PyObject_IsTrue(?*PyObject) c_int;
pub extern fn PyObject_Not(?*PyObject) c_int;
pub extern fn PyCallable_Check(?*PyObject) c_int;
pub extern fn PyObject_ClearWeakRefs(?*PyObject) void;
pub extern fn PyObject_Dir(?*PyObject) ?*PyObject;
pub extern fn Py_ReprEnter(?*PyObject) c_int;
pub extern fn Py_ReprLeave(?*PyObject) void;
pub extern fn _Py_Dealloc(?*PyObject) void;
pub extern fn Py_IncRef(?*PyObject) void;
pub extern fn Py_DecRef(?*PyObject) void;
pub extern fn _Py_IncRef(?*PyObject) void;
pub extern fn _Py_DecRef(?*PyObject) void;
pub inline fn Py_INCREF(arg_op: ?*PyObject) void {
    var op = arg_op;
    _ = &op;
    var cur_refcnt: u32 = op.*.unnamed_0.ob_refcnt_split[@as(c_uint, @intCast(@as(c_int, 0)))];
    _ = &cur_refcnt;
    var new_refcnt: u32 = cur_refcnt +% @as(u32, @bitCast(@as(c_int, 1)));
    _ = &new_refcnt;
    if (new_refcnt == @as(u32, @bitCast(@as(c_int, 0)))) {
        return;
    }
    op.*.unnamed_0.ob_refcnt_split[@as(c_uint, @intCast(@as(c_int, 0)))] = new_refcnt;
    _ = @as(c_int, 0);
}
pub inline fn Py_DECREF(arg_op: ?*PyObject) void {
    var op = arg_op;
    _ = &op;
    if (_Py_IsImmortal(op) != 0) {
        return;
    }
    _ = @as(c_int, 0);
    if ((blk: {
        const ref = &op.*.unnamed_0.ob_refcnt;
        ref.* -= 1;
        break :blk ref.*;
    }) == @as(Py_ssize_t, @bitCast(@as(c_long, @as(c_int, 0))))) {
        _Py_Dealloc(op);
    }
}
pub fn Py_XINCREF(arg_op: ?*PyObject) callconv(.c) void {
    var op = arg_op;
    _ = &op;
    if (op != @as(?*PyObject, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0))))))) {
        Py_INCREF(op);
    }
}
pub fn Py_XDECREF(arg_op: ?*PyObject) callconv(.c) void {
    var op = arg_op;
    _ = &op;
    if (op != @as(?*PyObject, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0))))))) {
        Py_DECREF(op);
    }
}
pub extern fn Py_NewRef(obj: ?*PyObject) ?*PyObject;
pub extern fn Py_XNewRef(obj: ?*PyObject) ?*PyObject;
pub fn _Py_NewRef(arg_obj: ?*PyObject) callconv(.c) ?*PyObject {
    var obj = arg_obj;
    _ = &obj;
    Py_INCREF(obj);
    return obj;
}
pub fn _Py_XNewRef(arg_obj: ?*PyObject) callconv(.c) ?*PyObject {
    var obj = arg_obj;
    _ = &obj;
    Py_XINCREF(obj);
    return obj;
}
pub extern fn Py_GetConstant(constant_id: c_uint) ?*PyObject;
pub extern fn Py_GetConstantBorrowed(constant_id: c_uint) ?*PyObject;
pub extern var _Py_NoneStruct: PyObject;
pub extern fn Py_IsNone(x: ?*PyObject) c_int;
pub extern var _Py_NotImplementedStruct: PyObject;
pub const PYGEN_RETURN: c_int = 0;
pub const PYGEN_ERROR: c_int = -1;
pub const PYGEN_NEXT: c_int = 1;
pub const PySendResult = c_int;
pub extern fn _Py_NewReference(op: ?*PyObject) void;
pub extern fn _Py_NewReferenceNoTotal(op: ?*PyObject) void;
pub extern fn _Py_ResurrectReference(op: ?*PyObject) void;
const struct_unnamed_13 = extern struct {
    v: u8 = std.mem.zeroes(u8),
};
pub const struct__Py_Identifier = extern struct {
    string: ?*const u8 = std.mem.zeroes(?*const u8),
    index: Py_ssize_t = std.mem.zeroes(Py_ssize_t),
    mutex: struct_unnamed_13 = std.mem.zeroes(struct_unnamed_13),
};
pub const _Py_Identifier = struct__Py_Identifier;
pub const PyNumberMethods = extern struct {
    nb_add: binaryfunc = std.mem.zeroes(binaryfunc),
    nb_subtract: binaryfunc = std.mem.zeroes(binaryfunc),
    nb_multiply: binaryfunc = std.mem.zeroes(binaryfunc),
    nb_remainder: binaryfunc = std.mem.zeroes(binaryfunc),
    nb_divmod: binaryfunc = std.mem.zeroes(binaryfunc),
    nb_power: ternaryfunc = std.mem.zeroes(ternaryfunc),
    nb_negative: unaryfunc = std.mem.zeroes(unaryfunc),
    nb_positive: unaryfunc = std.mem.zeroes(unaryfunc),
    nb_absolute: unaryfunc = std.mem.zeroes(unaryfunc),
    nb_bool: inquiry = std.mem.zeroes(inquiry),
    nb_invert: unaryfunc = std.mem.zeroes(unaryfunc),
    nb_lshift: binaryfunc = std.mem.zeroes(binaryfunc),
    nb_rshift: binaryfunc = std.mem.zeroes(binaryfunc),
    nb_and: binaryfunc = std.mem.zeroes(binaryfunc),
    nb_xor: binaryfunc = std.mem.zeroes(binaryfunc),
    nb_or: binaryfunc = std.mem.zeroes(binaryfunc),
    nb_int: unaryfunc = std.mem.zeroes(unaryfunc),
    nb_reserved: ?*anyopaque = std.mem.zeroes(?*anyopaque),
    nb_float: unaryfunc = std.mem.zeroes(unaryfunc),
    nb_inplace_add: binaryfunc = std.mem.zeroes(binaryfunc),
    nb_inplace_subtract: binaryfunc = std.mem.zeroes(binaryfunc),
    nb_inplace_multiply: binaryfunc = std.mem.zeroes(binaryfunc),
    nb_inplace_remainder: binaryfunc = std.mem.zeroes(binaryfunc),
    nb_inplace_power: ternaryfunc = std.mem.zeroes(ternaryfunc),
    nb_inplace_lshift: binaryfunc = std.mem.zeroes(binaryfunc),
    nb_inplace_rshift: binaryfunc = std.mem.zeroes(binaryfunc),
    nb_inplace_and: binaryfunc = std.mem.zeroes(binaryfunc),
    nb_inplace_xor: binaryfunc = std.mem.zeroes(binaryfunc),
    nb_inplace_or: binaryfunc = std.mem.zeroes(binaryfunc),
    nb_floor_divide: binaryfunc = std.mem.zeroes(binaryfunc),
    nb_true_divide: binaryfunc = std.mem.zeroes(binaryfunc),
    nb_inplace_floor_divide: binaryfunc = std.mem.zeroes(binaryfunc),
    nb_inplace_true_divide: binaryfunc = std.mem.zeroes(binaryfunc),
    nb_index: unaryfunc = std.mem.zeroes(unaryfunc),
    nb_matrix_multiply: binaryfunc = std.mem.zeroes(binaryfunc),
    nb_inplace_matrix_multiply: binaryfunc = std.mem.zeroes(binaryfunc),
};
pub const PySequenceMethods = extern struct {
    sq_length: lenfunc = std.mem.zeroes(lenfunc),
    sq_concat: binaryfunc = std.mem.zeroes(binaryfunc),
    sq_repeat: ssizeargfunc = std.mem.zeroes(ssizeargfunc),
    sq_item: ssizeargfunc = std.mem.zeroes(ssizeargfunc),
    was_sq_slice: ?*anyopaque = std.mem.zeroes(?*anyopaque),
    sq_ass_item: ssizeobjargproc = std.mem.zeroes(ssizeobjargproc),
    was_sq_ass_slice: ?*anyopaque = std.mem.zeroes(?*anyopaque),
    sq_contains: objobjproc = std.mem.zeroes(objobjproc),
    sq_inplace_concat: binaryfunc = std.mem.zeroes(binaryfunc),
    sq_inplace_repeat: ssizeargfunc = std.mem.zeroes(ssizeargfunc),
};
pub const PyMappingMethods = extern struct {
    mp_length: lenfunc = std.mem.zeroes(lenfunc),
    mp_subscript: binaryfunc = std.mem.zeroes(binaryfunc),
    mp_ass_subscript: objobjargproc = std.mem.zeroes(objobjargproc),
};
pub const sendfunc = ?*const fn (?*PyObject, ?*PyObject, ?*?*PyObject) callconv(.c) PySendResult;
pub const PyAsyncMethods = extern struct {
    am_await: unaryfunc = std.mem.zeroes(unaryfunc),
    am_aiter: unaryfunc = std.mem.zeroes(unaryfunc),
    am_anext: unaryfunc = std.mem.zeroes(unaryfunc),
    am_send: sendfunc = std.mem.zeroes(sendfunc),
};
pub const PyBufferProcs = extern struct {
    bf_getbuffer: getbufferproc = std.mem.zeroes(getbufferproc),
    bf_releasebuffer: releasebufferproc = std.mem.zeroes(releasebufferproc),
};
pub const printfunc = Py_ssize_t;
pub const struct__specialization_cache = extern struct {
    getitem: ?*PyObject = std.mem.zeroes(?*PyObject),
    getitem_version: u32 = std.mem.zeroes(u32),
    init: ?*PyObject = std.mem.zeroes(?*PyObject),
};
pub const struct__dictkeysobject_14 = opaque {};
pub const struct__heaptypeobject = extern struct {
    ht_type: PyTypeObject = std.mem.zeroes(PyTypeObject),
    as_async: PyAsyncMethods = std.mem.zeroes(PyAsyncMethods),
    as_number: PyNumberMethods = std.mem.zeroes(PyNumberMethods),
    as_mapping: PyMappingMethods = std.mem.zeroes(PyMappingMethods),
    as_sequence: PySequenceMethods = std.mem.zeroes(PySequenceMethods),
    as_buffer: PyBufferProcs = std.mem.zeroes(PyBufferProcs),
    ht_name: ?*PyObject = std.mem.zeroes(?*PyObject),
    ht_slots: ?*PyObject = std.mem.zeroes(?*PyObject),
    ht_qualname: ?*PyObject = std.mem.zeroes(?*PyObject),
    ht_cached_keys: ?*struct__dictkeysobject_14 = std.mem.zeroes(?*struct__dictkeysobject_14),
    ht_module: ?*PyObject = std.mem.zeroes(?*PyObject),
    _ht_tpname: ?*u8 = std.mem.zeroes(?*u8),
    _spec_cache: struct__specialization_cache = std.mem.zeroes(struct__specialization_cache),
};
pub const PyHeapTypeObject = struct__heaptypeobject;
pub extern fn _PyType_Name(?*PyTypeObject) ?*const u8;
pub extern fn _PyType_Lookup(?*PyTypeObject, ?*PyObject) ?*PyObject;
pub extern fn _PyType_LookupRef(?*PyTypeObject, ?*PyObject) ?*PyObject;
pub extern fn PyType_GetDict(?*PyTypeObject) ?*PyObject;
pub extern fn _Py_BreakPoint() void;
pub extern fn _PyObject_Dump(?*PyObject) void;
pub extern fn _PyObject_GetAttrId(?*PyObject, ?*_Py_Identifier) ?*PyObject;
pub extern fn _PyObject_GetDictPtr(?*PyObject) ?*?*PyObject;
pub extern fn PyObject_CallFinalizer(?*PyObject) void;
pub extern fn PyObject_CallFinalizerFromDealloc(?*PyObject) c_int;
pub extern fn PyUnstable_Object_ClearWeakRefsNoCallbacks(?*PyObject) void;
pub extern fn _PyObject_GenericGetAttrWithDict(?*PyObject, ?*PyObject, ?*PyObject, c_int) ?*PyObject;
pub extern fn _PyObject_GenericSetAttrWithDict(?*PyObject, ?*PyObject, ?*PyObject, ?*PyObject) c_int;
pub extern fn _PyObject_FunctionStr(?*PyObject) ?*PyObject;
pub extern fn _PyObject_AssertFailed(obj: ?*PyObject, expr: ?*const u8, msg: ?*const u8, file: ?*const u8, line: c_int, function: ?*const u8) noreturn;
pub extern fn _PyTrash_begin(tstate: ?*PyThreadState, op: ?*PyObject) c_int;
pub extern fn _PyTrash_end(tstate: ?*PyThreadState) void;
pub extern fn _PyTrash_thread_deposit_object(tstate: ?*PyThreadState, op: ?*PyObject) void;
pub extern fn _PyTrash_thread_destroy_chain(tstate: ?*PyThreadState) void;
pub extern fn PyObject_GetItemData(obj: ?*PyObject) ?*anyopaque;
pub extern fn PyObject_VisitManagedDict(obj: ?*PyObject, visit: visitproc, arg: ?*anyopaque) c_int;
pub extern fn _PyObject_SetManagedDict(obj: ?*PyObject, new_dict: ?*PyObject) c_int;
pub extern fn PyObject_ClearManagedDict(obj: ?*PyObject) void;
pub const PyType_WatchCallback = ?*const fn (?*PyTypeObject) callconv(.c) c_int;
pub extern fn PyType_AddWatcher(callback: PyType_WatchCallback) c_int;
pub extern fn PyType_ClearWatcher(watcher_id: c_int) c_int;
pub extern fn PyType_Watch(watcher_id: c_int, @"type": ?*PyObject) c_int;
pub extern fn PyType_Unwatch(watcher_id: c_int, @"type": ?*PyObject) c_int;
pub extern fn PyUnstable_Type_AssignVersionTag(@"type": ?*PyTypeObject) c_int;
pub const PyRefTracer_CREATE: c_int = 0;
pub const PyRefTracer_DESTROY: c_int = 1;
pub const PyRefTracerEvent = c_uint;
pub const PyRefTracer = ?*const fn (?*PyObject, PyRefTracerEvent, ?*anyopaque) callconv(.c) c_int;
pub extern fn PyRefTracer_SetTracer(tracer: PyRefTracer, data: ?*anyopaque) c_int;
pub extern fn PyRefTracer_GetTracer(?*?*anyopaque) PyRefTracer;
pub fn PyType_HasFeature(arg_type: ?*PyTypeObject, arg_feature: c_ulong) callconv(.c) c_int {
    var @"type" = arg_type;
    _ = &@"type";
    var feature = arg_feature;
    _ = &feature;
    var flags: c_ulong = undefined;
    _ = &flags;
    flags = @"type".?.tp_flags;
    return @intFromBool((flags & feature) != @as(c_ulong, @bitCast(@as(c_long, @as(c_int, 0)))));
}
pub fn PyType_Check(arg_op: ?*PyObject) callconv(.c) c_int {
    var op = arg_op;
    _ = &op;
    return PyType_HasFeature(Py_TYPE(op), @as(c_ulong, 1) << @intCast(31));
}
pub fn PyType_CheckExact(arg_op: ?*PyObject) callconv(.c) c_int {
    var op = arg_op;
    _ = &op;
    return Py_IS_TYPE(op, &PyType_Type);
}
pub extern fn PyType_GetModuleByDef(?*PyTypeObject, ?*PyModuleDef) ?*PyObject;
pub extern fn PyObject_Malloc(size: usize) ?*anyopaque;
pub extern fn PyObject_Calloc(nelem: usize, elsize: usize) ?*anyopaque;
pub extern fn PyObject_Realloc(ptr: ?*anyopaque, new_size: usize) ?*anyopaque;
pub extern fn PyObject_Free(ptr: ?*anyopaque) void;
pub extern fn PyObject_Init(?*PyObject, ?*PyTypeObject) ?*PyObject;
pub extern fn PyObject_InitVar(?*PyVarObject, ?*PyTypeObject, Py_ssize_t) ?*PyVarObject;
pub extern fn _PyObject_New(?*PyTypeObject) ?*PyObject;
pub extern fn _PyObject_NewVar(?*PyTypeObject, Py_ssize_t) ?*PyVarObject;
pub extern fn PyGC_Collect() Py_ssize_t;
pub extern fn PyGC_Enable() c_int;
pub extern fn PyGC_Disable() c_int;
pub extern fn PyGC_IsEnabled() c_int;
pub extern fn _PyObject_GC_Resize(?*PyVarObject, Py_ssize_t) ?*PyVarObject;
pub extern fn _PyObject_GC_New(?*PyTypeObject) ?*PyObject;
pub extern fn _PyObject_GC_NewVar(?*PyTypeObject, Py_ssize_t) ?*PyVarObject;
pub extern fn PyObject_GC_Track(?*anyopaque) void;
pub extern fn PyObject_GC_UnTrack(?*anyopaque) void;
pub extern fn PyObject_GC_Del(?*anyopaque) void;
pub extern fn PyObject_GC_IsTracked(?*PyObject) c_int;
pub extern fn PyObject_GC_IsFinalized(?*PyObject) c_int;
pub fn _PyObject_SIZE(arg_type: ?*PyTypeObject) callconv(.c) usize {
    var @"type" = arg_type;
    _ = &@"type";
    return @as(usize, @bitCast(@"type".*.tp_basicsize));
}
pub fn _PyObject_VAR_SIZE(arg_type: ?*PyTypeObject, arg_nitems: Py_ssize_t) callconv(.c) usize {
    var @"type" = arg_type;
    _ = &@"type";
    var nitems = arg_nitems;
    _ = &nitems;
    var size: usize = @as(usize, @bitCast(@"type".*.tp_basicsize));
    _ = &size;
    size +%= @as(usize, @bitCast(nitems)) *% @as(usize, @bitCast(@"type".*.tp_itemsize));
    return (size +% @as(usize, @bitCast(@as(c_long, @as(c_int, 8) - @as(c_int, 1))))) & ~@as(usize, @bitCast(@as(c_long, @as(c_int, 8) - @as(c_int, 1))));
}
pub const PyObjectArenaAllocator = extern struct {
    ctx: ?*anyopaque = std.mem.zeroes(?*anyopaque),
    alloc: ?*const fn (?*anyopaque, usize) callconv(.c) ?*anyopaque = std.mem.zeroes(?*const fn (?*anyopaque, usize) callconv(.c) ?*anyopaque),
    free: ?*const fn (?*anyopaque, ?*anyopaque, usize) callconv(.c) void = std.mem.zeroes(?*const fn (?*anyopaque, ?*anyopaque, usize) callconv(.c) void),
};
pub extern fn PyObject_GetArenaAllocator(allocator: ?*PyObjectArenaAllocator) void;
pub extern fn PyObject_SetArenaAllocator(allocator: ?*PyObjectArenaAllocator) void;
pub extern fn PyObject_IS_GC(obj: ?*PyObject) c_int;
pub extern fn PyType_SUPPORTS_WEAKREFS(@"type": ?*PyTypeObject) c_int;
pub extern fn PyObject_GET_WEAKREFS_LISTPTR(op: ?*PyObject) ?*?*PyObject;
pub extern fn PyUnstable_Object_GC_NewWithExtraData(?*PyTypeObject, usize) ?*PyObject;
pub const gcvisitobjects_t = ?*const fn (?*PyObject, ?*anyopaque) callconv(.c) c_int;
pub extern fn PyUnstable_GC_VisitObjects(callback: gcvisitobjects_t, arg: ?*anyopaque) void;
pub extern fn _Py_HashDouble(?*PyObject, f64) Py_hash_t;
pub const PyHash_FuncDef = extern struct {
    hash: ?*const fn (?*const anyopaque, Py_ssize_t) callconv(.c) Py_hash_t = std.mem.zeroes(?*const fn (?*const anyopaque, Py_ssize_t) callconv(.c) Py_hash_t),
    name: ?*const u8 = std.mem.zeroes(?*const u8),
    hash_bits: c_int = std.mem.zeroes(c_int),
    seed_bits: c_int = std.mem.zeroes(c_int),
};
pub extern fn PyHash_GetFuncDef() ?*PyHash_FuncDef;
pub extern fn Py_HashPointer(ptr: ?*const anyopaque) Py_hash_t;
pub extern fn PyObject_GenericHash(?*PyObject) Py_hash_t;
pub extern var Py_DebugFlag: c_int;
pub extern var Py_VerboseFlag: c_int;
pub extern var Py_QuietFlag: c_int;
pub extern var Py_InteractiveFlag: c_int;
pub extern var Py_InspectFlag: c_int;
pub extern var Py_OptimizeFlag: c_int;
pub extern var Py_NoSiteFlag: c_int;
pub extern var Py_BytesWarningFlag: c_int;
pub extern var Py_FrozenFlag: c_int;
pub extern var Py_IgnoreEnvironmentFlag: c_int;
pub extern var Py_DontWriteBytecodeFlag: c_int;
pub extern var Py_NoUserSiteDirectory: c_int;
pub extern var Py_UnbufferedStdioFlag: c_int;
pub extern var Py_HashRandomizationFlag: c_int;
pub extern var Py_IsolatedFlag: c_int;
pub extern fn Py_GETENV(name: ?*const u8) ?*u8;
pub extern var PyByteArray_Type: PyTypeObject;
pub extern var PyByteArrayIter_Type: PyTypeObject;
pub extern fn PyByteArray_FromObject(?*PyObject) ?*PyObject;
pub extern fn PyByteArray_Concat(?*PyObject, ?*PyObject) ?*PyObject;
pub extern fn PyByteArray_FromStringAndSize([*]const u8, Py_ssize_t) ?*PyObject;
pub extern fn PyByteArray_Size(?*PyObject) Py_ssize_t;
pub extern fn PyByteArray_AsString(?*PyObject) ?*u8;
pub extern fn PyByteArray_Resize(?*PyObject, Py_ssize_t) c_int;
pub const PyByteArrayObject = extern struct {
    ob_base: PyVarObject = std.mem.zeroes(PyVarObject),
    ob_alloc: Py_ssize_t = std.mem.zeroes(Py_ssize_t),
    ob_bytes: ?*u8 = std.mem.zeroes(?*u8),
    ob_start: ?*u8 = std.mem.zeroes(?*u8),
    ob_exports: Py_ssize_t = std.mem.zeroes(Py_ssize_t),
};
pub const _PyByteArray_empty_string: ?*u8 = @extern(?*u8, .{
    .name = "_PyByteArray_empty_string",
});
pub extern var PyBytes_Type: PyTypeObject;
pub extern var PyBytesIter_Type: PyTypeObject;
pub extern fn PyBytes_FromStringAndSize([*]const u8, Py_ssize_t) ?*PyObject;
pub extern fn PyBytes_FromString([*]const u8) ?*PyObject;
pub extern fn PyBytes_FromObject(?*PyObject) ?*PyObject;
pub extern fn PyBytes_FromFormat(?*const u8, ...) ?*PyObject;
pub extern fn PyBytes_Size(?*PyObject) Py_ssize_t;
pub extern fn PyBytes_AsString(?*PyObject) ?*u8;
pub extern fn PyBytes_Repr(?*PyObject, c_int) ?*PyObject;
pub extern fn PyBytes_Concat(?*?*PyObject, ?*PyObject) void;
pub extern fn PyBytes_ConcatAndDel(?*?*PyObject, ?*PyObject) void;
pub extern fn PyBytes_DecodeEscape(?*const u8, Py_ssize_t, ?*const u8, Py_ssize_t, ?*const u8) ?*PyObject;
pub extern fn PyBytes_AsStringAndSize(obj: ?*PyObject, s: ?*?*u8, len: ?*Py_ssize_t) c_int;
pub const PyBytesObject = extern struct {
    ob_base: PyVarObject = std.mem.zeroes(PyVarObject),
    ob_shash: Py_hash_t = std.mem.zeroes(Py_hash_t),
    ob_sval: [1]u8 = std.mem.zeroes([1]u8),
};
pub extern fn _PyBytes_Resize(?*?*PyObject, Py_ssize_t) c_int;
pub extern fn _PyBytes_Join(sep: ?*PyObject, x: ?*PyObject) ?*PyObject;
pub const Py_UCS4 = u32;
pub const Py_UCS2 = u16;
pub const Py_UCS1 = u8;
pub extern var PyUnicode_Type: PyTypeObject;
pub extern var PyUnicodeIter_Type: PyTypeObject;
pub extern fn PyUnicode_FromStringAndSize(u: [*]const u8, size: Py_ssize_t) ?*PyObject;
pub extern fn PyUnicode_FromString(u: [*]const u8) ?*PyObject;
pub extern fn PyUnicode_Substring(str: ?*PyObject, start: Py_ssize_t, end: Py_ssize_t) ?*PyObject;
pub extern fn PyUnicode_AsUCS4(unicode: ?*PyObject, buffer: ?*Py_UCS4, buflen: Py_ssize_t, copy_null: c_int) ?*Py_UCS4;
pub extern fn PyUnicode_AsUCS4Copy(unicode: ?*PyObject) ?*Py_UCS4;
pub extern fn PyUnicode_GetLength(unicode: ?*PyObject) Py_ssize_t;
pub extern fn PyUnicode_ReadChar(unicode: ?*PyObject, index: Py_ssize_t) Py_UCS4;
pub extern fn PyUnicode_WriteChar(unicode: ?*PyObject, index: Py_ssize_t, character: Py_UCS4) c_int;
pub extern fn PyUnicode_Resize(unicode: ?*?*PyObject, length: Py_ssize_t) c_int;
pub extern fn PyUnicode_FromEncodedObject(obj: ?*PyObject, encoding: ?*const u8, errors: ?*const u8) ?*PyObject;
pub extern fn PyUnicode_FromObject(obj: ?*PyObject) ?*PyObject;
pub extern fn PyUnicode_FromFormat(format: ?*const u8, ...) ?*PyObject;
pub extern fn PyUnicode_InternInPlace(?*?*PyObject) void;
pub extern fn PyUnicode_InternFromString(u: ?*const u8) ?*PyObject;
pub extern fn PyUnicode_FromOrdinal(ordinal: c_int) ?*PyObject;
pub extern fn PyUnicode_GetDefaultEncoding() ?*const u8;
pub extern fn PyUnicode_Decode(s: ?*const u8, size: Py_ssize_t, encoding: ?*const u8, errors: ?*const u8) ?*PyObject;
pub extern fn PyUnicode_AsDecodedObject(unicode: ?*PyObject, encoding: ?*const u8, errors: ?*const u8) ?*PyObject;
pub extern fn PyUnicode_AsDecodedUnicode(unicode: ?*PyObject, encoding: ?*const u8, errors: ?*const u8) ?*PyObject;
pub extern fn PyUnicode_AsEncodedObject(unicode: ?*PyObject, encoding: ?*const u8, errors: ?*const u8) ?*PyObject;
pub extern fn PyUnicode_AsEncodedString(unicode: ?*PyObject, encoding: ?*const u8, errors: ?*const u8) ?*PyObject;
pub extern fn PyUnicode_AsEncodedUnicode(unicode: ?*PyObject, encoding: ?*const u8, errors: ?*const u8) ?*PyObject;
pub extern fn PyUnicode_BuildEncodingMap(string: ?*PyObject) ?*PyObject;
pub extern fn PyUnicode_DecodeUTF7(string: ?*const u8, length: Py_ssize_t, errors: ?*const u8) ?*PyObject;
pub extern fn PyUnicode_DecodeUTF7Stateful(string: ?*const u8, length: Py_ssize_t, errors: ?*const u8, consumed: ?*Py_ssize_t) ?*PyObject;
pub extern fn PyUnicode_DecodeUTF8(string: ?*const u8, length: Py_ssize_t, errors: ?*const u8) ?*PyObject;
pub extern fn PyUnicode_DecodeUTF8Stateful(string: ?*const u8, length: Py_ssize_t, errors: ?*const u8, consumed: ?*Py_ssize_t) ?*PyObject;
pub extern fn PyUnicode_AsUTF8String(unicode: ?*PyObject) ?*PyObject;
pub extern fn PyUnicode_AsUTF8AndSize(unicode: ?*PyObject, size: ?*Py_ssize_t) ?*const u8;
pub extern fn PyUnicode_DecodeUTF32(string: ?*const u8, length: Py_ssize_t, errors: ?*const u8, byteorder: ?*c_int) ?*PyObject;
pub extern fn PyUnicode_DecodeUTF32Stateful(string: ?*const u8, length: Py_ssize_t, errors: ?*const u8, byteorder: ?*c_int, consumed: ?*Py_ssize_t) ?*PyObject;
pub extern fn PyUnicode_AsUTF32String(unicode: ?*PyObject) ?*PyObject;
pub extern fn PyUnicode_DecodeUTF16(string: ?*const u8, length: Py_ssize_t, errors: ?*const u8, byteorder: ?*c_int) ?*PyObject;
pub extern fn PyUnicode_DecodeUTF16Stateful(string: ?*const u8, length: Py_ssize_t, errors: ?*const u8, byteorder: ?*c_int, consumed: ?*Py_ssize_t) ?*PyObject;
pub extern fn PyUnicode_AsUTF16String(unicode: ?*PyObject) ?*PyObject;
pub extern fn PyUnicode_DecodeUnicodeEscape(string: ?*const u8, length: Py_ssize_t, errors: ?*const u8) ?*PyObject;
pub extern fn PyUnicode_AsUnicodeEscapeString(unicode: ?*PyObject) ?*PyObject;
pub extern fn PyUnicode_DecodeRawUnicodeEscape(string: ?*const u8, length: Py_ssize_t, errors: ?*const u8) ?*PyObject;
pub extern fn PyUnicode_AsRawUnicodeEscapeString(unicode: ?*PyObject) ?*PyObject;
pub extern fn PyUnicode_DecodeLatin1(string: ?*const u8, length: Py_ssize_t, errors: ?*const u8) ?*PyObject;
pub extern fn PyUnicode_AsLatin1String(unicode: ?*PyObject) ?*PyObject;
pub extern fn PyUnicode_DecodeASCII(string: ?*const u8, length: Py_ssize_t, errors: ?*const u8) ?*PyObject;
pub extern fn PyUnicode_AsASCIIString(unicode: ?*PyObject) ?*PyObject;
pub extern fn PyUnicode_DecodeCharmap(string: ?*const u8, length: Py_ssize_t, mapping: ?*PyObject, errors: ?*const u8) ?*PyObject;
pub extern fn PyUnicode_AsCharmapString(unicode: ?*PyObject, mapping: ?*PyObject) ?*PyObject;
pub extern fn PyUnicode_DecodeLocaleAndSize(str: ?*const u8, len: Py_ssize_t, errors: ?*const u8) ?*PyObject;
pub extern fn PyUnicode_DecodeLocale(str: ?*const u8, errors: ?*const u8) ?*PyObject;
pub extern fn PyUnicode_EncodeLocale(unicode: ?*PyObject, errors: ?*const u8) ?*PyObject;
pub extern fn PyUnicode_FSConverter(?*PyObject, ?*anyopaque) c_int;
pub extern fn PyUnicode_FSDecoder(?*PyObject, ?*anyopaque) c_int;
pub extern fn PyUnicode_DecodeFSDefault(s: ?*const u8) ?*PyObject;
pub extern fn PyUnicode_DecodeFSDefaultAndSize(s: ?*const u8, size: Py_ssize_t) ?*PyObject;
pub extern fn PyUnicode_EncodeFSDefault(unicode: ?*PyObject) ?*PyObject;
pub extern fn PyUnicode_Concat(left: ?*PyObject, right: ?*PyObject) ?*PyObject;
pub extern fn PyUnicode_Append(pleft: ?*?*PyObject, right: ?*PyObject) void;
pub extern fn PyUnicode_AppendAndDel(pleft: ?*?*PyObject, right: ?*PyObject) void;
pub extern fn PyUnicode_Split(s: ?*PyObject, sep: ?*PyObject, maxsplit: Py_ssize_t) ?*PyObject;
pub extern fn PyUnicode_Splitlines(s: ?*PyObject, keepends: c_int) ?*PyObject;
pub extern fn PyUnicode_Partition(s: ?*PyObject, sep: ?*PyObject) ?*PyObject;
pub extern fn PyUnicode_RPartition(s: ?*PyObject, sep: ?*PyObject) ?*PyObject;
pub extern fn PyUnicode_RSplit(s: ?*PyObject, sep: ?*PyObject, maxsplit: Py_ssize_t) ?*PyObject;
pub extern fn PyUnicode_Translate(str: ?*PyObject, table: ?*PyObject, errors: ?*const u8) ?*PyObject;
pub extern fn PyUnicode_Join(separator: ?*PyObject, seq: ?*PyObject) ?*PyObject;
pub extern fn PyUnicode_Tailmatch(str: ?*PyObject, substr: ?*PyObject, start: Py_ssize_t, end: Py_ssize_t, direction: c_int) Py_ssize_t;
pub extern fn PyUnicode_Find(str: ?*PyObject, substr: ?*PyObject, start: Py_ssize_t, end: Py_ssize_t, direction: c_int) Py_ssize_t;
pub extern fn PyUnicode_FindChar(str: ?*PyObject, ch: Py_UCS4, start: Py_ssize_t, end: Py_ssize_t, direction: c_int) Py_ssize_t;
pub extern fn PyUnicode_Count(str: ?*PyObject, substr: ?*PyObject, start: Py_ssize_t, end: Py_ssize_t) Py_ssize_t;
pub extern fn PyUnicode_Replace(str: ?*PyObject, substr: ?*PyObject, replstr: ?*PyObject, maxcount: Py_ssize_t) ?*PyObject;
pub extern fn PyUnicode_Compare(left: ?*PyObject, right: ?*PyObject) c_int;
pub extern fn PyUnicode_CompareWithASCIIString(left: ?*PyObject, right: ?*const u8) c_int;
pub extern fn PyUnicode_EqualToUTF8(?*PyObject, ?*const u8) c_int;
pub extern fn PyUnicode_EqualToUTF8AndSize(?*PyObject, ?*const u8, Py_ssize_t) c_int;
pub extern fn PyUnicode_RichCompare(left: ?*PyObject, right: ?*PyObject, op: c_int) ?*PyObject;
pub extern fn PyUnicode_Format(format: ?*PyObject, args: ?*PyObject) ?*PyObject;
pub extern fn PyUnicode_Contains(container: ?*PyObject, element: ?*PyObject) c_int;
pub extern fn PyUnicode_IsIdentifier(s: ?*PyObject) c_int;
pub fn Py_UNICODE_IS_SURROGATE(arg_ch: Py_UCS4) callconv(.c) c_int {
    var ch = arg_ch;
    _ = &ch;
    return @intFromBool((@as(Py_UCS4, @bitCast(@as(c_int, 55296))) <= ch) and (ch <= @as(Py_UCS4, @bitCast(@as(c_int, 57343)))));
}
pub fn Py_UNICODE_IS_HIGH_SURROGATE(arg_ch: Py_UCS4) callconv(.c) c_int {
    var ch = arg_ch;
    _ = &ch;
    return @intFromBool((@as(Py_UCS4, @bitCast(@as(c_int, 55296))) <= ch) and (ch <= @as(Py_UCS4, @bitCast(@as(c_int, 56319)))));
}
pub fn Py_UNICODE_IS_LOW_SURROGATE(arg_ch: Py_UCS4) callconv(.c) c_int {
    var ch = arg_ch;
    _ = &ch;
    return @intFromBool((@as(Py_UCS4, @bitCast(@as(c_int, 56320))) <= ch) and (ch <= @as(Py_UCS4, @bitCast(@as(c_int, 57343)))));
}
// /usr/include/python3.13/cpython/unicodeobject.h:112:22: warning: struct demoted to opaque type - has bitfield
const struct_unnamed_15 = opaque {};
pub const PyASCIIObject = extern struct {
    ob_base: PyObject = std.mem.zeroes(PyObject),
    length: Py_ssize_t = std.mem.zeroes(Py_ssize_t),
    hash: Py_hash_t = std.mem.zeroes(Py_hash_t),
    state: struct_unnamed_15 = std.mem.zeroes(struct_unnamed_15),
};
pub const PyCompactUnicodeObject = extern struct {
    _base: PyASCIIObject = std.mem.zeroes(PyASCIIObject),
    utf8_length: Py_ssize_t = std.mem.zeroes(Py_ssize_t),
    utf8: ?*u8 = std.mem.zeroes(?*u8),
};
const union_unnamed_16 = extern union {
    any: ?*anyopaque,
    latin1: ?*Py_UCS1,
    ucs2: ?*Py_UCS2,
    ucs4: ?*Py_UCS4,
};
pub const PyUnicodeObject = extern struct {
    _base: PyCompactUnicodeObject = std.mem.zeroes(PyCompactUnicodeObject),
    data: union_unnamed_16 = std.mem.zeroes(union_unnamed_16),
};
pub fn PyUnicode_IS_READY(arg__unused_op: ?*PyObject) callconv(.c) c_uint {
    var _unused_op = arg__unused_op;
    _ = &_unused_op;
    return 1;
}
pub const PyUnicode_1BYTE_KIND: c_int = 1;
pub const PyUnicode_2BYTE_KIND: c_int = 2;
pub const PyUnicode_4BYTE_KIND: c_int = 4;
pub const enum_PyUnicode_Kind = c_uint;
pub extern fn PyUnicode_New(size: Py_ssize_t, maxchar: Py_UCS4) ?*PyObject;
pub fn PyUnicode_READY(arg__unused_op: ?*PyObject) callconv(.c) c_int {
    var _unused_op = arg__unused_op;
    _ = &_unused_op;
    return 0;
}
pub extern fn PyUnicode_CopyCharacters(to: ?*PyObject, to_start: Py_ssize_t, from: ?*PyObject, from_start: Py_ssize_t, how_many: Py_ssize_t) Py_ssize_t;
pub extern fn PyUnicode_Fill(unicode: ?*PyObject, start: Py_ssize_t, length: Py_ssize_t, fill_char: Py_UCS4) Py_ssize_t;
pub extern fn PyUnicode_FromKindAndData(kind: c_int, buffer: ?*const anyopaque, size: Py_ssize_t) ?*PyObject;
pub const _PyUnicodeWriter = extern struct {
    buffer: ?*PyObject = std.mem.zeroes(?*PyObject),
    data: ?*anyopaque = std.mem.zeroes(?*anyopaque),
    kind: c_int = std.mem.zeroes(c_int),
    maxchar: Py_UCS4 = std.mem.zeroes(Py_UCS4),
    size: Py_ssize_t = std.mem.zeroes(Py_ssize_t),
    pos: Py_ssize_t = std.mem.zeroes(Py_ssize_t),
    min_length: Py_ssize_t = std.mem.zeroes(Py_ssize_t),
    min_char: Py_UCS4 = std.mem.zeroes(Py_UCS4),
    overallocate: u8 = std.mem.zeroes(u8),
    readonly: u8 = std.mem.zeroes(u8),
};
pub extern fn _PyUnicodeWriter_Init(writer: ?*_PyUnicodeWriter) void;
pub extern fn _PyUnicodeWriter_PrepareInternal(writer: ?*_PyUnicodeWriter, length: Py_ssize_t, maxchar: Py_UCS4) c_int;
pub extern fn _PyUnicodeWriter_PrepareKindInternal(writer: ?*_PyUnicodeWriter, kind: c_int) c_int;
pub extern fn _PyUnicodeWriter_WriteChar(writer: ?*_PyUnicodeWriter, ch: Py_UCS4) c_int;
pub extern fn _PyUnicodeWriter_WriteStr(writer: ?*_PyUnicodeWriter, str: ?*PyObject) c_int;
pub extern fn _PyUnicodeWriter_WriteSubstring(writer: ?*_PyUnicodeWriter, str: ?*PyObject, start: Py_ssize_t, end: Py_ssize_t) c_int;
pub extern fn _PyUnicodeWriter_WriteASCIIString(writer: ?*_PyUnicodeWriter, str: ?*const u8, len: Py_ssize_t) c_int;
pub extern fn _PyUnicodeWriter_WriteLatin1String(writer: ?*_PyUnicodeWriter, str: ?*const u8, len: Py_ssize_t) c_int;
pub extern fn _PyUnicodeWriter_Finish(writer: ?*_PyUnicodeWriter) ?*PyObject;
pub extern fn _PyUnicodeWriter_Dealloc(writer: ?*_PyUnicodeWriter) void;
pub extern fn PyUnicode_AsUTF8(unicode: ?*PyObject) ?*const u8;
pub extern fn _PyUnicode_IsLowercase(ch: Py_UCS4) c_int;
pub extern fn _PyUnicode_IsUppercase(ch: Py_UCS4) c_int;
pub extern fn _PyUnicode_IsTitlecase(ch: Py_UCS4) c_int;
pub extern fn _PyUnicode_IsWhitespace(ch: Py_UCS4) c_int;
pub extern fn _PyUnicode_IsLinebreak(ch: Py_UCS4) c_int;
pub extern fn _PyUnicode_ToLowercase(ch: Py_UCS4) Py_UCS4;
pub extern fn _PyUnicode_ToUppercase(ch: Py_UCS4) Py_UCS4;
pub extern fn _PyUnicode_ToTitlecase(ch: Py_UCS4) Py_UCS4;
pub extern fn _PyUnicode_ToDecimalDigit(ch: Py_UCS4) c_int;
pub extern fn _PyUnicode_ToDigit(ch: Py_UCS4) c_int;
pub extern fn _PyUnicode_ToNumeric(ch: Py_UCS4) f64;
pub extern fn _PyUnicode_IsDecimalDigit(ch: Py_UCS4) c_int;
pub extern fn _PyUnicode_IsDigit(ch: Py_UCS4) c_int;
pub extern fn _PyUnicode_IsNumeric(ch: Py_UCS4) c_int;
pub extern fn _PyUnicode_IsPrintable(ch: Py_UCS4) c_int;
pub extern fn _PyUnicode_IsAlpha(ch: Py_UCS4) c_int;
pub const _Py_ascii_whitespace: ?*const u8 = @extern(?*const u8, .{
    .name = "_Py_ascii_whitespace",
});
pub fn Py_UNICODE_ISSPACE(arg_ch: Py_UCS4) callconv(.c) c_int {
    var ch = arg_ch;
    _ = &ch;
    if (ch < @as(Py_UCS4, @bitCast(@as(c_int, 128)))) {
        return @as(c_int, @bitCast(@as(c_uint, _Py_ascii_whitespace[ch])));
    }
    return _PyUnicode_IsWhitespace(ch);
}
pub fn Py_UNICODE_ISALNUM(arg_ch: Py_UCS4) callconv(.c) c_int {
    var ch = arg_ch;
    _ = &ch;
    return @intFromBool((((_PyUnicode_IsAlpha(ch) != 0) or (_PyUnicode_IsDecimalDigit(ch) != 0)) or (_PyUnicode_IsDigit(ch) != 0)) or (_PyUnicode_IsNumeric(ch) != 0));
}
pub extern fn _PyUnicode_FromId(?*_Py_Identifier) ?*PyObject;
pub extern fn PyErr_SetNone(?*PyObject) void;
pub extern fn PyErr_SetObject(?*PyObject, ?*PyObject) void;
pub extern fn PyErr_SetString(exception: *PyObject, string: [*]const u8) void;
pub extern fn PyErr_Occurred() ?*PyObject;
pub extern fn PyErr_Clear() void;
pub extern fn PyErr_Fetch(?*?*PyObject, ?*?*PyObject, ?*?*PyObject) void;
pub extern fn PyErr_Restore(?*PyObject, ?*PyObject, ?*PyObject) void;
pub extern fn PyErr_GetRaisedException() ?*PyObject;
pub extern fn PyErr_SetRaisedException(?*PyObject) void;
pub extern fn PyErr_GetHandledException() ?*PyObject;
pub extern fn PyErr_SetHandledException(?*PyObject) void;
pub extern fn PyErr_GetExcInfo(?*?*PyObject, ?*?*PyObject, ?*?*PyObject) void;
pub extern fn PyErr_SetExcInfo(?*PyObject, ?*PyObject, ?*PyObject) void;
pub extern fn Py_FatalError(message: ?*const u8) noreturn;
pub extern fn PyErr_GivenExceptionMatches(?*PyObject, ?*PyObject) c_int;
pub extern fn PyErr_ExceptionMatches(?*PyObject) c_int;
pub extern fn PyErr_NormalizeException(?*?*PyObject, ?*?*PyObject, ?*?*PyObject) void;
pub extern fn PyException_SetTraceback(?*PyObject, ?*PyObject) c_int;
pub extern fn PyException_GetTraceback(?*PyObject) ?*PyObject;
pub extern fn PyException_GetCause(?*PyObject) ?*PyObject;
pub extern fn PyException_SetCause(?*PyObject, ?*PyObject) void;
pub extern fn PyException_GetContext(?*PyObject) ?*PyObject;
pub extern fn PyException_SetContext(?*PyObject, ?*PyObject) void;
pub extern fn PyException_GetArgs(?*PyObject) ?*PyObject;
pub extern fn PyException_SetArgs(?*PyObject, ?*PyObject) void;
pub extern fn PyExceptionClass_Name(?*PyObject) ?*const u8;
pub extern var PyExc_BaseException: ?*PyObject;
pub extern var PyExc_Exception: ?*PyObject;
pub extern var PyExc_BaseExceptionGroup: ?*PyObject;
pub extern var PyExc_StopAsyncIteration: ?*PyObject;
pub extern var PyExc_StopIteration: ?*PyObject;
pub extern var PyExc_GeneratorExit: ?*PyObject;
pub extern var PyExc_ArithmeticError: ?*PyObject;
pub extern var PyExc_LookupError: ?*PyObject;
pub extern var PyExc_AssertionError: ?*PyObject;
pub extern var PyExc_AttributeError: ?*PyObject;
pub extern var PyExc_BufferError: ?*PyObject;
pub extern var PyExc_EOFError: ?*PyObject;
pub extern var PyExc_FloatingPointError: ?*PyObject;
pub extern var PyExc_OSError: ?*PyObject;
pub extern var PyExc_ImportError: ?*PyObject;
pub extern var PyExc_ModuleNotFoundError: ?*PyObject;
pub extern var PyExc_IndexError: ?*PyObject;
pub extern var PyExc_KeyError: ?*PyObject;
pub extern var PyExc_KeyboardInterrupt: ?*PyObject;
pub extern var PyExc_MemoryError: ?*PyObject;
pub extern var PyExc_NameError: ?*PyObject;
pub extern var PyExc_OverflowError: ?*PyObject;
pub extern var PyExc_RuntimeError: ?*PyObject;
pub extern var PyExc_RecursionError: ?*PyObject;
pub extern var PyExc_NotImplementedError: ?*PyObject;
pub extern var PyExc_SyntaxError: ?*PyObject;
pub extern var PyExc_IndentationError: ?*PyObject;
pub extern var PyExc_TabError: ?*PyObject;
pub extern var PyExc_ReferenceError: ?*PyObject;
pub extern var PyExc_SystemError: ?*PyObject;
pub extern var PyExc_SystemExit: ?*PyObject;
pub extern var PyExc_TypeError: ?*PyObject;
pub extern var PyExc_UnboundLocalError: ?*PyObject;
pub extern var PyExc_UnicodeError: ?*PyObject;
pub extern var PyExc_UnicodeEncodeError: ?*PyObject;
pub extern var PyExc_UnicodeDecodeError: ?*PyObject;
pub extern var PyExc_UnicodeTranslateError: ?*PyObject;
pub extern var PyExc_ValueError: ?*PyObject;
pub extern var PyExc_ZeroDivisionError: ?*PyObject;
pub extern var PyExc_BlockingIOError: ?*PyObject;
pub extern var PyExc_BrokenPipeError: ?*PyObject;
pub extern var PyExc_ChildProcessError: ?*PyObject;
pub extern var PyExc_ConnectionError: ?*PyObject;
pub extern var PyExc_ConnectionAbortedError: ?*PyObject;
pub extern var PyExc_ConnectionRefusedError: ?*PyObject;
pub extern var PyExc_ConnectionResetError: ?*PyObject;
pub extern var PyExc_FileExistsError: ?*PyObject;
pub extern var PyExc_FileNotFoundError: ?*PyObject;
pub extern var PyExc_InterruptedError: ?*PyObject;
pub extern var PyExc_IsADirectoryError: ?*PyObject;
pub extern var PyExc_NotADirectoryError: ?*PyObject;
pub extern var PyExc_PermissionError: ?*PyObject;
pub extern var PyExc_ProcessLookupError: ?*PyObject;
pub extern var PyExc_TimeoutError: ?*PyObject;
pub extern var PyExc_EnvironmentError: ?*PyObject;
pub extern var PyExc_IOError: ?*PyObject;
pub extern var PyExc_Warning: ?*PyObject;
pub extern var PyExc_UserWarning: ?*PyObject;
pub extern var PyExc_DeprecationWarning: ?*PyObject;
pub extern var PyExc_PendingDeprecationWarning: ?*PyObject;
pub extern var PyExc_SyntaxWarning: ?*PyObject;
pub extern var PyExc_RuntimeWarning: ?*PyObject;
pub extern var PyExc_FutureWarning: ?*PyObject;
pub extern var PyExc_ImportWarning: ?*PyObject;
pub extern var PyExc_UnicodeWarning: ?*PyObject;
pub extern var PyExc_BytesWarning: ?*PyObject;
pub extern var PyExc_EncodingWarning: ?*PyObject;
pub extern var PyExc_ResourceWarning: ?*PyObject;
pub extern fn PyErr_BadArgument() c_int;
pub extern fn PyErr_NoMemory() ?*PyObject;
pub extern fn PyErr_SetFromErrno(?*PyObject) ?*PyObject;
pub extern fn PyErr_SetFromErrnoWithFilenameObject(?*PyObject, ?*PyObject) ?*PyObject;
pub extern fn PyErr_SetFromErrnoWithFilenameObjects(?*PyObject, ?*PyObject, ?*PyObject) ?*PyObject;
pub extern fn PyErr_SetFromErrnoWithFilename(exc: ?*PyObject, filename: ?*const u8) ?*PyObject;
pub extern fn PyErr_Format(exception: ?*PyObject, format: ?*const u8, ...) ?*PyObject;
pub extern fn PyErr_SetImportErrorSubclass(?*PyObject, ?*PyObject, ?*PyObject, ?*PyObject) ?*PyObject;
pub extern fn PyErr_SetImportError(?*PyObject, ?*PyObject, ?*PyObject) ?*PyObject;
pub extern fn PyErr_BadInternalCall() void;
pub extern fn _PyErr_BadInternalCall(filename: ?*const u8, lineno: c_int) void;
pub extern fn PyErr_NewException(name: ?*const u8, base: ?*PyObject, dict: ?*PyObject) ?*PyObject;
pub extern fn PyErr_NewExceptionWithDoc(name: ?*const u8, doc: ?*const u8, base: ?*PyObject, dict: ?*PyObject) ?*PyObject;
pub extern fn PyErr_WriteUnraisable(?*PyObject) void;
pub extern fn PyErr_CheckSignals() c_int;
pub extern fn PyErr_SetInterrupt() void;
pub extern fn PyErr_SetInterruptEx(signum: c_int) c_int;
pub extern fn PyErr_SyntaxLocation(filename: ?*const u8, lineno: c_int) void;
pub extern fn PyErr_SyntaxLocationEx(filename: ?*const u8, lineno: c_int, col_offset: c_int) void;
pub extern fn PyErr_ProgramText(filename: ?*const u8, lineno: c_int) ?*PyObject;
pub extern fn PyUnicodeDecodeError_Create(encoding: ?*const u8, object: ?*const u8, length: Py_ssize_t, start: Py_ssize_t, end: Py_ssize_t, reason: ?*const u8) ?*PyObject;
pub extern fn PyUnicodeEncodeError_GetEncoding(?*PyObject) ?*PyObject;
pub extern fn PyUnicodeDecodeError_GetEncoding(?*PyObject) ?*PyObject;
pub extern fn PyUnicodeEncodeError_GetObject(?*PyObject) ?*PyObject;
pub extern fn PyUnicodeDecodeError_GetObject(?*PyObject) ?*PyObject;
pub extern fn PyUnicodeTranslateError_GetObject(?*PyObject) ?*PyObject;
pub extern fn PyUnicodeEncodeError_GetStart(?*PyObject, ?*Py_ssize_t) c_int;
pub extern fn PyUnicodeDecodeError_GetStart(?*PyObject, ?*Py_ssize_t) c_int;
pub extern fn PyUnicodeTranslateError_GetStart(?*PyObject, ?*Py_ssize_t) c_int;
pub extern fn PyUnicodeEncodeError_SetStart(?*PyObject, Py_ssize_t) c_int;
pub extern fn PyUnicodeDecodeError_SetStart(?*PyObject, Py_ssize_t) c_int;
pub extern fn PyUnicodeTranslateError_SetStart(?*PyObject, Py_ssize_t) c_int;
pub extern fn PyUnicodeEncodeError_GetEnd(?*PyObject, ?*Py_ssize_t) c_int;
pub extern fn PyUnicodeDecodeError_GetEnd(?*PyObject, ?*Py_ssize_t) c_int;
pub extern fn PyUnicodeTranslateError_GetEnd(?*PyObject, ?*Py_ssize_t) c_int;
pub extern fn PyUnicodeEncodeError_SetEnd(?*PyObject, Py_ssize_t) c_int;
pub extern fn PyUnicodeDecodeError_SetEnd(?*PyObject, Py_ssize_t) c_int;
pub extern fn PyUnicodeTranslateError_SetEnd(?*PyObject, Py_ssize_t) c_int;
pub extern fn PyUnicodeEncodeError_GetReason(?*PyObject) ?*PyObject;
pub extern fn PyUnicodeDecodeError_GetReason(?*PyObject) ?*PyObject;
pub extern fn PyUnicodeTranslateError_GetReason(?*PyObject) ?*PyObject;
pub extern fn PyUnicodeEncodeError_SetReason(exc: ?*PyObject, reason: ?*const u8) c_int;
pub extern fn PyUnicodeDecodeError_SetReason(exc: ?*PyObject, reason: ?*const u8) c_int;
pub extern fn PyUnicodeTranslateError_SetReason(exc: ?*PyObject, reason: ?*const u8) c_int;
pub extern fn PyOS_snprintf(str: ?*u8, size: usize, format: ?*const u8, ...) c_int;
pub extern fn PyOS_vsnprintf(str: ?*u8, size: usize, format: ?*const u8, va: ?*struct___va_list_tag_3) c_int;
pub const PyBaseExceptionObject = extern struct {
    ob_base: PyObject = std.mem.zeroes(PyObject),
    dict: ?*PyObject = std.mem.zeroes(?*PyObject),
    args: ?*PyObject = std.mem.zeroes(?*PyObject),
    notes: ?*PyObject = std.mem.zeroes(?*PyObject),
    traceback: ?*PyObject = std.mem.zeroes(?*PyObject),
    context: ?*PyObject = std.mem.zeroes(?*PyObject),
    cause: ?*PyObject = std.mem.zeroes(?*PyObject),
    suppress_context: u8 = std.mem.zeroes(u8),
};
pub const PyBaseExceptionGroupObject = extern struct {
    ob_base: PyObject = std.mem.zeroes(PyObject),
    dict: ?*PyObject = std.mem.zeroes(?*PyObject),
    args: ?*PyObject = std.mem.zeroes(?*PyObject),
    notes: ?*PyObject = std.mem.zeroes(?*PyObject),
    traceback: ?*PyObject = std.mem.zeroes(?*PyObject),
    context: ?*PyObject = std.mem.zeroes(?*PyObject),
    cause: ?*PyObject = std.mem.zeroes(?*PyObject),
    suppress_context: u8 = std.mem.zeroes(u8),
    msg: ?*PyObject = std.mem.zeroes(?*PyObject),
    excs: ?*PyObject = std.mem.zeroes(?*PyObject),
};
pub const PySyntaxErrorObject = extern struct {
    ob_base: PyObject = std.mem.zeroes(PyObject),
    dict: ?*PyObject = std.mem.zeroes(?*PyObject),
    args: ?*PyObject = std.mem.zeroes(?*PyObject),
    notes: ?*PyObject = std.mem.zeroes(?*PyObject),
    traceback: ?*PyObject = std.mem.zeroes(?*PyObject),
    context: ?*PyObject = std.mem.zeroes(?*PyObject),
    cause: ?*PyObject = std.mem.zeroes(?*PyObject),
    suppress_context: u8 = std.mem.zeroes(u8),
    msg: ?*PyObject = std.mem.zeroes(?*PyObject),
    filename: ?*PyObject = std.mem.zeroes(?*PyObject),
    lineno: ?*PyObject = std.mem.zeroes(?*PyObject),
    offset: ?*PyObject = std.mem.zeroes(?*PyObject),
    end_lineno: ?*PyObject = std.mem.zeroes(?*PyObject),
    end_offset: ?*PyObject = std.mem.zeroes(?*PyObject),
    text: ?*PyObject = std.mem.zeroes(?*PyObject),
    print_file_and_line: ?*PyObject = std.mem.zeroes(?*PyObject),
};
pub const PyImportErrorObject = extern struct {
    ob_base: PyObject = std.mem.zeroes(PyObject),
    dict: ?*PyObject = std.mem.zeroes(?*PyObject),
    args: ?*PyObject = std.mem.zeroes(?*PyObject),
    notes: ?*PyObject = std.mem.zeroes(?*PyObject),
    traceback: ?*PyObject = std.mem.zeroes(?*PyObject),
    context: ?*PyObject = std.mem.zeroes(?*PyObject),
    cause: ?*PyObject = std.mem.zeroes(?*PyObject),
    suppress_context: u8 = std.mem.zeroes(u8),
    msg: ?*PyObject = std.mem.zeroes(?*PyObject),
    name: ?*PyObject = std.mem.zeroes(?*PyObject),
    path: ?*PyObject = std.mem.zeroes(?*PyObject),
    name_from: ?*PyObject = std.mem.zeroes(?*PyObject),
};
pub const PyUnicodeErrorObject = extern struct {
    ob_base: PyObject = std.mem.zeroes(PyObject),
    dict: ?*PyObject = std.mem.zeroes(?*PyObject),
    args: ?*PyObject = std.mem.zeroes(?*PyObject),
    notes: ?*PyObject = std.mem.zeroes(?*PyObject),
    traceback: ?*PyObject = std.mem.zeroes(?*PyObject),
    context: ?*PyObject = std.mem.zeroes(?*PyObject),
    cause: ?*PyObject = std.mem.zeroes(?*PyObject),
    suppress_context: u8 = std.mem.zeroes(u8),
    encoding: ?*PyObject = std.mem.zeroes(?*PyObject),
    object: ?*PyObject = std.mem.zeroes(?*PyObject),
    start: Py_ssize_t = std.mem.zeroes(Py_ssize_t),
    end: Py_ssize_t = std.mem.zeroes(Py_ssize_t),
    reason: ?*PyObject = std.mem.zeroes(?*PyObject),
};
pub const PySystemExitObject = extern struct {
    ob_base: PyObject = std.mem.zeroes(PyObject),
    dict: ?*PyObject = std.mem.zeroes(?*PyObject),
    args: ?*PyObject = std.mem.zeroes(?*PyObject),
    notes: ?*PyObject = std.mem.zeroes(?*PyObject),
    traceback: ?*PyObject = std.mem.zeroes(?*PyObject),
    context: ?*PyObject = std.mem.zeroes(?*PyObject),
    cause: ?*PyObject = std.mem.zeroes(?*PyObject),
    suppress_context: u8 = std.mem.zeroes(u8),
    code: ?*PyObject = std.mem.zeroes(?*PyObject),
};
pub const PyOSErrorObject = extern struct {
    ob_base: PyObject = std.mem.zeroes(PyObject),
    dict: ?*PyObject = std.mem.zeroes(?*PyObject),
    args: ?*PyObject = std.mem.zeroes(?*PyObject),
    notes: ?*PyObject = std.mem.zeroes(?*PyObject),
    traceback: ?*PyObject = std.mem.zeroes(?*PyObject),
    context: ?*PyObject = std.mem.zeroes(?*PyObject),
    cause: ?*PyObject = std.mem.zeroes(?*PyObject),
    suppress_context: u8 = std.mem.zeroes(u8),
    myerrno: ?*PyObject = std.mem.zeroes(?*PyObject),
    strerror: ?*PyObject = std.mem.zeroes(?*PyObject),
    filename: ?*PyObject = std.mem.zeroes(?*PyObject),
    filename2: ?*PyObject = std.mem.zeroes(?*PyObject),
    written: Py_ssize_t = std.mem.zeroes(Py_ssize_t),
};
pub const PyStopIterationObject = extern struct {
    ob_base: PyObject = std.mem.zeroes(PyObject),
    dict: ?*PyObject = std.mem.zeroes(?*PyObject),
    args: ?*PyObject = std.mem.zeroes(?*PyObject),
    notes: ?*PyObject = std.mem.zeroes(?*PyObject),
    traceback: ?*PyObject = std.mem.zeroes(?*PyObject),
    context: ?*PyObject = std.mem.zeroes(?*PyObject),
    cause: ?*PyObject = std.mem.zeroes(?*PyObject),
    suppress_context: u8 = std.mem.zeroes(u8),
    value: ?*PyObject = std.mem.zeroes(?*PyObject),
};
pub const PyNameErrorObject = extern struct {
    ob_base: PyObject = std.mem.zeroes(PyObject),
    dict: ?*PyObject = std.mem.zeroes(?*PyObject),
    args: ?*PyObject = std.mem.zeroes(?*PyObject),
    notes: ?*PyObject = std.mem.zeroes(?*PyObject),
    traceback: ?*PyObject = std.mem.zeroes(?*PyObject),
    context: ?*PyObject = std.mem.zeroes(?*PyObject),
    cause: ?*PyObject = std.mem.zeroes(?*PyObject),
    suppress_context: u8 = std.mem.zeroes(u8),
    name: ?*PyObject = std.mem.zeroes(?*PyObject),
};
pub const PyAttributeErrorObject = extern struct {
    ob_base: PyObject = std.mem.zeroes(PyObject),
    dict: ?*PyObject = std.mem.zeroes(?*PyObject),
    args: ?*PyObject = std.mem.zeroes(?*PyObject),
    notes: ?*PyObject = std.mem.zeroes(?*PyObject),
    traceback: ?*PyObject = std.mem.zeroes(?*PyObject),
    context: ?*PyObject = std.mem.zeroes(?*PyObject),
    cause: ?*PyObject = std.mem.zeroes(?*PyObject),
    suppress_context: u8 = std.mem.zeroes(u8),
    obj: ?*PyObject = std.mem.zeroes(?*PyObject),
    name: ?*PyObject = std.mem.zeroes(?*PyObject),
};
pub const PyEnvironmentErrorObject = PyOSErrorObject;
pub extern fn _PyErr_ChainExceptions1(?*PyObject) void;
pub extern fn PyUnstable_Exc_PrepReraiseStar(orig: ?*PyObject, excs: ?*PyObject) ?*PyObject;
pub extern fn PySignal_SetWakeupFd(fd: c_int) c_int;
pub extern fn PyErr_SyntaxLocationObject(filename: ?*PyObject, lineno: c_int, col_offset: c_int) void;
pub extern fn PyErr_RangedSyntaxLocationObject(filename: ?*PyObject, lineno: c_int, col_offset: c_int, end_lineno: c_int, end_col_offset: c_int) void;
pub extern fn PyErr_ProgramTextObject(filename: ?*PyObject, lineno: c_int) ?*PyObject;
pub extern fn _Py_FatalErrorFunc(func: ?*const u8, message: ?*const u8) noreturn;
pub extern fn PyErr_FormatUnraisable(?*const u8, ...) void;
pub extern var PyExc_PythonFinalizationError: ?*PyObject;
pub extern fn PyLong_FromLong(c_long) ?*PyObject;
pub extern fn PyLong_FromUnsignedLong(c_ulong) ?*PyObject;
pub extern fn PyLong_FromSize_t(usize) ?*PyObject;
pub extern fn PyLong_FromSsize_t(Py_ssize_t) ?*PyObject;
pub extern fn PyLong_FromDouble(f64) ?*PyObject;
pub extern fn PyLong_AsLong(?*PyObject) c_long;
pub extern fn PyLong_AsLongAndOverflow(?*PyObject, ?*c_int) c_long;
pub extern fn PyLong_AsSsize_t(?*PyObject) Py_ssize_t;
pub extern fn PyLong_AsSize_t(?*PyObject) usize;
pub extern fn PyLong_AsUnsignedLong(?*PyObject) c_ulong;
pub extern fn PyLong_AsUnsignedLongMask(?*PyObject) c_ulong;
pub extern fn PyLong_AsInt(?*PyObject) c_int;
pub extern fn PyLong_GetInfo() ?*PyObject;
pub extern fn PyLong_AsDouble(?*PyObject) f64;
pub extern fn PyLong_FromVoidPtr(?*anyopaque) ?*PyObject;
pub extern fn PyLong_AsVoidPtr(?*PyObject) ?*anyopaque;
pub extern fn PyLong_FromLongLong(c_longlong) ?*PyObject;
pub extern fn PyLong_FromUnsignedLongLong(c_ulonglong) ?*PyObject;
pub extern fn PyLong_AsLongLong(?*PyObject) c_longlong;
pub extern fn PyLong_AsUnsignedLongLong(?*PyObject) c_ulonglong;
pub extern fn PyLong_AsUnsignedLongLongMask(?*PyObject) c_ulonglong;
pub extern fn PyLong_AsLongLongAndOverflow(?*PyObject, ?*c_int) c_longlong;
pub extern fn PyLong_FromString(?*const u8, ?*?*u8, c_int) ?*PyObject;
pub extern fn PyOS_strtoul(?*const u8, ?*?*u8, c_int) c_ulong;
pub extern fn PyOS_strtol(?*const u8, ?*?*u8, c_int) c_long;
pub extern fn PyLong_FromUnicodeObject(u: ?*PyObject, base: c_int) ?*PyObject;
pub extern fn PyLong_AsNativeBytes(v: ?*PyObject, buffer: ?*anyopaque, n_bytes: Py_ssize_t, flags: c_int) Py_ssize_t;
pub extern fn PyLong_FromNativeBytes(buffer: ?*const anyopaque, n_bytes: usize, flags: c_int) ?*PyObject;
pub extern fn PyLong_FromUnsignedNativeBytes(buffer: ?*const anyopaque, n_bytes: usize, flags: c_int) ?*PyObject;
pub extern fn PyUnstable_Long_IsCompact(op: ?*const PyLongObject) c_int;
pub extern fn PyUnstable_Long_CompactValue(op: ?*const PyLongObject) Py_ssize_t;
pub extern fn _PyLong_Sign(v: ?*PyObject) c_int;
pub extern fn _PyLong_NumBits(v: ?*PyObject) usize;
pub extern fn _PyLong_FromByteArray(bytes: ?*const u8, n: usize, little_endian: c_int, is_signed: c_int) ?*PyObject;
pub extern fn _PyLong_AsByteArray(v: ?*PyLongObject, bytes: ?*u8, n: usize, little_endian: c_int, is_signed: c_int, with_exceptions: c_int) c_int;
pub extern fn _PyLong_GCD(?*PyObject, ?*PyObject) ?*PyObject;
pub const sdigit = i32;
pub const twodigits = u64;
pub const stwodigits = i64;
pub extern fn _PyLong_New(Py_ssize_t) ?*PyLongObject;
pub extern fn _PyLong_Copy(src: ?*PyLongObject) ?*PyObject;
pub extern fn _PyLong_FromDigits(negative: c_int, digit_count: Py_ssize_t, digits: ?*digit) ?*PyLongObject;
pub fn _PyLong_IsCompact(arg_op: ?*const PyLongObject) callconv(.c) c_int {
    var op = arg_op;
    _ = &op;
    _ = blk: {
        _ = @sizeOf(c_int);
        break :blk blk_1: {
            break :blk_1 if (PyType_HasFeature(op.*.ob_base.ob_type, @as(c_ulong, 1) << @intCast(24)) != 0) {} else {
                __assert_fail("PyType_HasFeature((op)->ob_base.ob_type, Py_TPFLAGS_LONG_SUBCLASS)", "/usr/include/python3.13/cpython/longintrepr.h", @as(c_uint, @bitCast(@as(c_int, 123))), "int _PyLong_IsCompact(const PyLongObject *)");
            };
        };
    };
    return @intFromBool(op.*.long_value.lv_tag < @as(usize, @bitCast(@as(c_long, @as(c_int, 2) << @intCast(3)))));
}
pub fn _PyLong_CompactValue(arg_op: ?*const PyLongObject) callconv(.c) Py_ssize_t {
    var op = arg_op;
    _ = &op;
    var sign: Py_ssize_t = undefined;
    _ = &sign;
    _ = blk: {
        _ = @sizeOf(c_int);
        break :blk blk_1: {
            break :blk_1 if (PyType_HasFeature(op.*.ob_base.ob_type, @as(c_ulong, 1) << @intCast(24)) != 0) {} else {
                __assert_fail("PyType_HasFeature((op)->ob_base.ob_type, Py_TPFLAGS_LONG_SUBCLASS)", "/usr/include/python3.13/cpython/longintrepr.h", @as(c_uint, @bitCast(@as(c_int, 133))), "Py_ssize_t _PyLong_CompactValue(const PyLongObject *)");
            };
        };
    };
    _ = blk: {
        _ = @sizeOf(c_int);
        break :blk blk_1: {
            break :blk_1 if (_PyLong_IsCompact(op) != 0) {} else {
                __assert_fail("PyUnstable_Long_IsCompact(op)", "/usr/include/python3.13/cpython/longintrepr.h", @as(c_uint, @bitCast(@as(c_int, 134))), "Py_ssize_t _PyLong_CompactValue(const PyLongObject *)");
            };
        };
    };
    sign = @as(Py_ssize_t, @bitCast(@as(usize, @bitCast(@as(c_long, @as(c_int, 1)))) -% (op.*.long_value.lv_tag & @as(usize, @bitCast(@as(c_long, @as(c_int, 3)))))));
    return sign * @as(Py_ssize_t, @bitCast(@as(c_ulong, op.*.long_value.ob_digit[@as(c_uint, @intCast(@as(c_int, 0)))])));
}
pub extern var _Py_FalseStruct: PyLongObject;
pub extern var _Py_TrueStruct: PyLongObject;
pub extern fn Py_IsTrue(x: ?*PyObject) c_int;
pub extern fn Py_IsFalse(x: ?*PyObject) c_int;
pub extern fn PyBool_FromLong(c_long) ?*PyObject;
pub extern var PyFloat_Type: PyTypeObject;
pub extern fn PyFloat_GetMax() f64;
pub extern fn PyFloat_GetMin() f64;
pub extern fn PyFloat_GetInfo() ?*PyObject;
pub extern fn PyFloat_FromString(?*PyObject) ?*PyObject;
pub extern fn PyFloat_FromDouble(f64) ?*PyObject;
pub extern fn PyFloat_AsDouble(?*PyObject) f64;
pub const PyFloatObject = extern struct {
    ob_base: PyObject = std.mem.zeroes(PyObject),
    ob_fval: f64 = std.mem.zeroes(f64),
};
pub fn PyFloat_AS_DOUBLE(arg_op: ?*PyObject) callconv(.c) f64 {
    var op = arg_op;
    _ = &op;
    return (blk: {
        _ = blk_1: {
            _ = @sizeOf(c_int);
            break :blk_1 blk_2: {
                break :blk_2 if (PyObject_TypeCheck(op, &PyFloat_Type) != 0) {} else {
                    __assert_fail("PyFloat_Check(op)", "/usr/include/python3.13/cpython/floatobject.h", @as(c_uint, @bitCast(@as(c_int, 16))), "double PyFloat_AS_DOUBLE(PyObject *)");
                };
            };
        };
        break :blk @as(?*PyFloatObject, @ptrCast(@alignCast(op)));
    }).*.ob_fval;
}
pub extern fn PyFloat_Pack2(x: f64, p: ?*u8, le: c_int) c_int;
pub extern fn PyFloat_Pack4(x: f64, p: ?*u8, le: c_int) c_int;
pub extern fn PyFloat_Pack8(x: f64, p: ?*u8, le: c_int) c_int;
pub extern fn PyFloat_Unpack2(p: ?*const u8, le: c_int) f64;
pub extern fn PyFloat_Unpack4(p: ?*const u8, le: c_int) f64;
pub extern fn PyFloat_Unpack8(p: ?*const u8, le: c_int) f64;
pub extern var PyComplex_Type: PyTypeObject;
pub extern fn PyComplex_FromDoubles(real: f64, imag: f64) ?*PyObject;
pub extern fn PyComplex_RealAsDouble(op: ?*PyObject) f64;
pub extern fn PyComplex_ImagAsDouble(op: ?*PyObject) f64;
pub const Py_complex = extern struct {
    real: f64 = std.mem.zeroes(f64),
    imag: f64 = std.mem.zeroes(f64),
};
pub extern fn _Py_c_sum(Py_complex, Py_complex) Py_complex;
pub extern fn _Py_c_diff(Py_complex, Py_complex) Py_complex;
pub extern fn _Py_c_neg(Py_complex) Py_complex;
pub extern fn _Py_c_prod(Py_complex, Py_complex) Py_complex;
pub extern fn _Py_c_quot(Py_complex, Py_complex) Py_complex;
pub extern fn _Py_c_pow(Py_complex, Py_complex) Py_complex;
pub extern fn _Py_c_abs(Py_complex) f64;
pub const PyComplexObject = extern struct {
    ob_base: PyObject = std.mem.zeroes(PyObject),
    cval: Py_complex = std.mem.zeroes(Py_complex),
};
pub extern fn PyComplex_FromCComplex(Py_complex) ?*PyObject;
pub extern fn PyComplex_AsCComplex(op: ?*PyObject) Py_complex;
pub extern var PyRange_Type: PyTypeObject;
pub extern var PyRangeIter_Type: PyTypeObject;
pub extern var PyLongRangeIter_Type: PyTypeObject;
pub extern var PyMemoryView_Type: PyTypeObject;
pub extern fn PyMemoryView_FromObject(base: ?*PyObject) ?*PyObject;
pub extern fn PyMemoryView_FromMemory(mem: ?*u8, size: Py_ssize_t, flags: c_int) ?*PyObject;
pub extern fn PyMemoryView_FromBuffer(info: ?*const Py_buffer) ?*PyObject;
pub extern fn PyMemoryView_GetContiguous(base: ?*PyObject, buffertype: c_int, order: u8) ?*PyObject;
pub const _PyManagedBufferObject = extern struct {
    ob_base: PyObject = std.mem.zeroes(PyObject),
    flags: c_int = std.mem.zeroes(c_int),
    exports: Py_ssize_t = std.mem.zeroes(Py_ssize_t),
    master: Py_buffer = std.mem.zeroes(Py_buffer),
};
pub const PyMemoryViewObject = extern struct {
    ob_base: PyVarObject = std.mem.zeroes(PyVarObject),
    mbuf: ?*_PyManagedBufferObject = std.mem.zeroes(?*_PyManagedBufferObject),
    hash: Py_hash_t = std.mem.zeroes(Py_hash_t),
    flags: c_int = std.mem.zeroes(c_int),
    exports: Py_ssize_t = std.mem.zeroes(Py_ssize_t),
    view: Py_buffer = std.mem.zeroes(Py_buffer),
    weakreflist: ?*PyObject = std.mem.zeroes(?*PyObject),
    ob_array: [1]Py_ssize_t = std.mem.zeroes([1]Py_ssize_t),
};
pub fn PyMemoryView_GET_BUFFER(arg_op: ?*PyObject) callconv(.c) ?*Py_buffer {
    var op = arg_op;
    _ = &op;
    return &@as(?*PyMemoryViewObject, @ptrCast(@alignCast(op))).*.view;
}
pub fn PyMemoryView_GET_BASE(arg_op: ?*PyObject) callconv(.c) ?*PyObject {
    var op = arg_op;
    _ = &op;
    return @as(?*PyMemoryViewObject, @ptrCast(@alignCast(op))).*.view.obj;
}
pub extern var PyTuple_Type: PyTypeObject;
pub extern var PyTupleIter_Type: PyTypeObject;
pub extern fn PyTuple_New(size: Py_ssize_t) ?*PyObject;
pub extern fn PyTuple_Size(?*PyObject) Py_ssize_t;
pub extern fn PyTuple_GetItem(?*PyObject, Py_ssize_t) ?*PyObject;
pub extern fn PyTuple_SetItem(?*PyObject, Py_ssize_t, ?*PyObject) c_int;
pub extern fn PyTuple_GetSlice(?*PyObject, Py_ssize_t, Py_ssize_t) ?*PyObject;
pub extern fn PyTuple_Pack(Py_ssize_t, ...) ?*PyObject;
pub const PyTupleObject = extern struct {
    ob_base: PyVarObject = std.mem.zeroes(PyVarObject),
    ob_item: [1]?*PyObject = std.mem.zeroes([1]?*PyObject),
};
pub extern fn _PyTuple_Resize(?*?*PyObject, Py_ssize_t) c_int;
pub fn Py_SIZE(arg_ob: ?*PyObject) callconv(.c) Py_ssize_t {
    var ob = arg_ob;
    _ = &ob;
    _ = blk: {
        _ = @sizeOf(c_int);
        break :blk blk_1: {
            break :blk_1 if (ob.*.ob_type != (&PyLong_Type)) {} else {
                __assert_fail("ob->ob_type != &PyLong_Type", "/usr/include/python3.13/object.h", @as(c_uint, @bitCast(@as(c_int, 347))), "Py_ssize_t Py_SIZE(PyObject *)");
            };
        };
    };
    _ = blk: {
        _ = @sizeOf(c_int);
        break :blk blk_1: {
            break :blk_1 if (ob.*.ob_type != (&PyBool_Type)) {} else {
                __assert_fail("ob->ob_type != &PyBool_Type", "/usr/include/python3.13/object.h", @as(c_uint, @bitCast(@as(c_int, 348))), "Py_ssize_t Py_SIZE(PyObject *)");
            };
        };
    };
    return @as(?*PyVarObject, @ptrCast(@alignCast(ob))).*.ob_size;
}
pub fn PyTuple_GET_SIZE(arg_op: ?*PyObject) callconv(.c) Py_ssize_t {
    var op = arg_op;
    _ = &op;
    var tuple: ?*PyTupleObject = blk: {
        _ = blk_1: {
            _ = @sizeOf(c_int);
            break :blk_1 blk_2: {
                break :blk_2 if (PyType_HasFeature(Py_TYPE(op), @as(c_ulong, 1) << @intCast(26)) != 0) {} else {
                    __assert_fail("PyTuple_Check(op)", "/usr/include/python3.13/cpython/tupleobject.h", @as(c_uint, @bitCast(@as(c_int, 22))), "Py_ssize_t PyTuple_GET_SIZE(PyObject *)");
                };
            };
        };
        break :blk @as(?*PyTupleObject, @ptrCast(@alignCast(op)));
    };
    _ = &tuple;
    return Py_SIZE(@as(?*PyObject, @ptrCast(@alignCast(tuple))));
}
pub fn PyTuple_SET_ITEM(arg_op: ?*PyObject, arg_index_1: Py_ssize_t, arg_value: ?*PyObject) callconv(.c) void {
    var op = arg_op;
    _ = &op;
    var index_1 = arg_index_1;
    _ = &index_1;
    var value = arg_value;
    _ = &value;
    var tuple: ?*PyTupleObject = blk: {
        _ = blk_1: {
            _ = @sizeOf(c_int);
            break :blk_1 blk_2: {
                break :blk_2 if (PyType_HasFeature(Py_TYPE(op), @as(c_ulong, 1) << @intCast(26)) != 0) {} else {
                    __assert_fail("PyTuple_Check(op)", "/usr/include/python3.13/cpython/tupleobject.h", @as(c_uint, @bitCast(@as(c_int, 32))), "void PyTuple_SET_ITEM(PyObject *, Py_ssize_t, PyObject *)");
                };
            };
        };
        break :blk @as(?*PyTupleObject, @ptrCast(@alignCast(op)));
    };
    _ = &tuple;
    _ = blk: {
        _ = @sizeOf(c_int);
        break :blk blk_1: {
            break :blk_1 if (@as(Py_ssize_t, @bitCast(@as(c_long, @as(c_int, 0)))) <= index_1) {} else {
                __assert_fail("0 <= index", "/usr/include/python3.13/cpython/tupleobject.h", @as(c_uint, @bitCast(@as(c_int, 33))), "void PyTuple_SET_ITEM(PyObject *, Py_ssize_t, PyObject *)");
            };
        };
    };
    _ = blk: {
        _ = @sizeOf(c_int);
        break :blk blk_1: {
            break :blk_1 if (index_1 < Py_SIZE(@as(?*PyObject, @ptrCast(@alignCast(tuple))))) {} else {
                __assert_fail("index < Py_SIZE(tuple)", "/usr/include/python3.13/cpython/tupleobject.h", @as(c_uint, @bitCast(@as(c_int, 34))), "void PyTuple_SET_ITEM(PyObject *, Py_ssize_t, PyObject *)");
            };
        };
    };
    tuple.*.ob_item[@as(c_ulong, @intCast(index_1))] = value;
}
pub extern var PyList_Type: PyTypeObject;
pub extern var PyListIter_Type: PyTypeObject;
pub extern var PyListRevIter_Type: PyTypeObject;
pub extern fn PyList_New(size: Py_ssize_t) ?*PyObject;
pub extern fn PyList_Size(?*PyObject) Py_ssize_t;
pub extern fn PyList_GetItem(?*PyObject, Py_ssize_t) ?*PyObject;
pub extern fn PyList_GetItemRef(?*PyObject, Py_ssize_t) ?*PyObject;
pub extern fn PyList_SetItem(?*PyObject, Py_ssize_t, ?*PyObject) c_int;
pub extern fn PyList_Insert(?*PyObject, Py_ssize_t, ?*PyObject) c_int;
pub extern fn PyList_Append(?*PyObject, ?*PyObject) c_int;
pub extern fn PyList_GetSlice(?*PyObject, Py_ssize_t, Py_ssize_t) ?*PyObject;
pub extern fn PyList_SetSlice(?*PyObject, Py_ssize_t, Py_ssize_t, ?*PyObject) c_int;
pub extern fn PyList_Sort(?*PyObject) c_int;
pub extern fn PyList_Reverse(?*PyObject) c_int;
pub extern fn PyList_AsTuple(?*PyObject) ?*PyObject;
pub const PyListObject = extern struct {
    ob_base: PyVarObject = std.mem.zeroes(PyVarObject),
    ob_item: ?*?*PyObject = std.mem.zeroes(?*?*PyObject),
    allocated: Py_ssize_t = std.mem.zeroes(Py_ssize_t),
};
pub fn PyList_GET_SIZE(arg_op: ?*PyObject) callconv(.c) Py_ssize_t {
    var op = arg_op;
    _ = &op;
    var list: ?*PyListObject = blk: {
        _ = blk_1: {
            _ = @sizeOf(c_int);
            break :blk_1 blk_2: {
                break :blk_2 if (PyType_HasFeature(Py_TYPE(op), @as(c_ulong, 1) << @intCast(25)) != 0) {} else {
                    __assert_fail("PyList_Check(op)", "/usr/include/python3.13/cpython/listobject.h", @as(c_uint, @bitCast(@as(c_int, 31))), "Py_ssize_t PyList_GET_SIZE(PyObject *)");
                };
            };
        };
        break :blk @as(?*PyListObject, @ptrCast(@alignCast(op)));
    };
    _ = &list;
    return Py_SIZE(@as(?*PyObject, @ptrCast(@alignCast(list))));
}
pub fn PyList_SET_ITEM(arg_op: ?*PyObject, arg_index_1: Py_ssize_t, arg_value: ?*PyObject) callconv(.c) void {
    var op = arg_op;
    _ = &op;
    var index_1 = arg_index_1;
    _ = &index_1;
    var value = arg_value;
    _ = &value;
    var list: ?*PyListObject = blk: {
        _ = blk_1: {
            _ = @sizeOf(c_int);
            break :blk_1 blk_2: {
                break :blk_2 if (PyType_HasFeature(Py_TYPE(op), @as(c_ulong, 1) << @intCast(25)) != 0) {} else {
                    __assert_fail("PyList_Check(op)", "/usr/include/python3.13/cpython/listobject.h", @as(c_uint, @bitCast(@as(c_int, 44))), "void PyList_SET_ITEM(PyObject *, Py_ssize_t, PyObject *)");
                };
            };
        };
        break :blk @as(?*PyListObject, @ptrCast(@alignCast(op)));
    };
    _ = &list;
    _ = blk: {
        _ = @sizeOf(c_int);
        break :blk blk_1: {
            break :blk_1 if (@as(Py_ssize_t, @bitCast(@as(c_long, @as(c_int, 0)))) <= index_1) {} else {
                __assert_fail("0 <= index", "/usr/include/python3.13/cpython/listobject.h", @as(c_uint, @bitCast(@as(c_int, 45))), "void PyList_SET_ITEM(PyObject *, Py_ssize_t, PyObject *)");
            };
        };
    };
    _ = blk: {
        _ = @sizeOf(c_int);
        break :blk blk_1: {
            break :blk_1 if (index_1 < list.*.allocated) {} else {
                __assert_fail("index < list->allocated", "/usr/include/python3.13/cpython/listobject.h", @as(c_uint, @bitCast(@as(c_int, 46))), "void PyList_SET_ITEM(PyObject *, Py_ssize_t, PyObject *)");
            };
        };
    };
    (blk: {
        const tmp = index_1;
        if (tmp >= 0) break :blk list.*.ob_item + @as(usize, @intCast(tmp)) else break :blk list.*.ob_item - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
    }).* = value;
}
pub extern fn PyList_Extend(self: ?*PyObject, iterable: ?*PyObject) c_int;
pub extern fn PyList_Clear(self: ?*PyObject) c_int;
pub extern var PyDict_Type: PyTypeObject;
pub extern fn PyDict_New() ?*PyObject;
pub extern fn PyDict_GetItem(mp: ?*PyObject, key: ?*PyObject) ?*PyObject;
pub extern fn PyDict_GetItemWithError(mp: ?*PyObject, key: ?*PyObject) ?*PyObject;
pub extern fn PyDict_SetItem(mp: ?*PyObject, key: ?*PyObject, item: ?*PyObject) c_int;
pub extern fn PyDict_DelItem(mp: ?*PyObject, key: ?*PyObject) c_int;
pub extern fn PyDict_Clear(mp: ?*PyObject) void;
pub extern fn PyDict_Next(mp: ?*PyObject, pos: ?*Py_ssize_t, key: ?*?*PyObject, value: ?*?*PyObject) c_int;
pub extern fn PyDict_Keys(mp: ?*PyObject) ?*PyObject;
pub extern fn PyDict_Values(mp: ?*PyObject) ?*PyObject;
pub extern fn PyDict_Items(mp: ?*PyObject) ?*PyObject;
pub extern fn PyDict_Size(mp: ?*PyObject) Py_ssize_t;
pub extern fn PyDict_Copy(mp: ?*PyObject) ?*PyObject;
pub extern fn PyDict_Contains(mp: ?*PyObject, key: ?*PyObject) c_int;
pub extern fn PyDict_Update(mp: ?*PyObject, other: ?*PyObject) c_int;
pub extern fn PyDict_Merge(mp: ?*PyObject, other: ?*PyObject, override: c_int) c_int;
pub extern fn PyDict_MergeFromSeq2(d: ?*PyObject, seq2: ?*PyObject, override: c_int) c_int;
pub extern fn PyDict_GetItemString(dp: ?*PyObject, key: ?*const u8) ?*PyObject;
pub extern fn PyDict_SetItemString(dp: ?*PyObject, key: ?*const u8, item: ?*PyObject) c_int;
pub extern fn PyDict_DelItemString(dp: ?*PyObject, key: ?*const u8) c_int;
pub extern fn PyDict_GetItemRef(mp: ?*PyObject, key: ?*PyObject, result: ?*?*PyObject) c_int;
pub extern fn PyDict_GetItemStringRef(mp: ?*PyObject, key: ?*const u8, result: ?*?*PyObject) c_int;
pub extern fn PyObject_GenericGetDict(?*PyObject, ?*anyopaque) ?*PyObject;
pub extern var PyDictKeys_Type: PyTypeObject;
pub extern var PyDictValues_Type: PyTypeObject;
pub extern var PyDictItems_Type: PyTypeObject;
pub extern var PyDictIterKey_Type: PyTypeObject;
pub extern var PyDictIterValue_Type: PyTypeObject;
pub extern var PyDictIterItem_Type: PyTypeObject;
pub extern var PyDictRevIterKey_Type: PyTypeObject;
pub extern var PyDictRevIterItem_Type: PyTypeObject;
pub extern var PyDictRevIterValue_Type: PyTypeObject;
pub const PyDictKeysObject = struct__dictkeysobject_14;
pub const struct__dictvalues = opaque {};
pub const PyDictValues = struct__dictvalues;
pub const PyDictObject = extern struct {
    ob_base: PyObject = std.mem.zeroes(PyObject),
    ma_used: Py_ssize_t = std.mem.zeroes(Py_ssize_t),
    ma_version_tag: u64 = std.mem.zeroes(u64),
    ma_keys: ?*PyDictKeysObject = std.mem.zeroes(?*PyDictKeysObject),
    ma_values: ?*PyDictValues = std.mem.zeroes(?*PyDictValues),
};
pub extern fn _PyDict_GetItem_KnownHash(mp: ?*PyObject, key: ?*PyObject, hash: Py_hash_t) ?*PyObject;
pub extern fn _PyDict_GetItemStringWithError(?*PyObject, ?*const u8) ?*PyObject;
pub extern fn PyDict_SetDefault(mp: ?*PyObject, key: ?*PyObject, defaultobj: ?*PyObject) ?*PyObject;
pub extern fn PyDict_SetDefaultRef(mp: ?*PyObject, key: ?*PyObject, default_value: ?*PyObject, result: ?*?*PyObject) c_int;
pub fn PyDict_GET_SIZE(arg_op: ?*PyObject) callconv(.c) Py_ssize_t {
    var op = arg_op;
    _ = &op;
    var mp: ?*PyDictObject = undefined;
    _ = &mp;
    _ = blk: {
        _ = @sizeOf(c_int);
        break :blk blk_1: {
            break :blk_1 if (PyType_HasFeature(Py_TYPE(op), @as(c_ulong, 1) << @intCast(29)) != 0) {} else {
                __assert_fail("PyDict_Check(op)", "/usr/include/python3.13/cpython/dictobject.h", @as(c_uint, @bitCast(@as(c_int, 57))), "Py_ssize_t PyDict_GET_SIZE(PyObject *)");
            };
        };
    };
    mp = @as(?*PyDictObject, @ptrCast(@alignCast(op)));
    return mp.*.ma_used;
}
pub extern fn PyDict_ContainsString(mp: ?*PyObject, key: ?*const u8) c_int;
pub extern fn _PyDict_NewPresized(minused: Py_ssize_t) ?*PyObject;
pub extern fn PyDict_Pop(dict: ?*PyObject, key: ?*PyObject, result: ?*?*PyObject) c_int;
pub extern fn PyDict_PopString(dict: ?*PyObject, key: ?*const u8, result: ?*?*PyObject) c_int;
pub extern fn _PyDict_Pop(dict: ?*PyObject, key: ?*PyObject, default_value: ?*PyObject) ?*PyObject;
pub const PyDict_EVENT_ADDED: c_int = 0;
pub const PyDict_EVENT_MODIFIED: c_int = 1;
pub const PyDict_EVENT_DELETED: c_int = 2;
pub const PyDict_EVENT_CLONED: c_int = 3;
pub const PyDict_EVENT_CLEARED: c_int = 4;
pub const PyDict_EVENT_DEALLOCATED: c_int = 5;
pub const PyDict_WatchEvent = c_uint;
pub const PyDict_WatchCallback = ?*const fn (PyDict_WatchEvent, ?*PyObject, ?*PyObject, ?*PyObject) callconv(.c) c_int;
pub extern fn PyDict_AddWatcher(callback: PyDict_WatchCallback) c_int;
pub extern fn PyDict_ClearWatcher(watcher_id: c_int) c_int;
pub extern fn PyDict_Watch(watcher_id: c_int, dict: ?*PyObject) c_int;
pub extern fn PyDict_Unwatch(watcher_id: c_int, dict: ?*PyObject) c_int;
pub const struct__odictobject = opaque {};
pub const PyODictObject = struct__odictobject;
pub extern var PyODict_Type: PyTypeObject;
pub extern var PyODictIter_Type: PyTypeObject;
pub extern var PyODictKeys_Type: PyTypeObject;
pub extern var PyODictItems_Type: PyTypeObject;
pub extern var PyODictValues_Type: PyTypeObject;
pub extern fn PyODict_New() ?*PyObject;
pub extern fn PyODict_SetItem(od: ?*PyObject, key: ?*PyObject, item: ?*PyObject) c_int;
pub extern fn PyODict_DelItem(od: ?*PyObject, key: ?*PyObject) c_int;
pub extern var PyEnum_Type: PyTypeObject;
pub extern var PyReversed_Type: PyTypeObject;
pub extern var PySet_Type: PyTypeObject;
pub extern var PyFrozenSet_Type: PyTypeObject;
pub extern var PySetIter_Type: PyTypeObject;
pub extern fn PySet_New(?*PyObject) ?*PyObject;
pub extern fn PyFrozenSet_New(?*PyObject) ?*PyObject;
pub extern fn PySet_Add(set: ?*PyObject, key: ?*PyObject) c_int;
pub extern fn PySet_Clear(set: ?*PyObject) c_int;
pub extern fn PySet_Contains(anyset: ?*PyObject, key: ?*PyObject) c_int;
pub extern fn PySet_Discard(set: ?*PyObject, key: ?*PyObject) c_int;
pub extern fn PySet_Pop(set: ?*PyObject) ?*PyObject;
pub extern fn PySet_Size(anyset: ?*PyObject) Py_ssize_t;
pub const setentry = extern struct {
    key: ?*PyObject = std.mem.zeroes(?*PyObject),
    hash: Py_hash_t = std.mem.zeroes(Py_hash_t),
};
pub const PySetObject = extern struct {
    ob_base: PyObject = std.mem.zeroes(PyObject),
    fill: Py_ssize_t = std.mem.zeroes(Py_ssize_t),
    used: Py_ssize_t = std.mem.zeroes(Py_ssize_t),
    mask: Py_ssize_t = std.mem.zeroes(Py_ssize_t),
    table: ?*setentry = std.mem.zeroes(?*setentry),
    hash: Py_hash_t = std.mem.zeroes(Py_hash_t),
    finger: Py_ssize_t = std.mem.zeroes(Py_ssize_t),
    smalltable: [8]setentry = std.mem.zeroes([8]setentry),
    weakreflist: ?*PyObject = std.mem.zeroes(?*PyObject),
};
pub fn PySet_GET_SIZE(arg_so: ?*PyObject) callconv(.c) Py_ssize_t {
    var so = arg_so;
    _ = &so;
    return (blk: {
        _ = blk_1: {
            _ = @sizeOf(c_int);
            break :blk_1 blk_2: {
                break :blk_2 if ((((Py_IS_TYPE(so, &PySet_Type) != 0) or (Py_IS_TYPE(so, &PyFrozenSet_Type) != 0)) or (PyType_IsSubtype(Py_TYPE(so), &PySet_Type) != 0)) or (PyType_IsSubtype(Py_TYPE(so), &PyFrozenSet_Type) != 0)) {} else {
                    __assert_fail("PyAnySet_Check(so)", "/usr/include/python3.13/cpython/setobject.h", @as(c_uint, @bitCast(@as(c_int, 68))), "Py_ssize_t PySet_GET_SIZE(PyObject *)");
                };
            };
        };
        break :blk @as(?*PySetObject, @ptrCast(@alignCast(so)));
    }).*.used;
}
pub extern var PyCFunction_Type: PyTypeObject;
pub const PyCFunctionFast = ?*const fn (?*PyObject, ?*const ?*PyObject, Py_ssize_t) callconv(.c) ?*PyObject;
pub const PyCFunctionWithKeywords = ?*const fn (?*PyObject, ?*PyObject, ?*PyObject) callconv(.c) ?*PyObject;
pub const PyCFunctionFastWithKeywords = ?*const fn (?*PyObject, ?*const ?*PyObject, Py_ssize_t, ?*PyObject) callconv(.c) ?*PyObject;
pub const PyCMethod = ?*const fn (?*PyObject, ?*PyTypeObject, ?*const ?*PyObject, usize, ?*PyObject) callconv(.c) ?*PyObject;
pub const _PyCFunctionFast = PyCFunctionFast;
pub const _PyCFunctionFastWithKeywords = PyCFunctionFastWithKeywords;
pub extern fn PyCFunction_GetFunction(?*PyObject) PyCFunction;
pub extern fn PyCFunction_GetSelf(?*PyObject) ?*PyObject;
pub extern fn PyCFunction_GetFlags(?*PyObject) c_int;
pub extern fn PyCFunction_New(?*PyMethodDef, ?*PyObject) ?*PyObject;
pub extern fn PyCFunction_NewEx(?*PyMethodDef, ?*PyObject, ?*PyObject) ?*PyObject;
pub extern fn PyCMethod_New(?*PyMethodDef, ?*PyObject, ?*PyObject, ?*PyTypeObject) ?*PyObject;
pub const PyCFunctionObject = extern struct {
    ob_base: PyObject = std.mem.zeroes(PyObject),
    m_ml: ?*PyMethodDef = std.mem.zeroes(?*PyMethodDef),
    m_self: ?*PyObject = std.mem.zeroes(?*PyObject),
    m_module: ?*PyObject = std.mem.zeroes(?*PyObject),
    m_weakreflist: ?*PyObject = std.mem.zeroes(?*PyObject),
    vectorcall: vectorcallfunc = std.mem.zeroes(vectorcallfunc),
};
pub const PyCMethodObject = extern struct {
    func: PyCFunctionObject = std.mem.zeroes(PyCFunctionObject),
    mm_class: ?*PyTypeObject = std.mem.zeroes(?*PyTypeObject),
};
pub extern var PyCMethod_Type: PyTypeObject;
pub fn PyCFunction_GET_FUNCTION(arg_func: ?*PyObject) callconv(.c) PyCFunction {
    var func = arg_func;
    _ = &func;
    return (blk: {
        _ = blk_1: {
            _ = @sizeOf(c_int);
            break :blk_1 blk_2: {
                break :blk_2 if (PyObject_TypeCheck(func, &PyCFunction_Type) != 0) {} else {
                    __assert_fail("PyCFunction_Check(func)", "/usr/include/python3.13/cpython/methodobject.h", @as(c_uint, @bitCast(@as(c_int, 41))), "PyCFunction PyCFunction_GET_FUNCTION(PyObject *)");
                };
            };
        };
        break :blk @as(?*PyCFunctionObject, @ptrCast(@alignCast(func)));
    }).*.m_ml.*.ml_meth;
}
pub fn PyCFunction_GET_SELF(arg_func_obj: ?*PyObject) callconv(.c) ?*PyObject {
    var func_obj = arg_func_obj;
    _ = &func_obj;
    var func: ?*PyCFunctionObject = blk: {
        _ = blk_1: {
            _ = @sizeOf(c_int);
            break :blk_1 blk_2: {
                break :blk_2 if (PyObject_TypeCheck(func_obj, &PyCFunction_Type) != 0) {} else {
                    __assert_fail("PyCFunction_Check(func_obj)", "/usr/include/python3.13/cpython/methodobject.h", @as(c_uint, @bitCast(@as(c_int, 46))), "PyObject *PyCFunction_GET_SELF(PyObject *)");
                };
            };
        };
        break :blk @as(?*PyCFunctionObject, @ptrCast(@alignCast(func_obj)));
    };
    _ = &func;
    if ((func.*.m_ml.*.ml_flags & @as(c_int, 32)) != 0) {
        return null;
    }
    return func.*.m_self;
}
pub fn PyCFunction_GET_FLAGS(arg_func: ?*PyObject) callconv(.c) c_int {
    var func = arg_func;
    _ = &func;
    return (blk: {
        _ = blk_1: {
            _ = @sizeOf(c_int);
            break :blk_1 blk_2: {
                break :blk_2 if (PyObject_TypeCheck(func, &PyCFunction_Type) != 0) {} else {
                    __assert_fail("PyCFunction_Check(func)", "/usr/include/python3.13/cpython/methodobject.h", @as(c_uint, @bitCast(@as(c_int, 55))), "int PyCFunction_GET_FLAGS(PyObject *)");
                };
            };
        };
        break :blk @as(?*PyCFunctionObject, @ptrCast(@alignCast(func)));
    }).*.m_ml.*.ml_flags;
}
pub fn PyCFunction_GET_CLASS(arg_func_obj: ?*PyObject) callconv(.c) ?*PyTypeObject {
    var func_obj = arg_func_obj;
    _ = &func_obj;
    var func: ?*PyCFunctionObject = blk: {
        _ = blk_1: {
            _ = @sizeOf(c_int);
            break :blk_1 blk_2: {
                break :blk_2 if (PyObject_TypeCheck(func_obj, &PyCFunction_Type) != 0) {} else {
                    __assert_fail("PyCFunction_Check(func_obj)", "/usr/include/python3.13/cpython/methodobject.h", @as(c_uint, @bitCast(@as(c_int, 60))), "PyTypeObject *PyCFunction_GET_CLASS(PyObject *)");
                };
            };
        };
        break :blk @as(?*PyCFunctionObject, @ptrCast(@alignCast(func_obj)));
    };
    _ = &func;
    if ((func.*.m_ml.*.ml_flags & @as(c_int, 512)) != 0) {
        return (blk: {
            _ = blk_1: {
                _ = @sizeOf(c_int);
                break :blk_1 blk_2: {
                    break :blk_2 if (PyObject_TypeCheck(@as(?*PyObject, @ptrCast(@alignCast(func))), &PyCMethod_Type) != 0) {} else {
                        __assert_fail("PyCMethod_Check(func)", "/usr/include/python3.13/cpython/methodobject.h", @as(c_uint, @bitCast(@as(c_int, 62))), "PyTypeObject *PyCFunction_GET_CLASS(PyObject *)");
                    };
                };
            };
            break :blk @as(?*PyCMethodObject, @ptrCast(@alignCast(func)));
        }).*.mm_class;
    }
    return null;
}
pub extern var PyModule_Type: PyTypeObject;
pub extern fn PyModule_NewObject(name: ?*PyObject) ?*PyObject;
pub extern fn PyModule_New(name: ?*const u8) ?*PyObject;
pub extern fn PyModule_GetDict(?*PyObject) ?*PyObject;
pub extern fn PyModule_GetNameObject(?*PyObject) ?*PyObject;
pub extern fn PyModule_GetName(?*PyObject) ?*const u8;
pub extern fn PyModule_GetFilename(?*PyObject) ?*const u8;
pub extern fn PyModule_GetFilenameObject(?*PyObject) ?*PyObject;
pub extern fn PyModule_GetDef(?*PyObject) ?*PyModuleDef;
pub extern fn PyModule_GetState(?*PyObject) ?*anyopaque;
pub extern fn PyModuleDef_Init(?*PyModuleDef) ?*PyObject;
pub extern var PyModuleDef_Type: PyTypeObject;
pub const struct__PyMonitoringState = extern struct {
    active: u8 = std.mem.zeroes(u8),
    @"opaque": u8 = std.mem.zeroes(u8),
};
pub const PyMonitoringState = struct__PyMonitoringState;
pub extern fn PyMonitoring_EnterScope(state_array: ?*PyMonitoringState, version: ?*u64, event_types: ?*const u8, length: Py_ssize_t) c_int;
pub extern fn PyMonitoring_ExitScope() c_int;
pub extern fn _PyMonitoring_FirePyStartEvent(state: ?*PyMonitoringState, codelike: ?*PyObject, offset: i32) c_int;
pub extern fn _PyMonitoring_FirePyResumeEvent(state: ?*PyMonitoringState, codelike: ?*PyObject, offset: i32) c_int;
pub extern fn _PyMonitoring_FirePyReturnEvent(state: ?*PyMonitoringState, codelike: ?*PyObject, offset: i32, retval: ?*PyObject) c_int;
pub extern fn _PyMonitoring_FirePyYieldEvent(state: ?*PyMonitoringState, codelike: ?*PyObject, offset: i32, retval: ?*PyObject) c_int;
pub extern fn _PyMonitoring_FireCallEvent(state: ?*PyMonitoringState, codelike: ?*PyObject, offset: i32, callable: ?*PyObject, arg0: ?*PyObject) c_int;
pub extern fn _PyMonitoring_FireLineEvent(state: ?*PyMonitoringState, codelike: ?*PyObject, offset: i32, lineno: c_int) c_int;
pub extern fn _PyMonitoring_FireJumpEvent(state: ?*PyMonitoringState, codelike: ?*PyObject, offset: i32, target_offset: ?*PyObject) c_int;
pub extern fn _PyMonitoring_FireBranchEvent(state: ?*PyMonitoringState, codelike: ?*PyObject, offset: i32, target_offset: ?*PyObject) c_int;
pub extern fn _PyMonitoring_FireCReturnEvent(state: ?*PyMonitoringState, codelike: ?*PyObject, offset: i32, retval: ?*PyObject) c_int;
pub extern fn _PyMonitoring_FirePyThrowEvent(state: ?*PyMonitoringState, codelike: ?*PyObject, offset: i32) c_int;
pub extern fn _PyMonitoring_FireRaiseEvent(state: ?*PyMonitoringState, codelike: ?*PyObject, offset: i32) c_int;
pub extern fn _PyMonitoring_FireReraiseEvent(state: ?*PyMonitoringState, codelike: ?*PyObject, offset: i32) c_int;
pub extern fn _PyMonitoring_FireExceptionHandledEvent(state: ?*PyMonitoringState, codelike: ?*PyObject, offset: i32) c_int;
pub extern fn _PyMonitoring_FireCRaiseEvent(state: ?*PyMonitoringState, codelike: ?*PyObject, offset: i32) c_int;
pub extern fn _PyMonitoring_FirePyUnwindEvent(state: ?*PyMonitoringState, codelike: ?*PyObject, offset: i32) c_int;
pub extern fn _PyMonitoring_FireStopIterationEvent(state: ?*PyMonitoringState, codelike: ?*PyObject, offset: i32, value: ?*PyObject) c_int;
pub fn PyMonitoring_FirePyStartEvent(arg_state: ?*PyMonitoringState, arg_codelike: ?*PyObject, arg_offset: i32) callconv(.c) c_int {
    var state = arg_state;
    _ = &state;
    var codelike = arg_codelike;
    _ = &codelike;
    var offset = arg_offset;
    _ = &offset;
    if (state.*.active != 0) {
        return _PyMonitoring_FirePyStartEvent(state, codelike, offset);
    } else {
        return 0;
    }
    return 0;
}
pub fn PyMonitoring_FirePyResumeEvent(arg_state: ?*PyMonitoringState, arg_codelike: ?*PyObject, arg_offset: i32) callconv(.c) c_int {
    var state = arg_state;
    _ = &state;
    var codelike = arg_codelike;
    _ = &codelike;
    var offset = arg_offset;
    _ = &offset;
    if (state.*.active != 0) {
        return _PyMonitoring_FirePyResumeEvent(state, codelike, offset);
    } else {
        return 0;
    }
    return 0;
}
pub fn PyMonitoring_FirePyReturnEvent(arg_state: ?*PyMonitoringState, arg_codelike: ?*PyObject, arg_offset: i32, arg_retval: ?*PyObject) callconv(.c) c_int {
    var state = arg_state;
    _ = &state;
    var codelike = arg_codelike;
    _ = &codelike;
    var offset = arg_offset;
    _ = &offset;
    var retval = arg_retval;
    _ = &retval;
    if (state.*.active != 0) {
        return _PyMonitoring_FirePyReturnEvent(state, codelike, offset, retval);
    } else {
        return 0;
    }
    return 0;
}
pub fn PyMonitoring_FirePyYieldEvent(arg_state: ?*PyMonitoringState, arg_codelike: ?*PyObject, arg_offset: i32, arg_retval: ?*PyObject) callconv(.c) c_int {
    var state = arg_state;
    _ = &state;
    var codelike = arg_codelike;
    _ = &codelike;
    var offset = arg_offset;
    _ = &offset;
    var retval = arg_retval;
    _ = &retval;
    if (state.*.active != 0) {
        return _PyMonitoring_FirePyYieldEvent(state, codelike, offset, retval);
    } else {
        return 0;
    }
    return 0;
}
pub fn PyMonitoring_FireCallEvent(arg_state: ?*PyMonitoringState, arg_codelike: ?*PyObject, arg_offset: i32, arg_callable: ?*PyObject, arg_arg0: ?*PyObject) callconv(.c) c_int {
    var state = arg_state;
    _ = &state;
    var codelike = arg_codelike;
    _ = &codelike;
    var offset = arg_offset;
    _ = &offset;
    var callable = arg_callable;
    _ = &callable;
    var arg0 = arg_arg0;
    _ = &arg0;
    if (state.*.active != 0) {
        return _PyMonitoring_FireCallEvent(state, codelike, offset, callable, arg0);
    } else {
        return 0;
    }
    return 0;
}
pub fn PyMonitoring_FireLineEvent(arg_state: ?*PyMonitoringState, arg_codelike: ?*PyObject, arg_offset: i32, arg_lineno: c_int) callconv(.c) c_int {
    var state = arg_state;
    _ = &state;
    var codelike = arg_codelike;
    _ = &codelike;
    var offset = arg_offset;
    _ = &offset;
    var lineno = arg_lineno;
    _ = &lineno;
    if (state.*.active != 0) {
        return _PyMonitoring_FireLineEvent(state, codelike, offset, lineno);
    } else {
        return 0;
    }
    return 0;
}
pub fn PyMonitoring_FireJumpEvent(arg_state: ?*PyMonitoringState, arg_codelike: ?*PyObject, arg_offset: i32, arg_target_offset: ?*PyObject) callconv(.c) c_int {
    var state = arg_state;
    _ = &state;
    var codelike = arg_codelike;
    _ = &codelike;
    var offset = arg_offset;
    _ = &offset;
    var target_offset = arg_target_offset;
    _ = &target_offset;
    if (state.*.active != 0) {
        return _PyMonitoring_FireJumpEvent(state, codelike, offset, target_offset);
    } else {
        return 0;
    }
    return 0;
}
pub fn PyMonitoring_FireBranchEvent(arg_state: ?*PyMonitoringState, arg_codelike: ?*PyObject, arg_offset: i32, arg_target_offset: ?*PyObject) callconv(.c) c_int {
    var state = arg_state;
    _ = &state;
    var codelike = arg_codelike;
    _ = &codelike;
    var offset = arg_offset;
    _ = &offset;
    var target_offset = arg_target_offset;
    _ = &target_offset;
    if (state.*.active != 0) {
        return _PyMonitoring_FireBranchEvent(state, codelike, offset, target_offset);
    } else {
        return 0;
    }
    return 0;
}
pub fn PyMonitoring_FireCReturnEvent(arg_state: ?*PyMonitoringState, arg_codelike: ?*PyObject, arg_offset: i32, arg_retval: ?*PyObject) callconv(.c) c_int {
    var state = arg_state;
    _ = &state;
    var codelike = arg_codelike;
    _ = &codelike;
    var offset = arg_offset;
    _ = &offset;
    var retval = arg_retval;
    _ = &retval;
    if (state.*.active != 0) {
        return _PyMonitoring_FireCReturnEvent(state, codelike, offset, retval);
    } else {
        return 0;
    }
    return 0;
}
pub fn PyMonitoring_FirePyThrowEvent(arg_state: ?*PyMonitoringState, arg_codelike: ?*PyObject, arg_offset: i32) callconv(.c) c_int {
    var state = arg_state;
    _ = &state;
    var codelike = arg_codelike;
    _ = &codelike;
    var offset = arg_offset;
    _ = &offset;
    if (state.*.active != 0) {
        return _PyMonitoring_FirePyThrowEvent(state, codelike, offset);
    } else {
        return 0;
    }
    return 0;
}
pub fn PyMonitoring_FireRaiseEvent(arg_state: ?*PyMonitoringState, arg_codelike: ?*PyObject, arg_offset: i32) callconv(.c) c_int {
    var state = arg_state;
    _ = &state;
    var codelike = arg_codelike;
    _ = &codelike;
    var offset = arg_offset;
    _ = &offset;
    if (state.*.active != 0) {
        return _PyMonitoring_FireRaiseEvent(state, codelike, offset);
    } else {
        return 0;
    }
    return 0;
}
pub fn PyMonitoring_FireReraiseEvent(arg_state: ?*PyMonitoringState, arg_codelike: ?*PyObject, arg_offset: i32) callconv(.c) c_int {
    var state = arg_state;
    _ = &state;
    var codelike = arg_codelike;
    _ = &codelike;
    var offset = arg_offset;
    _ = &offset;
    if (state.*.active != 0) {
        return _PyMonitoring_FireReraiseEvent(state, codelike, offset);
    } else {
        return 0;
    }
    return 0;
}
pub fn PyMonitoring_FireExceptionHandledEvent(arg_state: ?*PyMonitoringState, arg_codelike: ?*PyObject, arg_offset: i32) callconv(.c) c_int {
    var state = arg_state;
    _ = &state;
    var codelike = arg_codelike;
    _ = &codelike;
    var offset = arg_offset;
    _ = &offset;
    if (state.*.active != 0) {
        return _PyMonitoring_FireExceptionHandledEvent(state, codelike, offset);
    } else {
        return 0;
    }
    return 0;
}
pub fn PyMonitoring_FireCRaiseEvent(arg_state: ?*PyMonitoringState, arg_codelike: ?*PyObject, arg_offset: i32) callconv(.c) c_int {
    var state = arg_state;
    _ = &state;
    var codelike = arg_codelike;
    _ = &codelike;
    var offset = arg_offset;
    _ = &offset;
    if (state.*.active != 0) {
        return _PyMonitoring_FireCRaiseEvent(state, codelike, offset);
    } else {
        return 0;
    }
    return 0;
}
pub fn PyMonitoring_FirePyUnwindEvent(arg_state: ?*PyMonitoringState, arg_codelike: ?*PyObject, arg_offset: i32) callconv(.c) c_int {
    var state = arg_state;
    _ = &state;
    var codelike = arg_codelike;
    _ = &codelike;
    var offset = arg_offset;
    _ = &offset;
    if (state.*.active != 0) {
        return _PyMonitoring_FirePyUnwindEvent(state, codelike, offset);
    } else {
        return 0;
    }
    return 0;
}
pub fn PyMonitoring_FireStopIterationEvent(arg_state: ?*PyMonitoringState, arg_codelike: ?*PyObject, arg_offset: i32, arg_value: ?*PyObject) callconv(.c) c_int {
    var state = arg_state;
    _ = &state;
    var codelike = arg_codelike;
    _ = &codelike;
    var offset = arg_offset;
    _ = &offset;
    var value = arg_value;
    _ = &value;
    if (state.*.active != 0) {
        return _PyMonitoring_FireStopIterationEvent(state, codelike, offset, value);
    } else {
        return 0;
    }
    return 0;
}
pub const PyFrameConstructor = extern struct {
    fc_globals: ?*PyObject = std.mem.zeroes(?*PyObject),
    fc_builtins: ?*PyObject = std.mem.zeroes(?*PyObject),
    fc_name: ?*PyObject = std.mem.zeroes(?*PyObject),
    fc_qualname: ?*PyObject = std.mem.zeroes(?*PyObject),
    fc_code: ?*PyObject = std.mem.zeroes(?*PyObject),
    fc_defaults: ?*PyObject = std.mem.zeroes(?*PyObject),
    fc_kwdefaults: ?*PyObject = std.mem.zeroes(?*PyObject),
    fc_closure: ?*PyObject = std.mem.zeroes(?*PyObject),
};
pub const PyFunctionObject = extern struct {
    ob_base: PyObject = std.mem.zeroes(PyObject),
    func_globals: ?*PyObject = std.mem.zeroes(?*PyObject),
    func_builtins: ?*PyObject = std.mem.zeroes(?*PyObject),
    func_name: ?*PyObject = std.mem.zeroes(?*PyObject),
    func_qualname: ?*PyObject = std.mem.zeroes(?*PyObject),
    func_code: ?*PyObject = std.mem.zeroes(?*PyObject),
    func_defaults: ?*PyObject = std.mem.zeroes(?*PyObject),
    func_kwdefaults: ?*PyObject = std.mem.zeroes(?*PyObject),
    func_closure: ?*PyObject = std.mem.zeroes(?*PyObject),
    func_doc: ?*PyObject = std.mem.zeroes(?*PyObject),
    func_dict: ?*PyObject = std.mem.zeroes(?*PyObject),
    func_weakreflist: ?*PyObject = std.mem.zeroes(?*PyObject),
    func_module: ?*PyObject = std.mem.zeroes(?*PyObject),
    func_annotations: ?*PyObject = std.mem.zeroes(?*PyObject),
    func_typeparams: ?*PyObject = std.mem.zeroes(?*PyObject),
    vectorcall: vectorcallfunc = std.mem.zeroes(vectorcallfunc),
    func_version: u32 = std.mem.zeroes(u32),
};
pub extern var PyFunction_Type: PyTypeObject;
pub extern fn PyFunction_New(?*PyObject, ?*PyObject) ?*PyObject;
pub extern fn PyFunction_NewWithQualName(?*PyObject, ?*PyObject, ?*PyObject) ?*PyObject;
pub extern fn PyFunction_GetCode(?*PyObject) ?*PyObject;
pub extern fn PyFunction_GetGlobals(?*PyObject) ?*PyObject;
pub extern fn PyFunction_GetModule(?*PyObject) ?*PyObject;
pub extern fn PyFunction_GetDefaults(?*PyObject) ?*PyObject;
pub extern fn PyFunction_SetDefaults(?*PyObject, ?*PyObject) c_int;
pub extern fn PyFunction_SetVectorcall(?*PyFunctionObject, vectorcallfunc) void;
pub extern fn PyFunction_GetKwDefaults(?*PyObject) ?*PyObject;
pub extern fn PyFunction_SetKwDefaults(?*PyObject, ?*PyObject) c_int;
pub extern fn PyFunction_GetClosure(?*PyObject) ?*PyObject;
pub extern fn PyFunction_SetClosure(?*PyObject, ?*PyObject) c_int;
pub extern fn PyFunction_GetAnnotations(?*PyObject) ?*PyObject;
pub extern fn PyFunction_SetAnnotations(?*PyObject, ?*PyObject) c_int;
pub fn PyFunction_GET_CODE(arg_func: ?*PyObject) callconv(.c) ?*PyObject {
    var func = arg_func;
    _ = &func;
    return (blk: {
        _ = blk_1: {
            _ = @sizeOf(c_int);
            break :blk_1 blk_2: {
                break :blk_2 if (Py_IS_TYPE(func, &PyFunction_Type) != 0) {} else {
                    __assert_fail("PyFunction_Check(func)", "/usr/include/python3.13/cpython/funcobject.h", @as(c_uint, @bitCast(@as(c_int, 90))), "PyObject *PyFunction_GET_CODE(PyObject *)");
                };
            };
        };
        break :blk @as(?*PyFunctionObject, @ptrCast(@alignCast(func)));
    }).*.func_code;
}
pub fn PyFunction_GET_GLOBALS(arg_func: ?*PyObject) callconv(.c) ?*PyObject {
    var func = arg_func;
    _ = &func;
    return (blk: {
        _ = blk_1: {
            _ = @sizeOf(c_int);
            break :blk_1 blk_2: {
                break :blk_2 if (Py_IS_TYPE(func, &PyFunction_Type) != 0) {} else {
                    __assert_fail("PyFunction_Check(func)", "/usr/include/python3.13/cpython/funcobject.h", @as(c_uint, @bitCast(@as(c_int, 95))), "PyObject *PyFunction_GET_GLOBALS(PyObject *)");
                };
            };
        };
        break :blk @as(?*PyFunctionObject, @ptrCast(@alignCast(func)));
    }).*.func_globals;
}
pub fn PyFunction_GET_MODULE(arg_func: ?*PyObject) callconv(.c) ?*PyObject {
    var func = arg_func;
    _ = &func;
    return (blk: {
        _ = blk_1: {
            _ = @sizeOf(c_int);
            break :blk_1 blk_2: {
                break :blk_2 if (Py_IS_TYPE(func, &PyFunction_Type) != 0) {} else {
                    __assert_fail("PyFunction_Check(func)", "/usr/include/python3.13/cpython/funcobject.h", @as(c_uint, @bitCast(@as(c_int, 100))), "PyObject *PyFunction_GET_MODULE(PyObject *)");
                };
            };
        };
        break :blk @as(?*PyFunctionObject, @ptrCast(@alignCast(func)));
    }).*.func_module;
}
pub fn PyFunction_GET_DEFAULTS(arg_func: ?*PyObject) callconv(.c) ?*PyObject {
    var func = arg_func;
    _ = &func;
    return (blk: {
        _ = blk_1: {
            _ = @sizeOf(c_int);
            break :blk_1 blk_2: {
                break :blk_2 if (Py_IS_TYPE(func, &PyFunction_Type) != 0) {} else {
                    __assert_fail("PyFunction_Check(func)", "/usr/include/python3.13/cpython/funcobject.h", @as(c_uint, @bitCast(@as(c_int, 105))), "PyObject *PyFunction_GET_DEFAULTS(PyObject *)");
                };
            };
        };
        break :blk @as(?*PyFunctionObject, @ptrCast(@alignCast(func)));
    }).*.func_defaults;
}
pub fn PyFunction_GET_KW_DEFAULTS(arg_func: ?*PyObject) callconv(.c) ?*PyObject {
    var func = arg_func;
    _ = &func;
    return (blk: {
        _ = blk_1: {
            _ = @sizeOf(c_int);
            break :blk_1 blk_2: {
                break :blk_2 if (Py_IS_TYPE(func, &PyFunction_Type) != 0) {} else {
                    __assert_fail("PyFunction_Check(func)", "/usr/include/python3.13/cpython/funcobject.h", @as(c_uint, @bitCast(@as(c_int, 110))), "PyObject *PyFunction_GET_KW_DEFAULTS(PyObject *)");
                };
            };
        };
        break :blk @as(?*PyFunctionObject, @ptrCast(@alignCast(func)));
    }).*.func_kwdefaults;
}
pub fn PyFunction_GET_CLOSURE(arg_func: ?*PyObject) callconv(.c) ?*PyObject {
    var func = arg_func;
    _ = &func;
    return (blk: {
        _ = blk_1: {
            _ = @sizeOf(c_int);
            break :blk_1 blk_2: {
                break :blk_2 if (Py_IS_TYPE(func, &PyFunction_Type) != 0) {} else {
                    __assert_fail("PyFunction_Check(func)", "/usr/include/python3.13/cpython/funcobject.h", @as(c_uint, @bitCast(@as(c_int, 115))), "PyObject *PyFunction_GET_CLOSURE(PyObject *)");
                };
            };
        };
        break :blk @as(?*PyFunctionObject, @ptrCast(@alignCast(func)));
    }).*.func_closure;
}
pub fn PyFunction_GET_ANNOTATIONS(arg_func: ?*PyObject) callconv(.c) ?*PyObject {
    var func = arg_func;
    _ = &func;
    return (blk: {
        _ = blk_1: {
            _ = @sizeOf(c_int);
            break :blk_1 blk_2: {
                break :blk_2 if (Py_IS_TYPE(func, &PyFunction_Type) != 0) {} else {
                    __assert_fail("PyFunction_Check(func)", "/usr/include/python3.13/cpython/funcobject.h", @as(c_uint, @bitCast(@as(c_int, 120))), "PyObject *PyFunction_GET_ANNOTATIONS(PyObject *)");
                };
            };
        };
        break :blk @as(?*PyFunctionObject, @ptrCast(@alignCast(func)));
    }).*.func_annotations;
}
pub extern var PyClassMethod_Type: PyTypeObject;
pub extern var PyStaticMethod_Type: PyTypeObject;
pub extern fn PyClassMethod_New(?*PyObject) ?*PyObject;
pub extern fn PyStaticMethod_New(?*PyObject) ?*PyObject;
pub const PyFunction_EVENT_CREATE: c_int = 0;
pub const PyFunction_EVENT_DESTROY: c_int = 1;
pub const PyFunction_EVENT_MODIFY_CODE: c_int = 2;
pub const PyFunction_EVENT_MODIFY_DEFAULTS: c_int = 3;
pub const PyFunction_EVENT_MODIFY_KWDEFAULTS: c_int = 4;
pub const PyFunction_WatchEvent = c_uint;
pub const PyFunction_WatchCallback = ?*const fn (PyFunction_WatchEvent, ?*PyFunctionObject, ?*PyObject) callconv(.c) c_int;
pub extern fn PyFunction_AddWatcher(callback: PyFunction_WatchCallback) c_int;
pub extern fn PyFunction_ClearWatcher(watcher_id: c_int) c_int;
pub const PyMethodObject = extern struct {
    ob_base: PyObject = std.mem.zeroes(PyObject),
    im_func: ?*PyObject = std.mem.zeroes(?*PyObject),
    im_self: ?*PyObject = std.mem.zeroes(?*PyObject),
    im_weakreflist: ?*PyObject = std.mem.zeroes(?*PyObject),
    vectorcall: vectorcallfunc = std.mem.zeroes(vectorcallfunc),
};
pub extern var PyMethod_Type: PyTypeObject;
pub extern fn PyMethod_New(?*PyObject, ?*PyObject) ?*PyObject;
pub extern fn PyMethod_Function(?*PyObject) ?*PyObject;
pub extern fn PyMethod_Self(?*PyObject) ?*PyObject;
pub fn PyMethod_GET_FUNCTION(arg_meth: ?*PyObject) callconv(.c) ?*PyObject {
    var meth = arg_meth;
    _ = &meth;
    return (blk: {
        _ = blk_1: {
            _ = @sizeOf(c_int);
            break :blk_1 blk_2: {
                break :blk_2 if (Py_IS_TYPE(meth, &PyMethod_Type) != 0) {} else {
                    __assert_fail("PyMethod_Check(meth)", "/usr/include/python3.13/cpython/classobject.h", @as(c_uint, @bitCast(@as(c_int, 35))), "PyObject *PyMethod_GET_FUNCTION(PyObject *)");
                };
            };
        };
        break :blk @as(?*PyMethodObject, @ptrCast(@alignCast(meth)));
    }).*.im_func;
}
pub fn PyMethod_GET_SELF(arg_meth: ?*PyObject) callconv(.c) ?*PyObject {
    var meth = arg_meth;
    _ = &meth;
    return (blk: {
        _ = blk_1: {
            _ = @sizeOf(c_int);
            break :blk_1 blk_2: {
                break :blk_2 if (Py_IS_TYPE(meth, &PyMethod_Type) != 0) {} else {
                    __assert_fail("PyMethod_Check(meth)", "/usr/include/python3.13/cpython/classobject.h", @as(c_uint, @bitCast(@as(c_int, 40))), "PyObject *PyMethod_GET_SELF(PyObject *)");
                };
            };
        };
        break :blk @as(?*PyMethodObject, @ptrCast(@alignCast(meth)));
    }).*.im_self;
}
pub const PyInstanceMethodObject = extern struct {
    ob_base: PyObject = std.mem.zeroes(PyObject),
    func: ?*PyObject = std.mem.zeroes(?*PyObject),
};
pub extern var PyInstanceMethod_Type: PyTypeObject;
pub extern fn PyInstanceMethod_New(?*PyObject) ?*PyObject;
pub extern fn PyInstanceMethod_Function(?*PyObject) ?*PyObject;
pub fn PyInstanceMethod_GET_FUNCTION(arg_meth: ?*PyObject) callconv(.c) ?*PyObject {
    var meth = arg_meth;
    _ = &meth;
    return (blk: {
        _ = blk_1: {
            _ = @sizeOf(c_int);
            break :blk_1 blk_2: {
                break :blk_2 if (Py_IS_TYPE(meth, &PyInstanceMethod_Type) != 0) {} else {
                    __assert_fail("PyInstanceMethod_Check(meth)", "/usr/include/python3.13/cpython/classobject.h", @as(c_uint, @bitCast(@as(c_int, 63))), "PyObject *PyInstanceMethod_GET_FUNCTION(PyObject *)");
                };
            };
        };
        break :blk @as(?*PyInstanceMethodObject, @ptrCast(@alignCast(meth)));
    }).*.func;
}
pub extern fn PyFile_FromFd(c_int, ?*const u8, ?*const u8, c_int, ?*const u8, ?*const u8, ?*const u8, c_int) ?*PyObject;
pub extern fn PyFile_GetLine(?*PyObject, c_int) ?*PyObject;
pub extern fn PyFile_WriteObject(?*PyObject, ?*PyObject, c_int) c_int;
pub extern fn PyFile_WriteString(?*const u8, ?*PyObject) c_int;
pub extern fn PyObject_AsFileDescriptor(?*PyObject) c_int;
pub extern var Py_FileSystemDefaultEncoding: ?*const u8;
pub extern var Py_FileSystemDefaultEncodeErrors: ?*const u8;
pub extern var Py_HasFileSystemDefaultEncoding: c_int;
pub extern var Py_UTF8Mode: c_int;
pub extern fn Py_UniversalNewlineFgets(?*u8, c_int, ?*FILE, ?*PyObject) ?*u8;
pub extern fn PyFile_NewStdPrinter(c_int) ?*PyObject;
pub extern var PyStdPrinter_Type: PyTypeObject;
pub const Py_OpenCodeHookFunction = ?*const fn (?*PyObject, ?*anyopaque) callconv(.c) ?*PyObject;
pub extern fn PyFile_OpenCode(utf8path: ?*const u8) ?*PyObject;
pub extern fn PyFile_OpenCodeObject(path: ?*PyObject) ?*PyObject;
pub extern fn PyFile_SetOpenCodeHook(hook: Py_OpenCodeHookFunction, userData: ?*anyopaque) c_int;
pub extern var PyCapsule_Type: PyTypeObject;
pub const PyCapsule_Destructor = ?*const fn (?*PyObject) callconv(.c) void;
pub extern fn PyCapsule_New(pointer: ?*anyopaque, name: ?*const u8, destructor: PyCapsule_Destructor) ?*PyObject;
pub extern fn PyCapsule_GetPointer(capsule: ?*PyObject, name: ?*const u8) ?*anyopaque;
pub extern fn PyCapsule_GetDestructor(capsule: ?*PyObject) PyCapsule_Destructor;
pub extern fn PyCapsule_GetName(capsule: ?*PyObject) ?*const u8;
pub extern fn PyCapsule_GetContext(capsule: ?*PyObject) ?*anyopaque;
pub extern fn PyCapsule_IsValid(capsule: ?*PyObject, name: ?*const u8) c_int;
pub extern fn PyCapsule_SetPointer(capsule: ?*PyObject, pointer: ?*anyopaque) c_int;
pub extern fn PyCapsule_SetDestructor(capsule: ?*PyObject, destructor: PyCapsule_Destructor) c_int;
pub extern fn PyCapsule_SetName(capsule: ?*PyObject, name: ?*const u8) c_int;
pub extern fn PyCapsule_SetContext(capsule: ?*PyObject, context: ?*anyopaque) c_int;
pub extern fn PyCapsule_Import(name: ?*const u8, no_block: c_int) ?*anyopaque;
pub const struct__Py_LocalMonitors = extern struct {
    tools: [10]u8 = std.mem.zeroes([10]u8),
};
pub const _Py_LocalMonitors = struct__Py_LocalMonitors;
pub const struct__Py_GlobalMonitors = extern struct {
    tools: [15]u8 = std.mem.zeroes([15]u8),
};
pub const _Py_GlobalMonitors = struct__Py_GlobalMonitors;
pub const _PyCoCached = extern struct {
    _co_code: ?*PyObject = std.mem.zeroes(?*PyObject),
    _co_varnames: ?*PyObject = std.mem.zeroes(?*PyObject),
    _co_cellvars: ?*PyObject = std.mem.zeroes(?*PyObject),
    _co_freevars: ?*PyObject = std.mem.zeroes(?*PyObject),
};
pub const _PyCoLineInstrumentationData = extern struct {
    original_opcode: u8 = std.mem.zeroes(u8),
    line_delta: i8 = std.mem.zeroes(i8),
};
pub const struct__PyExecutorObject_17 = opaque {};
pub const _PyExecutorArray = extern struct {
    size: c_int = std.mem.zeroes(c_int),
    capacity: c_int = std.mem.zeroes(c_int),
    executors: [1]?*struct__PyExecutorObject_17 = std.mem.zeroes([1]?*struct__PyExecutorObject_17),
};
pub const _PyCoMonitoringData = extern struct {
    local_monitors: _Py_LocalMonitors = std.mem.zeroes(_Py_LocalMonitors),
    active_monitors: _Py_LocalMonitors = std.mem.zeroes(_Py_LocalMonitors),
    tools: ?*u8 = std.mem.zeroes(?*u8),
    lines: ?*_PyCoLineInstrumentationData = std.mem.zeroes(?*_PyCoLineInstrumentationData),
    line_tools: ?*u8 = std.mem.zeroes(?*u8),
    per_instruction_opcodes: ?*u8 = std.mem.zeroes(?*u8),
    per_instruction_tools: ?*u8 = std.mem.zeroes(?*u8),
};
pub extern var PyCode_Type: PyTypeObject;
pub fn PyCode_GetNumFree(arg_op: ?*PyCodeObject) callconv(.c) Py_ssize_t {
    var op = arg_op;
    _ = &op;
    _ = blk: {
        _ = @sizeOf(c_int);
        break :blk blk_1: {
            break :blk_1 if (Py_IS_TYPE(@as(?*PyObject, @ptrCast(@alignCast(op))), &PyCode_Type) != 0) {} else {
                __assert_fail("PyCode_Check(op)", "/usr/include/python3.13/cpython/code.h", @as(c_uint, @bitCast(@as(c_int, 184))), "Py_ssize_t PyCode_GetNumFree(PyCodeObject *)");
            };
        };
    };
    return @as(Py_ssize_t, @bitCast(@as(c_long, op.*.co_nfreevars)));
}
pub fn PyUnstable_Code_GetFirstFree(arg_op: ?*PyCodeObject) callconv(.c) c_int {
    var op = arg_op;
    _ = &op;
    _ = blk: {
        _ = @sizeOf(c_int);
        break :blk blk_1: {
            break :blk_1 if (Py_IS_TYPE(@as(?*PyObject, @ptrCast(@alignCast(op))), &PyCode_Type) != 0) {} else {
                __assert_fail("PyCode_Check(op)", "/usr/include/python3.13/cpython/code.h", @as(c_uint, @bitCast(@as(c_int, 189))), "int PyUnstable_Code_GetFirstFree(PyCodeObject *)");
            };
        };
    };
    return op.*.co_nlocalsplus - op.*.co_nfreevars;
}
pub fn PyCode_GetFirstFree(arg_op: ?*PyCodeObject) callconv(.c) c_int {
    var op = arg_op;
    _ = &op;
    return PyUnstable_Code_GetFirstFree(op);
}
pub extern fn PyUnstable_Code_New(c_int, c_int, c_int, c_int, c_int, ?*PyObject, ?*PyObject, ?*PyObject, ?*PyObject, ?*PyObject, ?*PyObject, ?*PyObject, ?*PyObject, ?*PyObject, c_int, ?*PyObject, ?*PyObject) ?*PyCodeObject;
pub extern fn PyUnstable_Code_NewWithPosOnlyArgs(c_int, c_int, c_int, c_int, c_int, c_int, ?*PyObject, ?*PyObject, ?*PyObject, ?*PyObject, ?*PyObject, ?*PyObject, ?*PyObject, ?*PyObject, ?*PyObject, c_int, ?*PyObject, ?*PyObject) ?*PyCodeObject;
pub fn PyCode_New(arg_a: c_int, arg_b: c_int, arg_c: c_int, arg_d: c_int, arg_e: c_int, arg_f: ?*PyObject, arg_g: ?*PyObject, arg_h: ?*PyObject, arg_i: ?*PyObject, arg_j: ?*PyObject, arg_k: ?*PyObject, arg_l: ?*PyObject, arg_m: ?*PyObject, arg_n: ?*PyObject, arg_o: c_int, arg_p: ?*PyObject, arg_q: ?*PyObject) callconv(.c) ?*PyCodeObject {
    var a = arg_a;
    _ = &a;
    var b = arg_b;
    _ = &b;
    var c = arg_c;
    _ = &c;
    var d = arg_d;
    _ = &d;
    var e = arg_e;
    _ = &e;
    var f = arg_f;
    _ = &f;
    var g = arg_g;
    _ = &g;
    var h = arg_h;
    _ = &h;
    var i = arg_i;
    _ = &i;
    var j = arg_j;
    _ = &j;
    var k = arg_k;
    _ = &k;
    var l = arg_l;
    _ = &l;
    var m = arg_m;
    _ = &m;
    var n = arg_n;
    _ = &n;
    var o = arg_o;
    _ = &o;
    var p = arg_p;
    _ = &p;
    var q = arg_q;
    _ = &q;
    return PyUnstable_Code_New(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q);
}
pub fn PyCode_NewWithPosOnlyArgs(arg_a: c_int, arg_poac: c_int, arg_b: c_int, arg_c: c_int, arg_d: c_int, arg_e: c_int, arg_f: ?*PyObject, arg_g: ?*PyObject, arg_h: ?*PyObject, arg_i: ?*PyObject, arg_j: ?*PyObject, arg_k: ?*PyObject, arg_l: ?*PyObject, arg_m: ?*PyObject, arg_n: ?*PyObject, arg_o: c_int, arg_p: ?*PyObject, arg_q: ?*PyObject) callconv(.c) ?*PyCodeObject {
    var a = arg_a;
    _ = &a;
    var poac = arg_poac;
    _ = &poac;
    var b = arg_b;
    _ = &b;
    var c = arg_c;
    _ = &c;
    var d = arg_d;
    _ = &d;
    var e = arg_e;
    _ = &e;
    var f = arg_f;
    _ = &f;
    var g = arg_g;
    _ = &g;
    var h = arg_h;
    _ = &h;
    var i = arg_i;
    _ = &i;
    var j = arg_j;
    _ = &j;
    var k = arg_k;
    _ = &k;
    var l = arg_l;
    _ = &l;
    var m = arg_m;
    _ = &m;
    var n = arg_n;
    _ = &n;
    var o = arg_o;
    _ = &o;
    var p = arg_p;
    _ = &p;
    var q = arg_q;
    _ = &q;
    return PyUnstable_Code_NewWithPosOnlyArgs(a, poac, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q);
}
pub extern fn PyCode_NewEmpty(filename: ?*const u8, funcname: ?*const u8, firstlineno: c_int) ?*PyCodeObject;
pub extern fn PyCode_Addr2Line(?*PyCodeObject, c_int) c_int;
pub extern fn PyCode_Addr2Location(?*PyCodeObject, c_int, ?*c_int, ?*c_int, ?*c_int, ?*c_int) c_int;
pub const PY_CODE_EVENT_CREATE: c_int = 0;
pub const PY_CODE_EVENT_DESTROY: c_int = 1;
pub const PyCodeEvent = c_uint;
pub const PyCode_WatchCallback = ?*const fn (PyCodeEvent, ?*PyCodeObject) callconv(.c) c_int;
pub extern fn PyCode_AddWatcher(callback: PyCode_WatchCallback) c_int;
pub extern fn PyCode_ClearWatcher(watcher_id: c_int) c_int;
pub const struct__opaque = extern struct {
    computed_line: c_int = std.mem.zeroes(c_int),
    lo_next: ?*const u8 = std.mem.zeroes(?*const u8),
    limit: ?*const u8 = std.mem.zeroes(?*const u8),
};
pub const struct__line_offsets = extern struct {
    ar_start: c_int = std.mem.zeroes(c_int),
    ar_end: c_int = std.mem.zeroes(c_int),
    ar_line: c_int = std.mem.zeroes(c_int),
    @"opaque": struct__opaque = std.mem.zeroes(struct__opaque),
};
pub const PyCodeAddressRange = struct__line_offsets;
pub extern fn _PyCode_CheckLineNumber(lasti: c_int, bounds: ?*PyCodeAddressRange) c_int;
pub extern fn _PyCode_ConstantKey(obj: ?*PyObject) ?*PyObject;
pub extern fn PyCode_Optimize(code: ?*PyObject, consts: ?*PyObject, names: ?*PyObject, lnotab: ?*PyObject) ?*PyObject;
pub extern fn PyUnstable_Code_GetExtra(code: ?*PyObject, index: Py_ssize_t, extra: ?*?*anyopaque) c_int;
pub extern fn PyUnstable_Code_SetExtra(code: ?*PyObject, index: Py_ssize_t, extra: ?*anyopaque) c_int;
pub fn _PyCode_GetExtra(arg_code: ?*PyObject, arg_index_1: Py_ssize_t, arg_extra: ?*?*anyopaque) callconv(.c) c_int {
    var code = arg_code;
    _ = &code;
    var index_1 = arg_index_1;
    _ = &index_1;
    var extra = arg_extra;
    _ = &extra;
    return PyUnstable_Code_GetExtra(code, index_1, extra);
}
pub fn _PyCode_SetExtra(arg_code: ?*PyObject, arg_index_1: Py_ssize_t, arg_extra: ?*anyopaque) callconv(.c) c_int {
    var code = arg_code;
    _ = &code;
    var index_1 = arg_index_1;
    _ = &index_1;
    var extra = arg_extra;
    _ = &extra;
    return PyUnstable_Code_SetExtra(code, index_1, extra);
}
pub extern fn PyCode_GetCode(code: ?*PyCodeObject) ?*PyObject;
pub extern fn PyCode_GetVarnames(code: ?*PyCodeObject) ?*PyObject;
pub extern fn PyCode_GetCellvars(code: ?*PyCodeObject) ?*PyObject;
pub extern fn PyCode_GetFreevars(code: ?*PyCodeObject) ?*PyObject;
pub const PY_CODE_LOCATION_INFO_SHORT0: c_int = 0;
pub const PY_CODE_LOCATION_INFO_ONE_LINE0: c_int = 10;
pub const PY_CODE_LOCATION_INFO_ONE_LINE1: c_int = 11;
pub const PY_CODE_LOCATION_INFO_ONE_LINE2: c_int = 12;
pub const PY_CODE_LOCATION_INFO_NO_COLUMNS: c_int = 13;
pub const PY_CODE_LOCATION_INFO_LONG: c_int = 14;
pub const PY_CODE_LOCATION_INFO_NONE: c_int = 15;
pub const enum__PyCodeLocationInfoKind = c_uint;
pub const _PyCodeLocationInfoKind = enum__PyCodeLocationInfoKind;
pub extern fn PyFrame_GetLineNumber(?*PyFrameObject) c_int;
pub extern fn PyFrame_GetCode(frame: ?*PyFrameObject) ?*PyCodeObject;
pub extern var PyFrame_Type: PyTypeObject;
pub extern var PyFrameLocalsProxy_Type: PyTypeObject;
pub extern fn PyFrame_GetBack(frame: ?*PyFrameObject) ?*PyFrameObject;
pub extern fn PyFrame_GetLocals(frame: ?*PyFrameObject) ?*PyObject;
pub extern fn PyFrame_GetGlobals(frame: ?*PyFrameObject) ?*PyObject;
pub extern fn PyFrame_GetBuiltins(frame: ?*PyFrameObject) ?*PyObject;
pub extern fn PyFrame_GetGenerator(frame: ?*PyFrameObject) ?*PyObject;
pub extern fn PyFrame_GetLasti(frame: ?*PyFrameObject) c_int;
pub extern fn PyFrame_GetVar(frame: ?*PyFrameObject, name: ?*PyObject) ?*PyObject;
pub extern fn PyFrame_GetVarString(frame: ?*PyFrameObject, name: ?*const u8) ?*PyObject;
pub extern fn PyUnstable_InterpreterFrame_GetCode(frame: ?*struct__PyInterpreterFrame) ?*PyObject;
pub extern fn PyUnstable_InterpreterFrame_GetLasti(frame: ?*struct__PyInterpreterFrame) c_int;
pub extern fn PyUnstable_InterpreterFrame_GetLine(frame: ?*struct__PyInterpreterFrame) c_int;
pub extern const PyUnstable_ExecutableKinds: [6]?*const PyTypeObject;
pub extern fn PyTraceBack_Here(?*PyFrameObject) c_int;
pub extern fn PyTraceBack_Print(?*PyObject, ?*PyObject) c_int;
pub extern var PyTraceBack_Type: PyTypeObject;
pub const PyTracebackObject = struct__traceback;
pub const struct__traceback = extern struct {
    ob_base: PyObject = std.mem.zeroes(PyObject),
    tb_next: ?*PyTracebackObject = std.mem.zeroes(?*PyTracebackObject),
    tb_frame: ?*PyFrameObject = std.mem.zeroes(?*PyFrameObject),
    tb_lasti: c_int = std.mem.zeroes(c_int),
    tb_lineno: c_int = std.mem.zeroes(c_int),
};
pub extern var _Py_EllipsisObject: PyObject;
pub const PySliceObject = extern struct {
    ob_base: PyObject = std.mem.zeroes(PyObject),
    start: ?*PyObject = std.mem.zeroes(?*PyObject),
    stop: ?*PyObject = std.mem.zeroes(?*PyObject),
    step: ?*PyObject = std.mem.zeroes(?*PyObject),
};
pub extern var PySlice_Type: PyTypeObject;
pub extern var PyEllipsis_Type: PyTypeObject;
pub extern fn PySlice_New(start: ?*PyObject, stop: ?*PyObject, step: ?*PyObject) ?*PyObject;
pub extern fn _PySlice_FromIndices(start: Py_ssize_t, stop: Py_ssize_t) ?*PyObject;
pub extern fn _PySlice_GetLongIndices(self: ?*PySliceObject, length: ?*PyObject, start_ptr: ?*?*PyObject, stop_ptr: ?*?*PyObject, step_ptr: ?*?*PyObject) c_int;
pub extern fn PySlice_GetIndices(r: ?*PyObject, length: Py_ssize_t, start: ?*Py_ssize_t, stop: ?*Py_ssize_t, step: ?*Py_ssize_t) c_int;
pub extern fn PySlice_GetIndicesEx(r: ?*PyObject, length: Py_ssize_t, start: ?*Py_ssize_t, stop: ?*Py_ssize_t, step: ?*Py_ssize_t, slicelength: ?*Py_ssize_t) c_int;
pub extern fn PySlice_Unpack(slice: ?*PyObject, start: ?*Py_ssize_t, stop: ?*Py_ssize_t, step: ?*Py_ssize_t) c_int;
pub extern fn PySlice_AdjustIndices(length: Py_ssize_t, start: ?*Py_ssize_t, stop: ?*Py_ssize_t, step: Py_ssize_t) Py_ssize_t;
pub const PyCellObject = extern struct {
    ob_base: PyObject = std.mem.zeroes(PyObject),
    ob_ref: ?*PyObject = std.mem.zeroes(?*PyObject),
};
pub extern var PyCell_Type: PyTypeObject;
pub extern fn PyCell_New(?*PyObject) ?*PyObject;
pub extern fn PyCell_Get(?*PyObject) ?*PyObject;
pub extern fn PyCell_Set(?*PyObject, ?*PyObject) c_int;
pub fn PyCell_GET(arg_op: ?*PyObject) callconv(.c) ?*PyObject {
    var op = arg_op;
    _ = &op;
    var cell: ?*PyCellObject = undefined;
    _ = &cell;
    _ = blk: {
        _ = @sizeOf(c_int);
        break :blk blk_1: {
            break :blk_1 if (Py_IS_TYPE(op, &PyCell_Type) != 0) {} else {
                __assert_fail("PyCell_Check(op)", "/usr/include/python3.13/cpython/cellobject.h", @as(c_uint, @bitCast(@as(c_int, 26))), "PyObject *PyCell_GET(PyObject *)");
            };
        };
    };
    cell = @as(?*PyCellObject, @ptrCast(@alignCast(op)));
    return cell.*.ob_ref;
}
pub fn PyCell_SET(arg_op: ?*PyObject, arg_value: ?*PyObject) callconv(.c) void {
    var op = arg_op;
    _ = &op;
    var value = arg_value;
    _ = &value;
    var cell: ?*PyCellObject = undefined;
    _ = &cell;
    _ = blk: {
        _ = @sizeOf(c_int);
        break :blk blk_1: {
            break :blk_1 if (Py_IS_TYPE(op, &PyCell_Type) != 0) {} else {
                __assert_fail("PyCell_Check(op)", "/usr/include/python3.13/cpython/cellobject.h", @as(c_uint, @bitCast(@as(c_int, 34))), "void PyCell_SET(PyObject *, PyObject *)");
            };
        };
    };
    cell = @as(?*PyCellObject, @ptrCast(@alignCast(op)));
    cell.*.ob_ref = value;
}
pub extern var PySeqIter_Type: PyTypeObject;
pub extern var PyCallIter_Type: PyTypeObject;
pub extern fn PySeqIter_New(?*PyObject) ?*PyObject;
pub extern fn PyCallIter_New(?*PyObject, ?*PyObject) ?*PyObject;
pub const _PyStatus_TYPE_OK: c_int = 0;
pub const _PyStatus_TYPE_ERROR: c_int = 1;
pub const _PyStatus_TYPE_EXIT: c_int = 2;
const enum_unnamed_18 = c_uint;
pub const PyStatus = extern struct {
    _type: enum_unnamed_18 = std.mem.zeroes(enum_unnamed_18),
    func: ?*const u8 = std.mem.zeroes(?*const u8),
    err_msg: ?*const u8 = std.mem.zeroes(?*const u8),
    exitcode: c_int = std.mem.zeroes(c_int),
};
pub extern fn PyStatus_Ok() PyStatus;
pub extern fn PyStatus_Error(err_msg: ?*const u8) PyStatus;
pub extern fn PyStatus_NoMemory() PyStatus;
pub extern fn PyStatus_Exit(exitcode: c_int) PyStatus;
pub extern fn PyStatus_IsError(err: PyStatus) c_int;
pub extern fn PyStatus_IsExit(err: PyStatus) c_int;
pub extern fn PyStatus_Exception(err: PyStatus) c_int;
pub const PyWideStringList = extern struct {
    length: Py_ssize_t = std.mem.zeroes(Py_ssize_t),
    items: ?*?*wchar_t = std.mem.zeroes(?*?*wchar_t),
};
pub extern fn PyWideStringList_Append(list: ?*PyWideStringList, item: ?*const wchar_t) PyStatus;
pub extern fn PyWideStringList_Insert(list: ?*PyWideStringList, index: Py_ssize_t, item: ?*const wchar_t) PyStatus;
pub const struct_PyPreConfig = extern struct {
    _config_init: c_int = std.mem.zeroes(c_int),
    parse_argv: c_int = std.mem.zeroes(c_int),
    isolated: c_int = std.mem.zeroes(c_int),
    use_environment: c_int = std.mem.zeroes(c_int),
    configure_locale: c_int = std.mem.zeroes(c_int),
    coerce_c_locale: c_int = std.mem.zeroes(c_int),
    coerce_c_locale_warn: c_int = std.mem.zeroes(c_int),
    utf8_mode: c_int = std.mem.zeroes(c_int),
    dev_mode: c_int = std.mem.zeroes(c_int),
    allocator: c_int = std.mem.zeroes(c_int),
};
pub const PyPreConfig = struct_PyPreConfig;
pub extern fn PyPreConfig_InitPythonConfig(config: ?*PyPreConfig) void;
pub extern fn PyPreConfig_InitIsolatedConfig(config: ?*PyPreConfig) void;
pub const struct_PyConfig = extern struct {
    _config_init: c_int = std.mem.zeroes(c_int),
    isolated: c_int = std.mem.zeroes(c_int),
    use_environment: c_int = std.mem.zeroes(c_int),
    dev_mode: c_int = std.mem.zeroes(c_int),
    install_signal_handlers: c_int = std.mem.zeroes(c_int),
    use_hash_seed: c_int = std.mem.zeroes(c_int),
    hash_seed: c_ulong = std.mem.zeroes(c_ulong),
    faulthandler: c_int = std.mem.zeroes(c_int),
    tracemalloc: c_int = std.mem.zeroes(c_int),
    perf_profiling: c_int = std.mem.zeroes(c_int),
    import_time: c_int = std.mem.zeroes(c_int),
    code_debug_ranges: c_int = std.mem.zeroes(c_int),
    show_ref_count: c_int = std.mem.zeroes(c_int),
    dump_refs: c_int = std.mem.zeroes(c_int),
    dump_refs_file: ?*wchar_t = std.mem.zeroes(?*wchar_t),
    malloc_stats: c_int = std.mem.zeroes(c_int),
    filesystem_encoding: ?*wchar_t = std.mem.zeroes(?*wchar_t),
    filesystem_errors: ?*wchar_t = std.mem.zeroes(?*wchar_t),
    pycache_prefix: ?*wchar_t = std.mem.zeroes(?*wchar_t),
    parse_argv: c_int = std.mem.zeroes(c_int),
    orig_argv: PyWideStringList = std.mem.zeroes(PyWideStringList),
    argv: PyWideStringList = std.mem.zeroes(PyWideStringList),
    xoptions: PyWideStringList = std.mem.zeroes(PyWideStringList),
    warnoptions: PyWideStringList = std.mem.zeroes(PyWideStringList),
    site_import: c_int = std.mem.zeroes(c_int),
    bytes_warning: c_int = std.mem.zeroes(c_int),
    warn_default_encoding: c_int = std.mem.zeroes(c_int),
    inspect: c_int = std.mem.zeroes(c_int),
    interactive: c_int = std.mem.zeroes(c_int),
    optimization_level: c_int = std.mem.zeroes(c_int),
    parser_debug: c_int = std.mem.zeroes(c_int),
    write_bytecode: c_int = std.mem.zeroes(c_int),
    verbose: c_int = std.mem.zeroes(c_int),
    quiet: c_int = std.mem.zeroes(c_int),
    user_site_directory: c_int = std.mem.zeroes(c_int),
    configure_c_stdio: c_int = std.mem.zeroes(c_int),
    buffered_stdio: c_int = std.mem.zeroes(c_int),
    stdio_encoding: ?*wchar_t = std.mem.zeroes(?*wchar_t),
    stdio_errors: ?*wchar_t = std.mem.zeroes(?*wchar_t),
    check_hash_pycs_mode: ?*wchar_t = std.mem.zeroes(?*wchar_t),
    use_frozen_modules: c_int = std.mem.zeroes(c_int),
    safe_path: c_int = std.mem.zeroes(c_int),
    int_max_str_digits: c_int = std.mem.zeroes(c_int),
    cpu_count: c_int = std.mem.zeroes(c_int),
    pathconfig_warnings: c_int = std.mem.zeroes(c_int),
    program_name: ?*wchar_t = std.mem.zeroes(?*wchar_t),
    pythonpath_env: ?*wchar_t = std.mem.zeroes(?*wchar_t),
    home: ?*wchar_t = std.mem.zeroes(?*wchar_t),
    platlibdir: ?*wchar_t = std.mem.zeroes(?*wchar_t),
    module_search_paths_set: c_int = std.mem.zeroes(c_int),
    module_search_paths: PyWideStringList = std.mem.zeroes(PyWideStringList),
    stdlib_dir: ?*wchar_t = std.mem.zeroes(?*wchar_t),
    executable: ?*wchar_t = std.mem.zeroes(?*wchar_t),
    base_executable: ?*wchar_t = std.mem.zeroes(?*wchar_t),
    prefix: ?*wchar_t = std.mem.zeroes(?*wchar_t),
    base_prefix: ?*wchar_t = std.mem.zeroes(?*wchar_t),
    exec_prefix: ?*wchar_t = std.mem.zeroes(?*wchar_t),
    base_exec_prefix: ?*wchar_t = std.mem.zeroes(?*wchar_t),
    skip_source_first_line: c_int = std.mem.zeroes(c_int),
    run_command: ?*wchar_t = std.mem.zeroes(?*wchar_t),
    run_module: ?*wchar_t = std.mem.zeroes(?*wchar_t),
    run_filename: ?*wchar_t = std.mem.zeroes(?*wchar_t),
    sys_path_0: ?*wchar_t = std.mem.zeroes(?*wchar_t),
    _install_importlib: c_int = std.mem.zeroes(c_int),
    _init_main: c_int = std.mem.zeroes(c_int),
    _is_python_build: c_int = std.mem.zeroes(c_int),
};
pub const PyConfig = struct_PyConfig;
pub extern fn PyConfig_InitPythonConfig(config: ?*PyConfig) void;
pub extern fn PyConfig_InitIsolatedConfig(config: ?*PyConfig) void;
pub extern fn PyConfig_Clear(?*PyConfig) void;
pub extern fn PyConfig_SetString(config: ?*PyConfig, config_str: ?*?*wchar_t, str: ?*const wchar_t) PyStatus;
pub extern fn PyConfig_SetBytesString(config: ?*PyConfig, config_str: ?*?*wchar_t, str: ?*const u8) PyStatus;
pub extern fn PyConfig_Read(config: ?*PyConfig) PyStatus;
pub extern fn PyConfig_SetBytesArgv(config: ?*PyConfig, argc: Py_ssize_t, argv: ?*const ?*u8) PyStatus;
pub extern fn PyConfig_SetArgv(config: ?*PyConfig, argc: Py_ssize_t, argv: ?*const ?*wchar_t) PyStatus;
pub extern fn PyConfig_SetWideStringList(config: ?*PyConfig, list: ?*PyWideStringList, length: Py_ssize_t, items: ?*?*wchar_t) PyStatus;
pub extern fn Py_GetArgcArgv(argc: ?*c_int, argv: ?*?*?*wchar_t) void;
pub extern fn PyInterpreterState_New() ?*PyInterpreterState;
pub extern fn PyInterpreterState_Clear(?*PyInterpreterState) void;
pub extern fn PyInterpreterState_Delete(?*PyInterpreterState) void;
pub extern fn PyInterpreterState_Get() ?*PyInterpreterState;
pub extern fn PyInterpreterState_GetDict(?*PyInterpreterState) ?*PyObject;
pub extern fn PyInterpreterState_GetID(?*PyInterpreterState) i64;
pub extern fn PyState_AddModule(?*PyObject, ?*PyModuleDef) c_int;
pub extern fn PyState_RemoveModule(?*PyModuleDef) c_int;
pub extern fn PyState_FindModule(?*PyModuleDef) ?*PyObject;
pub extern fn PyThreadState_New(?*PyInterpreterState) ?*PyThreadState;
pub extern fn PyThreadState_Clear(?*PyThreadState) void;
pub extern fn PyThreadState_Delete(?*PyThreadState) void;
pub extern fn PyThreadState_Get() ?*PyThreadState;
pub extern fn PyThreadState_Swap(?*PyThreadState) ?*PyThreadState;
pub extern fn PyThreadState_GetDict() ?*PyObject;
pub extern fn PyThreadState_SetAsyncExc(c_ulong, ?*PyObject) c_int;
pub extern fn PyThreadState_GetInterpreter(tstate: ?*PyThreadState) ?*PyInterpreterState;
pub extern fn PyThreadState_GetFrame(tstate: ?*PyThreadState) ?*PyFrameObject;
pub extern fn PyThreadState_GetID(tstate: ?*PyThreadState) u64;
pub const PyGILState_LOCKED: c_int = 0;
pub const PyGILState_UNLOCKED: c_int = 1;
pub const PyGILState_STATE = c_uint;
pub extern fn PyGILState_Ensure() PyGILState_STATE;
pub extern fn PyGILState_Release(PyGILState_STATE) void;
pub extern fn PyGILState_GetThisThreadState() ?*PyThreadState;
pub extern fn _PyInterpreterState_RequiresIDRef(?*PyInterpreterState) c_int;
pub extern fn _PyInterpreterState_RequireIDRef(?*PyInterpreterState, c_int) void;
pub extern fn PyUnstable_InterpreterState_GetMainModule(?*PyInterpreterState) ?*PyObject;
pub extern fn PyThreadState_GetUnchecked() ?*PyThreadState;
pub extern fn PyThreadState_EnterTracing(tstate: ?*PyThreadState) void;
pub extern fn PyThreadState_LeaveTracing(tstate: ?*PyThreadState) void;
pub extern fn PyGILState_Check() c_int;
pub extern fn _PyThread_CurrentFrames() ?*PyObject;
pub extern fn PyInterpreterState_Main() ?*PyInterpreterState;
pub extern fn PyInterpreterState_Head() ?*PyInterpreterState;
pub extern fn PyInterpreterState_Next(?*PyInterpreterState) ?*PyInterpreterState;
pub extern fn PyInterpreterState_ThreadHead(?*PyInterpreterState) ?*PyThreadState;
pub extern fn PyThreadState_Next(?*PyThreadState) ?*PyThreadState;
pub extern fn PyThreadState_DeleteCurrent() void;
pub const _PyFrameEvalFunction = ?*const fn (?*PyThreadState, ?*struct__PyInterpreterFrame, c_int) callconv(.c) ?*PyObject;
pub extern fn _PyInterpreterState_GetEvalFrameFunc(interp: ?*PyInterpreterState) _PyFrameEvalFunction;
pub extern fn _PyInterpreterState_SetEvalFrameFunc(interp: ?*PyInterpreterState, eval_frame: _PyFrameEvalFunction) void;
pub const PyGenObject = extern struct {
    ob_base: PyObject = std.mem.zeroes(PyObject),
    gi_weakreflist: ?*PyObject = std.mem.zeroes(?*PyObject),
    gi_name: ?*PyObject = std.mem.zeroes(?*PyObject),
    gi_qualname: ?*PyObject = std.mem.zeroes(?*PyObject),
    gi_exc_state: _PyErr_StackItem = std.mem.zeroes(_PyErr_StackItem),
    gi_origin_or_finalizer: ?*PyObject = std.mem.zeroes(?*PyObject),
    gi_hooks_inited: u8 = std.mem.zeroes(u8),
    gi_closed: u8 = std.mem.zeroes(u8),
    gi_running_async: u8 = std.mem.zeroes(u8),
    gi_frame_state: i8 = std.mem.zeroes(i8),
    gi_iframe: [1]?*PyObject = std.mem.zeroes([1]?*PyObject),
};
pub extern var PyGen_Type: PyTypeObject;
pub extern fn PyGen_New(?*PyFrameObject) ?*PyObject;
pub extern fn PyGen_NewWithQualName(?*PyFrameObject, name: ?*PyObject, qualname: ?*PyObject) ?*PyObject;
pub extern fn PyGen_GetCode(gen: ?*PyGenObject) ?*PyCodeObject;
pub const PyCoroObject = extern struct {
    ob_base: PyObject = std.mem.zeroes(PyObject),
    cr_weakreflist: ?*PyObject = std.mem.zeroes(?*PyObject),
    cr_name: ?*PyObject = std.mem.zeroes(?*PyObject),
    cr_qualname: ?*PyObject = std.mem.zeroes(?*PyObject),
    cr_exc_state: _PyErr_StackItem = std.mem.zeroes(_PyErr_StackItem),
    cr_origin_or_finalizer: ?*PyObject = std.mem.zeroes(?*PyObject),
    cr_hooks_inited: u8 = std.mem.zeroes(u8),
    cr_closed: u8 = std.mem.zeroes(u8),
    cr_running_async: u8 = std.mem.zeroes(u8),
    cr_frame_state: i8 = std.mem.zeroes(i8),
    cr_iframe: [1]?*PyObject = std.mem.zeroes([1]?*PyObject),
};
pub extern var PyCoro_Type: PyTypeObject;
pub extern fn PyCoro_New(?*PyFrameObject, name: ?*PyObject, qualname: ?*PyObject) ?*PyObject;
pub const PyAsyncGenObject = extern struct {
    ob_base: PyObject = std.mem.zeroes(PyObject),
    ag_weakreflist: ?*PyObject = std.mem.zeroes(?*PyObject),
    ag_name: ?*PyObject = std.mem.zeroes(?*PyObject),
    ag_qualname: ?*PyObject = std.mem.zeroes(?*PyObject),
    ag_exc_state: _PyErr_StackItem = std.mem.zeroes(_PyErr_StackItem),
    ag_origin_or_finalizer: ?*PyObject = std.mem.zeroes(?*PyObject),
    ag_hooks_inited: u8 = std.mem.zeroes(u8),
    ag_closed: u8 = std.mem.zeroes(u8),
    ag_running_async: u8 = std.mem.zeroes(u8),
    ag_frame_state: i8 = std.mem.zeroes(i8),
    ag_iframe: [1]?*PyObject = std.mem.zeroes([1]?*PyObject),
};
pub extern var PyAsyncGen_Type: PyTypeObject;
pub extern var _PyAsyncGenASend_Type: PyTypeObject;
pub extern fn PyAsyncGen_New(?*PyFrameObject, name: ?*PyObject, qualname: ?*PyObject) ?*PyObject;
pub extern var PyClassMethodDescr_Type: PyTypeObject;
pub extern var PyGetSetDescr_Type: PyTypeObject;
pub extern var PyMemberDescr_Type: PyTypeObject;
pub extern var PyMethodDescr_Type: PyTypeObject;
pub extern var PyWrapperDescr_Type: PyTypeObject;
pub extern var PyDictProxy_Type: PyTypeObject;
pub extern var PyProperty_Type: PyTypeObject;
pub extern fn PyDescr_NewMethod(?*PyTypeObject, ?*PyMethodDef) ?*PyObject;
pub extern fn PyDescr_NewClassMethod(?*PyTypeObject, ?*PyMethodDef) ?*PyObject;
pub extern fn PyDescr_NewMember(?*PyTypeObject, ?*PyMemberDef) ?*PyObject;
pub extern fn PyDescr_NewGetSet(?*PyTypeObject, ?*PyGetSetDef) ?*PyObject;
pub extern fn PyDictProxy_New(?*PyObject) ?*PyObject;
pub extern fn PyWrapper_New(?*PyObject, ?*PyObject) ?*PyObject;
pub extern fn PyMember_GetOne(?*const u8, ?*PyMemberDef) ?*PyObject;
pub extern fn PyMember_SetOne(?*u8, ?*PyMemberDef, ?*PyObject) c_int;
pub const wrapperfunc = ?*const fn (?*PyObject, ?*PyObject, ?*anyopaque) callconv(.c) ?*PyObject;
pub const wrapperfunc_kwds = ?*const fn (?*PyObject, ?*PyObject, ?*anyopaque, ?*PyObject) callconv(.c) ?*PyObject;
pub const struct_wrapperbase = extern struct {
    name: ?*const u8 = std.mem.zeroes(?*const u8),
    offset: c_int = std.mem.zeroes(c_int),
    function: ?*anyopaque = std.mem.zeroes(?*anyopaque),
    wrapper: wrapperfunc = std.mem.zeroes(wrapperfunc),
    doc: ?*const u8 = std.mem.zeroes(?*const u8),
    flags: c_int = std.mem.zeroes(c_int),
    name_strobj: ?*PyObject = std.mem.zeroes(?*PyObject),
};
pub const PyDescrObject = extern struct {
    ob_base: PyObject = std.mem.zeroes(PyObject),
    d_type: ?*PyTypeObject = std.mem.zeroes(?*PyTypeObject),
    d_name: ?*PyObject = std.mem.zeroes(?*PyObject),
    d_qualname: ?*PyObject = std.mem.zeroes(?*PyObject),
};
pub const PyMethodDescrObject = extern struct {
    d_common: PyDescrObject = std.mem.zeroes(PyDescrObject),
    d_method: ?*PyMethodDef = std.mem.zeroes(?*PyMethodDef),
    vectorcall: vectorcallfunc = std.mem.zeroes(vectorcallfunc),
};
pub const PyMemberDescrObject = extern struct {
    d_common: PyDescrObject = std.mem.zeroes(PyDescrObject),
    d_member: ?*PyMemberDef = std.mem.zeroes(?*PyMemberDef),
};
pub const PyGetSetDescrObject = extern struct {
    d_common: PyDescrObject = std.mem.zeroes(PyDescrObject),
    d_getset: ?*PyGetSetDef = std.mem.zeroes(?*PyGetSetDef),
};
pub const PyWrapperDescrObject = extern struct {
    d_common: PyDescrObject = std.mem.zeroes(PyDescrObject),
    d_base: ?*struct_wrapperbase = std.mem.zeroes(?*struct_wrapperbase),
    d_wrapped: ?*anyopaque = std.mem.zeroes(?*anyopaque),
};
pub extern fn PyDescr_NewWrapper(?*PyTypeObject, ?*struct_wrapperbase, ?*anyopaque) ?*PyObject;
pub extern fn PyDescr_IsData(?*PyObject) c_int;
pub extern fn Py_GenericAlias(?*PyObject, ?*PyObject) ?*PyObject;
pub extern var Py_GenericAliasType: PyTypeObject;
pub extern fn PyErr_WarnEx(category: ?*PyObject, message: ?*const u8, stack_level: Py_ssize_t) c_int;
pub extern fn PyErr_WarnFormat(category: ?*PyObject, stack_level: Py_ssize_t, format: ?*const u8, ...) c_int;
pub extern fn PyErr_ResourceWarning(source: ?*PyObject, stack_level: Py_ssize_t, format: ?*const u8, ...) c_int;
pub extern fn PyErr_WarnExplicit(category: ?*PyObject, message: ?*const u8, filename: ?*const u8, lineno: c_int, module: ?*const u8, registry: ?*PyObject) c_int;
pub extern fn PyErr_WarnExplicitObject(category: ?*PyObject, message: ?*PyObject, filename: ?*PyObject, lineno: c_int, module: ?*PyObject, registry: ?*PyObject) c_int;
pub extern fn PyErr_WarnExplicitFormat(category: ?*PyObject, filename: ?*const u8, lineno: c_int, module: ?*const u8, registry: ?*PyObject, format: ?*const u8, ...) c_int;
pub const PyWeakReference = struct__PyWeakReference;
pub const struct__PyWeakReference = extern struct {
    ob_base: PyObject = std.mem.zeroes(PyObject),
    wr_object: ?*PyObject = std.mem.zeroes(?*PyObject),
    wr_callback: ?*PyObject = std.mem.zeroes(?*PyObject),
    hash: Py_hash_t = std.mem.zeroes(Py_hash_t),
    wr_prev: ?*PyWeakReference = std.mem.zeroes(?*PyWeakReference),
    wr_next: ?*PyWeakReference = std.mem.zeroes(?*PyWeakReference),
    vectorcall: vectorcallfunc = std.mem.zeroes(vectorcallfunc),
};
pub extern var _PyWeakref_RefType: PyTypeObject;
pub extern var _PyWeakref_ProxyType: PyTypeObject;
pub extern var _PyWeakref_CallableProxyType: PyTypeObject;
pub extern fn PyWeakref_NewRef(ob: ?*PyObject, callback: ?*PyObject) ?*PyObject;
pub extern fn PyWeakref_NewProxy(ob: ?*PyObject, callback: ?*PyObject) ?*PyObject;
pub extern fn PyWeakref_GetObject(ref: ?*PyObject) ?*PyObject;
pub extern fn PyWeakref_GetRef(ref: ?*PyObject, pobj: ?*?*PyObject) c_int;
pub extern fn _PyWeakref_ClearRef(self: ?*PyWeakReference) void;
pub fn PyWeakref_GET_OBJECT(arg_ref_obj: ?*PyObject) callconv(.c) ?*PyObject {
    var ref_obj = arg_ref_obj;
    _ = &ref_obj;
    var ref: ?*PyWeakReference = undefined;
    _ = &ref;
    var obj: ?*PyObject = undefined;
    _ = &obj;
    _ = blk: {
        _ = @sizeOf(c_int);
        break :blk blk_1: {
            break :blk_1 if ((PyObject_TypeCheck(ref_obj, &_PyWeakref_RefType) != 0) or ((Py_IS_TYPE(ref_obj, &_PyWeakref_ProxyType) != 0) or (Py_IS_TYPE(ref_obj, &_PyWeakref_CallableProxyType) != 0))) {} else {
                __assert_fail("PyWeakref_Check(ref_obj)", "/usr/include/python3.13/cpython/weakrefobject.h", @as(c_uint, @bitCast(@as(c_int, 49))), "PyObject *PyWeakref_GET_OBJECT(PyObject *)");
            };
        };
    };
    ref = @as(?*PyWeakReference, @ptrCast(@alignCast(ref_obj)));
    obj = ref.*.wr_object;
    if (Py_REFCNT(obj) > @as(Py_ssize_t, @bitCast(@as(c_long, @as(c_int, 0))))) {
        return obj;
    }
    return &_Py_NoneStruct;
}
pub const struct_PyStructSequence_Field = extern struct {
    name: ?*const u8 = std.mem.zeroes(?*const u8),
    doc: ?*const u8 = std.mem.zeroes(?*const u8),
};
pub const PyStructSequence_Field = struct_PyStructSequence_Field;
pub const struct_PyStructSequence_Desc = extern struct {
    name: ?*const u8 = std.mem.zeroes(?*const u8),
    doc: ?*const u8 = std.mem.zeroes(?*const u8),
    fields: ?*PyStructSequence_Field = std.mem.zeroes(?*PyStructSequence_Field),
    n_in_sequence: c_int = std.mem.zeroes(c_int),
};
pub const PyStructSequence_Desc = struct_PyStructSequence_Desc;
pub extern const PyStructSequence_UnnamedField: ?*const u8;
pub extern fn PyStructSequence_InitType(@"type": ?*PyTypeObject, desc: ?*PyStructSequence_Desc) void;
pub extern fn PyStructSequence_InitType2(@"type": ?*PyTypeObject, desc: ?*PyStructSequence_Desc) c_int;
pub extern fn PyStructSequence_NewType(desc: ?*PyStructSequence_Desc) ?*PyTypeObject;
pub extern fn PyStructSequence_New(@"type": ?*PyTypeObject) ?*PyObject;
pub extern fn PyStructSequence_SetItem(?*PyObject, Py_ssize_t, ?*PyObject) void;
pub extern fn PyStructSequence_GetItem(?*PyObject, Py_ssize_t) ?*PyObject;
pub const PyStructSequence = PyTupleObject;
pub extern var PyPickleBuffer_Type: PyTypeObject;
pub extern fn PyPickleBuffer_FromObject(?*PyObject) ?*PyObject;
pub extern fn PyPickleBuffer_GetBuffer(?*PyObject) ?*const Py_buffer;
pub extern fn PyPickleBuffer_Release(?*PyObject) c_int;
pub const PyTime_t = i64;
pub extern fn PyTime_AsSecondsDouble(t: PyTime_t) f64;
pub extern fn PyTime_Monotonic(result: ?*PyTime_t) c_int;
pub extern fn PyTime_PerfCounter(result: ?*PyTime_t) c_int;
pub extern fn PyTime_Time(result: ?*PyTime_t) c_int;
pub extern fn PyTime_MonotonicRaw(result: ?*PyTime_t) c_int;
pub extern fn PyTime_PerfCounterRaw(result: ?*PyTime_t) c_int;
pub extern fn PyTime_TimeRaw(result: ?*PyTime_t) c_int;
pub extern fn PyCodec_Register(search_function: ?*PyObject) c_int;
pub extern fn PyCodec_Unregister(search_function: ?*PyObject) c_int;
pub extern fn PyCodec_KnownEncoding(encoding: ?*const u8) c_int;
pub extern fn PyCodec_Encode(object: ?*PyObject, encoding: ?*const u8, errors: ?*const u8) ?*PyObject;
pub extern fn PyCodec_Decode(object: ?*PyObject, encoding: ?*const u8, errors: ?*const u8) ?*PyObject;
pub extern fn PyCodec_Encoder(encoding: ?*const u8) ?*PyObject;
pub extern fn PyCodec_Decoder(encoding: ?*const u8) ?*PyObject;
pub extern fn PyCodec_IncrementalEncoder(encoding: ?*const u8, errors: ?*const u8) ?*PyObject;
pub extern fn PyCodec_IncrementalDecoder(encoding: ?*const u8, errors: ?*const u8) ?*PyObject;
pub extern fn PyCodec_StreamReader(encoding: ?*const u8, stream: ?*PyObject, errors: ?*const u8) ?*PyObject;
pub extern fn PyCodec_StreamWriter(encoding: ?*const u8, stream: ?*PyObject, errors: ?*const u8) ?*PyObject;
pub extern fn PyCodec_RegisterError(name: ?*const u8, @"error": ?*PyObject) c_int;
pub extern fn PyCodec_LookupError(name: ?*const u8) ?*PyObject;
pub extern fn PyCodec_StrictErrors(exc: ?*PyObject) ?*PyObject;
pub extern fn PyCodec_IgnoreErrors(exc: ?*PyObject) ?*PyObject;
pub extern fn PyCodec_ReplaceErrors(exc: ?*PyObject) ?*PyObject;
pub extern fn PyCodec_XMLCharRefReplaceErrors(exc: ?*PyObject) ?*PyObject;
pub extern fn PyCodec_BackslashReplaceErrors(exc: ?*PyObject) ?*PyObject;
pub extern fn PyCodec_NameReplaceErrors(exc: ?*PyObject) ?*PyObject;
pub extern var Py_hexdigits: ?*const u8;
pub const PyThread_type_lock = ?*anyopaque;
pub const PY_LOCK_FAILURE: c_int = 0;
pub const PY_LOCK_ACQUIRED: c_int = 1;
pub const PY_LOCK_INTR: c_int = 2;
pub const enum_PyLockStatus = c_uint;
pub const PyLockStatus = enum_PyLockStatus;
pub extern fn PyThread_init_thread() void;
pub extern fn PyThread_start_new_thread(?*const fn (?*anyopaque) callconv(.c) void, ?*anyopaque) c_ulong;
pub extern fn PyThread_exit_thread() noreturn;
pub extern fn PyThread_get_thread_ident() c_ulong;
pub extern fn PyThread_get_thread_native_id() c_ulong;
pub extern fn PyThread_allocate_lock() PyThread_type_lock;
pub extern fn PyThread_free_lock(PyThread_type_lock) void;
pub extern fn PyThread_acquire_lock(PyThread_type_lock, c_int) c_int;
pub extern fn PyThread_acquire_lock_timed(PyThread_type_lock, microseconds: c_longlong, intr_flag: c_int) PyLockStatus;
pub extern fn PyThread_release_lock(PyThread_type_lock) void;
pub extern fn PyThread_get_stacksize() usize;
pub extern fn PyThread_set_stacksize(usize) c_int;
pub extern fn PyThread_GetInfo() ?*PyObject;
pub extern fn PyThread_create_key() c_int;
pub extern fn PyThread_delete_key(key: c_int) void;
pub extern fn PyThread_set_key_value(key: c_int, value: ?*anyopaque) c_int;
pub extern fn PyThread_get_key_value(key: c_int) ?*anyopaque;
pub extern fn PyThread_delete_key_value(key: c_int) void;
pub extern fn PyThread_ReInitTLS() void;
pub const struct__Py_tss_t = extern struct {
    _is_initialized: c_int = std.mem.zeroes(c_int),
    _key: pthread_key_t = std.mem.zeroes(pthread_key_t),
};
pub const Py_tss_t = struct__Py_tss_t;
pub extern fn PyThread_tss_alloc() ?*Py_tss_t;
pub extern fn PyThread_tss_free(key: ?*Py_tss_t) void;
pub extern fn PyThread_tss_is_created(key: ?*Py_tss_t) c_int;
pub extern fn PyThread_tss_create(key: ?*Py_tss_t) c_int;
pub extern fn PyThread_tss_delete(key: ?*Py_tss_t) void;
pub extern fn PyThread_tss_set(key: ?*Py_tss_t, value: ?*anyopaque) c_int;
pub extern fn PyThread_tss_get(key: ?*Py_tss_t) ?*anyopaque;
pub extern const PY_TIMEOUT_MAX: c_longlong;
const enum_unnamed_28 = c_uint;
pub extern var PyContext_Type: PyTypeObject;
pub const struct__pycontextobject = opaque {};
pub const PyContext = struct__pycontextobject;
pub extern var PyContextVar_Type: PyTypeObject;
pub const struct__pycontextvarobject = opaque {};
pub const PyContextVar = struct__pycontextvarobject;
pub extern var PyContextToken_Type: PyTypeObject;
pub const struct__pycontexttokenobject = opaque {};
pub const PyContextToken = struct__pycontexttokenobject;
pub extern fn PyContext_New() ?*PyObject;
pub extern fn PyContext_Copy(?*PyObject) ?*PyObject;
pub extern fn PyContext_CopyCurrent() ?*PyObject;
pub extern fn PyContext_Enter(?*PyObject) c_int;
pub extern fn PyContext_Exit(?*PyObject) c_int;
pub extern fn PyContextVar_New(name: ?*const u8, default_value: ?*PyObject) ?*PyObject;
pub extern fn PyContextVar_Get(@"var": ?*PyObject, default_value: ?*PyObject, value: ?*?*PyObject) c_int;
pub extern fn PyContextVar_Set(@"var": ?*PyObject, value: ?*PyObject) ?*PyObject;
pub extern fn PyContextVar_Reset(@"var": ?*PyObject, token: ?*PyObject) c_int;
pub extern fn PyArg_Parse(?*PyObject, ?*const u8, ...) c_int;
pub extern fn PyArg_ParseTuple(?*PyObject, [*]const u8, ...) c_int;
pub extern fn PyArg_ParseTupleAndKeywords(?*PyObject, ?*PyObject, [*]const u8, ?*const ?*u8, ...) c_int;
pub extern fn PyArg_VaParse(?*PyObject, [*]const u8, ?*struct___va_list_tag_3) c_int;
pub extern fn PyArg_VaParseTupleAndKeywords(?*PyObject, ?*PyObject, [*]const u8, ?*const ?*u8, ?*struct___va_list_tag_3) c_int;
pub extern fn PyArg_ValidateKeywordArguments(?*PyObject) c_int;
pub extern fn PyArg_UnpackTuple(?*PyObject, ?*const u8, Py_ssize_t, Py_ssize_t, ...) c_int;
pub extern fn Py_BuildValue(?*const u8, ...) ?*PyObject;
pub extern fn Py_VaBuildValue(?*const u8, ?*struct___va_list_tag_3) ?*PyObject;
pub extern fn PyModule_AddObjectRef(mod: ?*PyObject, name: ?*const u8, value: ?*PyObject) c_int;
pub extern fn PyModule_Add(mod: ?*PyObject, name: ?*const u8, value: ?*PyObject) c_int;
pub extern fn PyModule_AddObject(mod: *PyObject, [*]const u8, value: ?*PyObject) c_int;
pub extern fn PyModule_AddIntConstant(?*PyObject, ?*const u8, c_long) c_int;
pub extern fn PyModule_AddStringConstant(?*PyObject, ?*const u8, ?*const u8) c_int;
pub extern fn PyModule_AddType(module: ?*PyObject, @"type": ?*PyTypeObject) c_int;
pub extern fn PyModule_SetDocString(?*PyObject, ?*const u8) c_int;
pub extern fn PyModule_AddFunctions(?*PyObject, ?*PyMethodDef) c_int;
pub extern fn PyModule_ExecDef(module: ?*PyObject, def: ?*PyModuleDef) c_int;
pub extern fn PyModule_Create2(?*PyModuleDef, apiver: c_int) ?*PyObject;
pub extern fn PyModule_FromDefAndSpec2(def: ?*PyModuleDef, spec: ?*PyObject, module_api_version: c_int) ?*PyObject;
pub const _PyOnceFlag = extern struct {
    v: u8 = std.mem.zeroes(u8),
};
pub const struct__PyArg_Parser = extern struct {
    format: ?*const u8 = std.mem.zeroes(?*const u8),
    keywords: ?*const ?*const u8 = std.mem.zeroes(?*const ?*const u8),
    fname: ?*const u8 = std.mem.zeroes(?*const u8),
    custom_msg: ?*const u8 = std.mem.zeroes(?*const u8),
    once: _PyOnceFlag = std.mem.zeroes(_PyOnceFlag),
    is_kwtuple_owned: c_int = std.mem.zeroes(c_int),
    pos: c_int = std.mem.zeroes(c_int),
    min: c_int = std.mem.zeroes(c_int),
    max: c_int = std.mem.zeroes(c_int),
    kwtuple: ?*PyObject = std.mem.zeroes(?*PyObject),
    next: ?*struct__PyArg_Parser = std.mem.zeroes(?*struct__PyArg_Parser),
};
pub const _PyArg_Parser = struct__PyArg_Parser;
pub extern fn _PyArg_ParseTupleAndKeywordsFast(?*PyObject, ?*PyObject, ?*struct__PyArg_Parser, ...) c_int;
pub const PyCompilerFlags = extern struct {
    cf_flags: c_int = std.mem.zeroes(c_int),
    cf_feature_version: c_int = std.mem.zeroes(c_int),
};
pub extern fn PyCompile_OpcodeStackEffect(opcode: c_int, oparg: c_int) c_int;
pub extern fn PyCompile_OpcodeStackEffectWithJump(opcode: c_int, oparg: c_int, jump: c_int) c_int;
pub extern fn Py_CompileString(?*const u8, ?*const u8, c_int) ?*PyObject;
pub extern fn PyErr_Print() void;
pub extern fn PyErr_PrintEx(c_int) void;
pub extern fn PyErr_Display(?*PyObject, ?*PyObject, ?*PyObject) void;
pub extern fn PyErr_DisplayException(?*PyObject) void;
pub extern var PyOS_InputHook: ?*const fn () callconv(.c) c_int;
pub extern fn PyRun_SimpleStringFlags(?*const u8, ?*PyCompilerFlags) c_int;
pub extern fn PyRun_AnyFileExFlags(fp: ?*FILE, filename: ?*const u8, closeit: c_int, flags: ?*PyCompilerFlags) c_int;
pub extern fn PyRun_SimpleFileExFlags(fp: ?*FILE, filename: ?*const u8, closeit: c_int, flags: ?*PyCompilerFlags) c_int;
pub extern fn PyRun_InteractiveOneFlags(fp: ?*FILE, filename: ?*const u8, flags: ?*PyCompilerFlags) c_int;
pub extern fn PyRun_InteractiveOneObject(fp: ?*FILE, filename: ?*PyObject, flags: ?*PyCompilerFlags) c_int;
pub extern fn PyRun_InteractiveLoopFlags(fp: ?*FILE, filename: ?*const u8, flags: ?*PyCompilerFlags) c_int;
pub extern fn PyRun_StringFlags(?*const u8, c_int, ?*PyObject, ?*PyObject, ?*PyCompilerFlags) ?*PyObject;
pub extern fn PyRun_FileExFlags(fp: ?*FILE, filename: ?*const u8, start: c_int, globals: ?*PyObject, locals: ?*PyObject, closeit: c_int, flags: ?*PyCompilerFlags) ?*PyObject;
pub extern fn Py_CompileStringExFlags(str: ?*const u8, filename: ?*const u8, start: c_int, flags: ?*PyCompilerFlags, optimize: c_int) ?*PyObject;
pub extern fn Py_CompileStringObject(str: ?*const u8, filename: ?*PyObject, start: c_int, flags: ?*PyCompilerFlags, optimize: c_int) ?*PyObject;
pub extern fn PyRun_String(str: ?*const u8, s: c_int, g: ?*PyObject, l: ?*PyObject) ?*PyObject;
pub extern fn PyRun_AnyFile(fp: ?*FILE, name: ?*const u8) c_int;
pub extern fn PyRun_AnyFileEx(fp: ?*FILE, name: ?*const u8, closeit: c_int) c_int;
pub extern fn PyRun_AnyFileFlags(?*FILE, ?*const u8, ?*PyCompilerFlags) c_int;
pub extern fn PyRun_SimpleString(s: ?*const u8) c_int;
pub extern fn PyRun_SimpleFile(f: ?*FILE, p: ?*const u8) c_int;
pub extern fn PyRun_SimpleFileEx(f: ?*FILE, p: ?*const u8, c: c_int) c_int;
pub extern fn PyRun_InteractiveOne(f: ?*FILE, p: ?*const u8) c_int;
pub extern fn PyRun_InteractiveLoop(f: ?*FILE, p: ?*const u8) c_int;
pub extern fn PyRun_File(fp: ?*FILE, p: ?*const u8, s: c_int, g: ?*PyObject, l: ?*PyObject) ?*PyObject;
pub extern fn PyRun_FileEx(fp: ?*FILE, p: ?*const u8, s: c_int, g: ?*PyObject, l: ?*PyObject, c: c_int) ?*PyObject;
pub extern fn PyRun_FileFlags(fp: ?*FILE, p: ?*const u8, s: c_int, g: ?*PyObject, l: ?*PyObject, flags: ?*PyCompilerFlags) ?*PyObject;
pub extern fn PyOS_Readline(?*FILE, ?*FILE, ?*const u8) ?*u8;
pub extern var PyOS_ReadlineFunctionPointer: ?*const fn (?*FILE, ?*FILE, ?*const u8) callconv(.c) ?*u8;
pub extern fn Py_Initialize() void;
pub extern fn Py_InitializeEx(c_int) void;
pub extern fn Py_Finalize() void;
pub extern fn Py_FinalizeEx() c_int;
pub extern fn Py_IsInitialized() c_int;
pub extern fn Py_NewInterpreter() ?*PyThreadState;
pub extern fn Py_EndInterpreter(?*PyThreadState) void;
pub extern fn Py_AtExit(func: ?*const fn () callconv(.c) void) c_int;
pub extern fn Py_Exit(c_int) noreturn;
pub extern fn Py_Main(argc: c_int, argv: ?*?*wchar_t) c_int;
pub extern fn Py_BytesMain(argc: c_int, argv: ?*?*u8) c_int;
pub extern fn Py_SetProgramName(?*const wchar_t) void;
pub extern fn Py_GetProgramName() ?*wchar_t;
pub extern fn Py_SetPythonHome(?*const wchar_t) void;
pub extern fn Py_GetPythonHome() ?*wchar_t;
pub extern fn Py_GetProgramFullPath() ?*wchar_t;
pub extern fn Py_GetPrefix() ?*wchar_t;
pub extern fn Py_GetExecPrefix() ?*wchar_t;
pub extern fn Py_GetPath() ?*wchar_t;
pub extern fn Py_GetVersion() ?*const u8;
pub extern fn Py_GetPlatform() ?*const u8;
pub extern fn Py_GetCopyright() ?*const u8;
pub extern fn Py_GetCompiler() ?*const u8;
pub extern fn Py_GetBuildInfo() ?*const u8;
pub const PyOS_sighandler_t = ?*const fn (c_int) callconv(.c) void;
pub extern fn PyOS_getsig(c_int) PyOS_sighandler_t;
pub extern fn PyOS_setsig(c_int, PyOS_sighandler_t) PyOS_sighandler_t;
pub extern const Py_Version: c_ulong;
pub extern fn Py_IsFinalizing() c_int;
pub extern fn Py_FrozenMain(argc: c_int, argv: ?*?*u8) c_int;
pub extern fn Py_PreInitialize(src_config: ?*const PyPreConfig) PyStatus;
pub extern fn Py_PreInitializeFromBytesArgs(src_config: ?*const PyPreConfig, argc: Py_ssize_t, argv: ?*?*u8) PyStatus;
pub extern fn Py_PreInitializeFromArgs(src_config: ?*const PyPreConfig, argc: Py_ssize_t, argv: ?*?*wchar_t) PyStatus;
pub extern fn Py_InitializeFromConfig(config: ?*const PyConfig) PyStatus;
pub extern fn _Py_InitializeMain() PyStatus;
pub extern fn Py_RunMain() c_int;
pub extern fn Py_ExitStatusException(err: PyStatus) noreturn;
pub extern fn Py_FdIsInteractive(?*FILE, ?*const u8) c_int;
pub const PyInterpreterConfig = extern struct {
    use_main_obmalloc: c_int = std.mem.zeroes(c_int),
    allow_fork: c_int = std.mem.zeroes(c_int),
    allow_exec: c_int = std.mem.zeroes(c_int),
    allow_threads: c_int = std.mem.zeroes(c_int),
    allow_daemon_threads: c_int = std.mem.zeroes(c_int),
    check_multi_interp_extensions: c_int = std.mem.zeroes(c_int),
    gil: c_int = std.mem.zeroes(c_int),
};
pub extern fn Py_NewInterpreterFromConfig(tstate_p: ?*?*PyThreadState, config: ?*const PyInterpreterConfig) PyStatus;
pub const atexit_datacallbackfunc = ?*const fn (?*anyopaque) callconv(.c) void;
pub extern fn PyUnstable_AtExit(?*PyInterpreterState, atexit_datacallbackfunc, ?*anyopaque) c_int;
pub extern fn PyEval_EvalCode(?*PyObject, ?*PyObject, ?*PyObject) ?*PyObject;
pub extern fn PyEval_EvalCodeEx(co: ?*PyObject, globals: ?*PyObject, locals: ?*PyObject, args: ?*const ?*PyObject, argc: c_int, kwds: ?*const ?*PyObject, kwdc: c_int, defs: ?*const ?*PyObject, defc: c_int, kwdefs: ?*PyObject, closure: ?*PyObject) ?*PyObject;
pub extern fn PyEval_GetBuiltins() ?*PyObject;
pub extern fn PyEval_GetGlobals() ?*PyObject;
pub extern fn PyEval_GetLocals() ?*PyObject;
pub extern fn PyEval_GetFrame() ?*PyFrameObject;
pub extern fn PyEval_GetFrameBuiltins() ?*PyObject;
pub extern fn PyEval_GetFrameGlobals() ?*PyObject;
pub extern fn PyEval_GetFrameLocals() ?*PyObject;
pub extern fn Py_AddPendingCall(func: ?*const fn (?*anyopaque) callconv(.c) c_int, arg: ?*anyopaque) c_int;
pub extern fn Py_MakePendingCalls() c_int;
pub extern fn Py_SetRecursionLimit(c_int) void;
pub extern fn Py_GetRecursionLimit() c_int;
pub extern fn Py_EnterRecursiveCall(where: ?*const u8) c_int;
pub extern fn Py_LeaveRecursiveCall() void;
pub extern fn PyEval_GetFuncName(?*PyObject) ?*const u8;
pub extern fn PyEval_GetFuncDesc(?*PyObject) ?*const u8;
pub extern fn PyEval_EvalFrame(?*PyFrameObject) ?*PyObject;
pub extern fn PyEval_EvalFrameEx(f: ?*PyFrameObject, exc: c_int) ?*PyObject;
pub extern fn PyEval_SaveThread() ?*PyThreadState;
pub extern fn PyEval_RestoreThread(?*PyThreadState) void;
pub extern fn PyEval_InitThreads() void;
pub extern fn PyEval_AcquireThread(tstate: ?*PyThreadState) void;
pub extern fn PyEval_ReleaseThread(tstate: ?*PyThreadState) void;
pub extern fn PyEval_SetProfile(Py_tracefunc, ?*PyObject) void;
pub extern fn PyEval_SetProfileAllThreads(Py_tracefunc, ?*PyObject) void;
pub extern fn PyEval_SetTrace(Py_tracefunc, ?*PyObject) void;
pub extern fn PyEval_SetTraceAllThreads(Py_tracefunc, ?*PyObject) void;
pub extern fn PyEval_MergeCompilerFlags(cf: ?*PyCompilerFlags) c_int;
pub extern fn _PyEval_EvalFrameDefault(tstate: ?*PyThreadState, f: ?*struct__PyInterpreterFrame, exc: c_int) ?*PyObject;
pub extern fn PyUnstable_Eval_RequestCodeExtraIndex(freefunc) Py_ssize_t;
pub fn _PyEval_RequestCodeExtraIndex(arg_f: freefunc) callconv(.c) Py_ssize_t {
    var f = arg_f;
    _ = &f;
    return PyUnstable_Eval_RequestCodeExtraIndex(f);
}
pub extern fn _PyEval_SliceIndex(?*PyObject, ?*Py_ssize_t) c_int;
pub extern fn _PyEval_SliceIndexNotNone(?*PyObject, ?*Py_ssize_t) c_int;
pub extern fn PySys_GetObject(?*const u8) ?*PyObject;
pub extern fn PySys_SetObject(?*const u8, ?*PyObject) c_int;
pub extern fn PySys_SetArgv(c_int, ?*?*wchar_t) void;
pub extern fn PySys_SetArgvEx(c_int, ?*?*wchar_t, c_int) void;
pub extern fn PySys_WriteStdout(format: ?*const u8, ...) void;
pub extern fn PySys_WriteStderr(format: ?*const u8, ...) void;
pub extern fn PySys_FormatStdout(format: ?*const u8, ...) void;
pub extern fn PySys_FormatStderr(format: ?*const u8, ...) void;
pub extern fn PySys_ResetWarnOptions() void;
pub extern fn PySys_GetXOptions() ?*PyObject;
pub extern fn PySys_Audit(event: ?*const u8, argFormat: ?*const u8, ...) c_int;
pub extern fn PySys_AuditTuple(event: ?*const u8, args: ?*PyObject) c_int;
pub const Py_AuditHookFunction = ?*const fn (?*const u8, ?*PyObject, ?*anyopaque) callconv(.c) c_int;
pub extern fn PySys_AddAuditHook(Py_AuditHookFunction, ?*anyopaque) c_int;
pub const PerfMapState = extern struct {
    perf_map: ?*FILE = std.mem.zeroes(?*FILE),
    map_lock: PyThread_type_lock = std.mem.zeroes(PyThread_type_lock),
};
pub extern fn PyUnstable_PerfMapState_Init() c_int;
pub extern fn PyUnstable_WritePerfMapEntry(code_addr: ?*const anyopaque, code_size: c_uint, entry_name: ?*const u8) c_int;
pub extern fn PyUnstable_PerfMapState_Fini() void;
pub extern fn PyUnstable_CopyPerfMapFile(parent_filename: ?*const u8) c_int;
pub extern fn PyUnstable_PerfTrampoline_CompileCode(?*PyCodeObject) c_int;
pub extern fn PyUnstable_PerfTrampoline_SetPersistAfterFork(enable: c_int) c_int;
pub extern fn PyOS_FSPath(path: ?*PyObject) ?*PyObject;
pub extern fn PyOS_InterruptOccurred() c_int;
pub extern fn PyOS_BeforeFork() void;
pub extern fn PyOS_AfterFork_Parent() void;
pub extern fn PyOS_AfterFork_Child() void;
pub extern fn PyOS_AfterFork() void;
pub extern fn PyImport_GetMagicNumber() c_long;
pub extern fn PyImport_GetMagicTag() ?*const u8;
pub extern fn PyImport_ExecCodeModule(name: ?*const u8, co: ?*PyObject) ?*PyObject;
pub extern fn PyImport_ExecCodeModuleEx(name: ?*const u8, co: ?*PyObject, pathname: ?*const u8) ?*PyObject;
pub extern fn PyImport_ExecCodeModuleWithPathnames(name: ?*const u8, co: ?*PyObject, pathname: ?*const u8, cpathname: ?*const u8) ?*PyObject;
pub extern fn PyImport_ExecCodeModuleObject(name: ?*PyObject, co: ?*PyObject, pathname: ?*PyObject, cpathname: ?*PyObject) ?*PyObject;
pub extern fn PyImport_GetModuleDict() ?*PyObject;
pub extern fn PyImport_GetModule(name: ?*PyObject) ?*PyObject;
pub extern fn PyImport_AddModuleObject(name: ?*PyObject) ?*PyObject;
pub extern fn PyImport_AddModule(name: ?*const u8) ?*PyObject;
pub extern fn PyImport_AddModuleRef(name: ?*const u8) ?*PyObject;
pub extern fn PyImport_ImportModule(name: [*]const u8) ?*PyObject;
pub extern fn PyImport_ImportModuleNoBlock(name: ?*const u8) ?*PyObject;
pub extern fn PyImport_ImportModuleLevel(name: ?*const u8, globals: ?*PyObject, locals: ?*PyObject, fromlist: ?*PyObject, level: c_int) ?*PyObject;
pub extern fn PyImport_ImportModuleLevelObject(name: ?*PyObject, globals: ?*PyObject, locals: ?*PyObject, fromlist: ?*PyObject, level: c_int) ?*PyObject;
pub extern fn PyImport_GetImporter(path: ?*PyObject) ?*PyObject;
pub extern fn PyImport_Import(name: ?*PyObject) ?*PyObject;
pub extern fn PyImport_ReloadModule(m: ?*PyObject) ?*PyObject;
pub extern fn PyImport_ImportFrozenModuleObject(name: ?*PyObject) c_int;
pub extern fn PyImport_ImportFrozenModule(name: ?*const u8) c_int;
pub extern fn PyImport_AppendInittab(name: ?*const u8, initfunc: ?*const fn () callconv(.c) ?*PyObject) c_int;
pub extern fn PyInit__imp() ?*PyObject;
pub const struct__inittab = extern struct {
    name: ?*const u8 = std.mem.zeroes(?*const u8),
    initfunc: ?*const fn () callconv(.c) ?*PyObject = std.mem.zeroes(?*const fn () callconv(.c) ?*PyObject),
};
pub extern var PyImport_Inittab: ?*struct__inittab;
pub extern fn PyImport_ExtendInittab(newtab: ?*struct__inittab) c_int;
pub const struct__frozen = extern struct {
    name: ?*const u8 = std.mem.zeroes(?*const u8),
    code: ?*const u8 = std.mem.zeroes(?*const u8),
    size: c_int = std.mem.zeroes(c_int),
    is_package: c_int = std.mem.zeroes(c_int),
};
pub extern var PyImport_FrozenModules: ?*const struct__frozen;
pub extern fn PyObject_CallNoArgs(func: *PyObject) ?*PyObject;
pub extern fn PyObject_Call(callable: *PyObject, args: *PyObject, kwargs: *PyObject) ?*PyObject;
pub extern fn PyObject_CallObject(callable: *PyObject, args: *PyObject) ?*PyObject;
pub extern fn PyObject_CallFunction(callable: *PyObject, format: *const u8, ...) ?*PyObject;
pub extern fn PyObject_CallMethod(obj: *PyObject, name: *const u8, format: *const u8, ...) ?*PyObject;
pub extern fn PyObject_CallFunctionObjArgs(callable: *PyObject, ...) ?*PyObject;
pub extern fn PyObject_CallMethodObjArgs(obj: *PyObject, name: *PyObject, ...) ?*PyObject;
pub extern fn PyVectorcall_NARGS(nargsf: usize) Py_ssize_t;
pub extern fn PyVectorcall_Call(callable: *PyObject, tuple: ?*PyObject, dict: ?*PyObject) ?*PyObject;
pub extern fn PyObject_Vectorcall(callable: *PyObject, args: [*]const *PyObject, nargsf: usize, kwnames: ?*PyObject) ?*PyObject;
pub extern fn PyObject_VectorcallMethod(name: *PyObject, args: [*]const *PyObject, nargsf: usize, kwnames: ?*PyObject) ?*PyObject;
pub extern fn PyObject_Type(o: ?*PyObject) ?*PyObject;
pub extern fn PyObject_Size(o: ?*PyObject) Py_ssize_t;
pub extern fn PyObject_Length(o: ?*PyObject) Py_ssize_t;
pub extern fn PyObject_GetItem(o: ?*PyObject, key: ?*PyObject) ?*PyObject;
pub extern fn PyObject_SetItem(o: ?*PyObject, key: ?*PyObject, v: ?*PyObject) c_int;
pub extern fn PyObject_DelItemString(o: ?*PyObject, key: ?*const u8) c_int;
pub extern fn PyObject_DelItem(o: ?*PyObject, key: ?*PyObject) c_int;
pub extern fn PyObject_Format(obj: ?*PyObject, format_spec: ?*PyObject) ?*PyObject;
pub extern fn PyObject_GetIter(?*PyObject) ?*PyObject;
pub extern fn PyObject_GetAIter(?*PyObject) ?*PyObject;
pub extern fn PyIter_Check(?*PyObject) c_int;
pub extern fn PyAIter_Check(?*PyObject) c_int;
pub extern fn PyIter_Next(?*PyObject) ?*PyObject;
pub extern fn PyIter_Send(?*PyObject, ?*PyObject, ?*?*PyObject) PySendResult;
pub extern fn PyNumber_Check(o: ?*PyObject) c_int;
pub extern fn PyNumber_Add(o1: ?*PyObject, o2: ?*PyObject) ?*PyObject;
pub extern fn PyNumber_Subtract(o1: ?*PyObject, o2: ?*PyObject) ?*PyObject;
pub extern fn PyNumber_Multiply(o1: ?*PyObject, o2: ?*PyObject) ?*PyObject;
pub extern fn PyNumber_MatrixMultiply(o1: ?*PyObject, o2: ?*PyObject) ?*PyObject;
pub extern fn PyNumber_FloorDivide(o1: ?*PyObject, o2: ?*PyObject) ?*PyObject;
pub extern fn PyNumber_TrueDivide(o1: ?*PyObject, o2: ?*PyObject) ?*PyObject;
pub extern fn PyNumber_Remainder(o1: ?*PyObject, o2: ?*PyObject) ?*PyObject;
pub extern fn PyNumber_Divmod(o1: ?*PyObject, o2: ?*PyObject) ?*PyObject;
pub extern fn PyNumber_Power(o1: ?*PyObject, o2: ?*PyObject, o3: ?*PyObject) ?*PyObject;
pub extern fn PyNumber_Negative(o: ?*PyObject) ?*PyObject;
pub extern fn PyNumber_Positive(o: ?*PyObject) ?*PyObject;
pub extern fn PyNumber_Absolute(o: ?*PyObject) ?*PyObject;
pub extern fn PyNumber_Invert(o: ?*PyObject) ?*PyObject;
pub extern fn PyNumber_Lshift(o1: ?*PyObject, o2: ?*PyObject) ?*PyObject;
pub extern fn PyNumber_Rshift(o1: ?*PyObject, o2: ?*PyObject) ?*PyObject;
pub extern fn PyNumber_And(o1: ?*PyObject, o2: ?*PyObject) ?*PyObject;
pub extern fn PyNumber_Xor(o1: ?*PyObject, o2: ?*PyObject) ?*PyObject;
pub extern fn PyNumber_Or(o1: ?*PyObject, o2: ?*PyObject) ?*PyObject;
pub extern fn PyIndex_Check(?*PyObject) c_int;
pub extern fn PyNumber_Index(o: ?*PyObject) ?*PyObject;
pub extern fn PyNumber_AsSsize_t(o: ?*PyObject, exc: ?*PyObject) Py_ssize_t;
pub extern fn PyNumber_Long(o: ?*PyObject) ?*PyObject;
pub extern fn PyNumber_Float(o: ?*PyObject) ?*PyObject;
pub extern fn PyNumber_InPlaceAdd(o1: ?*PyObject, o2: ?*PyObject) ?*PyObject;
pub extern fn PyNumber_InPlaceSubtract(o1: ?*PyObject, o2: ?*PyObject) ?*PyObject;
pub extern fn PyNumber_InPlaceMultiply(o1: ?*PyObject, o2: ?*PyObject) ?*PyObject;
pub extern fn PyNumber_InPlaceMatrixMultiply(o1: ?*PyObject, o2: ?*PyObject) ?*PyObject;
pub extern fn PyNumber_InPlaceFloorDivide(o1: ?*PyObject, o2: ?*PyObject) ?*PyObject;
pub extern fn PyNumber_InPlaceTrueDivide(o1: ?*PyObject, o2: ?*PyObject) ?*PyObject;
pub extern fn PyNumber_InPlaceRemainder(o1: ?*PyObject, o2: ?*PyObject) ?*PyObject;
pub extern fn PyNumber_InPlacePower(o1: ?*PyObject, o2: ?*PyObject, o3: ?*PyObject) ?*PyObject;
pub extern fn PyNumber_InPlaceLshift(o1: ?*PyObject, o2: ?*PyObject) ?*PyObject;
pub extern fn PyNumber_InPlaceRshift(o1: ?*PyObject, o2: ?*PyObject) ?*PyObject;
pub extern fn PyNumber_InPlaceAnd(o1: ?*PyObject, o2: ?*PyObject) ?*PyObject;
pub extern fn PyNumber_InPlaceXor(o1: ?*PyObject, o2: ?*PyObject) ?*PyObject;
pub extern fn PyNumber_InPlaceOr(o1: ?*PyObject, o2: ?*PyObject) ?*PyObject;
pub extern fn PyNumber_ToBase(n: ?*PyObject, base: c_int) ?*PyObject;
pub extern fn PySequence_Check(o: ?*PyObject) c_int;
pub extern fn PySequence_Size(o: ?*PyObject) Py_ssize_t;
pub extern fn PySequence_Length(o: ?*PyObject) Py_ssize_t;
pub extern fn PySequence_Concat(o1: ?*PyObject, o2: ?*PyObject) ?*PyObject;
pub extern fn PySequence_Repeat(o: ?*PyObject, count: Py_ssize_t) ?*PyObject;
pub extern fn PySequence_GetItem(o: ?*PyObject, i: Py_ssize_t) ?*PyObject;
pub extern fn PySequence_GetSlice(o: ?*PyObject, @"i1": Py_ssize_t, @"i2": Py_ssize_t) ?*PyObject;
pub extern fn PySequence_SetItem(o: ?*PyObject, i: Py_ssize_t, v: ?*PyObject) c_int;
pub extern fn PySequence_DelItem(o: ?*PyObject, i: Py_ssize_t) c_int;
pub extern fn PySequence_SetSlice(o: ?*PyObject, @"i1": Py_ssize_t, @"i2": Py_ssize_t, v: ?*PyObject) c_int;
pub extern fn PySequence_DelSlice(o: ?*PyObject, @"i1": Py_ssize_t, @"i2": Py_ssize_t) c_int;
pub extern fn PySequence_Tuple(o: ?*PyObject) ?*PyObject;
pub extern fn PySequence_List(o: ?*PyObject) ?*PyObject;
pub extern fn PySequence_Fast(o: ?*PyObject, m: ?*const u8) ?*PyObject;
pub extern fn PySequence_Count(o: ?*PyObject, value: ?*PyObject) Py_ssize_t;
pub extern fn PySequence_Contains(seq: ?*PyObject, ob: ?*PyObject) c_int;
pub extern fn PySequence_In(o: ?*PyObject, value: ?*PyObject) c_int;
pub extern fn PySequence_Index(o: ?*PyObject, value: ?*PyObject) Py_ssize_t;
pub extern fn PySequence_InPlaceConcat(o1: ?*PyObject, o2: ?*PyObject) ?*PyObject;
pub extern fn PySequence_InPlaceRepeat(o: ?*PyObject, count: Py_ssize_t) ?*PyObject;
pub extern fn PyMapping_Check(o: ?*PyObject) c_int;
pub extern fn PyMapping_Size(o: ?*PyObject) Py_ssize_t;
pub extern fn PyMapping_Length(o: ?*PyObject) Py_ssize_t;
pub extern fn PyMapping_HasKeyString(o: ?*PyObject, key: ?*const u8) c_int;
pub extern fn PyMapping_HasKey(o: ?*PyObject, key: ?*PyObject) c_int;
pub extern fn PyMapping_HasKeyWithError(o: ?*PyObject, key: ?*PyObject) c_int;
pub extern fn PyMapping_HasKeyStringWithError(o: ?*PyObject, key: ?*const u8) c_int;
pub extern fn PyMapping_Keys(o: ?*PyObject) ?*PyObject;
pub extern fn PyMapping_Values(o: ?*PyObject) ?*PyObject;
pub extern fn PyMapping_Items(o: ?*PyObject) ?*PyObject;
pub extern fn PyMapping_GetItemString(o: ?*PyObject, key: ?*const u8) ?*PyObject;
pub extern fn PyMapping_GetOptionalItem(?*PyObject, ?*PyObject, ?*?*PyObject) c_int;
pub extern fn PyMapping_GetOptionalItemString(?*PyObject, ?*const u8, ?*?*PyObject) c_int;
pub extern fn PyMapping_SetItemString(o: ?*PyObject, key: ?*const u8, value: ?*PyObject) c_int;
pub extern fn PyObject_IsInstance(object: ?*PyObject, typeorclass: ?*PyObject) c_int;
pub extern fn PyObject_IsSubclass(object: ?*PyObject, typeorclass: ?*PyObject) c_int;
pub extern fn _PyObject_CallMethodId(obj: ?*PyObject, name: ?*_Py_Identifier, format: ?*const u8, ...) ?*PyObject;
pub extern fn _PyStack_AsDict(values: ?*const ?*PyObject, kwnames: ?*PyObject) ?*PyObject;
pub fn _PyVectorcall_NARGS(arg_n: usize) callconv(.c) Py_ssize_t {
    var n = arg_n;
    _ = &n;
    return @as(Py_ssize_t, @bitCast(n & ~(@as(usize, @bitCast(@as(c_long, @as(c_int, 1)))) << @intCast((@as(c_ulong, @bitCast(@as(c_long, @as(c_int, 8)))) *% @sizeOf(usize)) -% @as(c_ulong, @bitCast(@as(c_long, @as(c_int, 1))))))));
}
pub extern fn PyVectorcall_Function(callable: ?*PyObject) vectorcallfunc;
pub extern fn PyObject_VectorcallDict(callable: ?*PyObject, args: ?*const ?*PyObject, nargsf: usize, kwargs: ?*PyObject) ?*PyObject;
pub extern fn PyObject_CallOneArg(func: ?*PyObject, arg: ?*PyObject) ?*PyObject;
pub fn PyObject_CallMethodNoArgs(arg_self: ?*PyObject, arg_name: ?*PyObject) callconv(.c) ?*PyObject {
    var self = arg_self;
    _ = &self;
    var name = arg_name;
    _ = &name;
    var nargsf: usize = @as(usize, @bitCast(@as(c_long, @as(c_int, 1)))) | (@as(usize, @bitCast(@as(c_long, @as(c_int, 1)))) << @intCast((@as(c_ulong, @bitCast(@as(c_long, @as(c_int, 8)))) *% @sizeOf(usize)) -% @as(c_ulong, @bitCast(@as(c_long, @as(c_int, 1))))));
    _ = &nargsf;
    return PyObject_VectorcallMethod(name, &self, nargsf, null);
}
pub fn PyObject_CallMethodOneArg(arg_self: ?*PyObject, arg_name: ?*PyObject, arg_arg: ?*PyObject) callconv(.c) ?*PyObject {
    var self = arg_self;
    _ = &self;
    var name = arg_name;
    _ = &name;
    var arg = arg_arg;
    _ = &arg;
    var args: [2]?*PyObject = [2]?*PyObject{
        self,
        arg,
    };
    _ = &args;
    var nargsf: usize = @as(usize, @bitCast(@as(c_long, @as(c_int, 2)))) | (@as(usize, @bitCast(@as(c_long, @as(c_int, 1)))) << @intCast((@as(c_ulong, @bitCast(@as(c_long, @as(c_int, 8)))) *% @sizeOf(usize)) -% @as(c_ulong, @bitCast(@as(c_long, @as(c_int, 1))))));
    _ = &nargsf;
    _ = blk: {
        _ = @sizeOf(c_int);
        break :blk blk_1: {
            break :blk_1 if (arg != @as(?*PyObject, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0))))))) {} else {
                __assert_fail("arg != NULL", "/usr/include/python3.13/cpython/abstract.h", @as(c_uint, @bitCast(@as(c_int, 73))), "PyObject *PyObject_CallMethodOneArg(PyObject *, PyObject *, PyObject *)");
            };
        };
    };
    return PyObject_VectorcallMethod(name, @as(?*?*PyObject, @ptrCast(@alignCast(&args))), nargsf, null);
}
pub extern fn PyObject_LengthHint(o: ?*PyObject, Py_ssize_t) Py_ssize_t;
pub extern var PyFilter_Type: PyTypeObject;
pub extern var PyMap_Type: PyTypeObject;
pub extern var PyZip_Type: PyTypeObject;
pub const struct_PyCriticalSection = opaque {};
pub const PyCriticalSection = struct_PyCriticalSection;
pub const struct_PyCriticalSection2 = opaque {};
pub const PyCriticalSection2 = struct_PyCriticalSection2;
pub extern fn PyCriticalSection_Begin(c: ?*PyCriticalSection, op: ?*PyObject) void;
pub extern fn PyCriticalSection_End(c: ?*PyCriticalSection) void;
pub extern fn PyCriticalSection2_Begin(c: ?*PyCriticalSection2, a: ?*PyObject, b: ?*PyObject) void;
pub extern fn PyCriticalSection2_End(c: ?*PyCriticalSection2) void;
pub extern const _Py_ctype_table: [256]c_uint;
pub extern const _Py_ctype_tolower: [256]u8;
pub extern const _Py_ctype_toupper: [256]u8;
pub extern fn PyOS_string_to_double(str: ?*const u8, endptr: ?*?*u8, overflow_exception: ?*PyObject) f64;
pub extern fn PyOS_double_to_string(val: f64, format_code: u8, precision: c_int, flags: c_int, @"type": ?*c_int) ?*u8;
pub extern fn PyOS_mystrnicmp(?*const u8, ?*const u8, Py_ssize_t) c_int;
pub extern fn PyOS_mystricmp(?*const u8, ?*const u8) c_int;
pub extern fn Py_DecodeLocale(arg: ?*const u8, size: ?*usize) ?*wchar_t;
pub extern fn Py_EncodeLocale(text: ?*const wchar_t, error_pos: ?*usize) ?*u8;
pub extern fn _Py_fopen_obj(path: ?*PyObject, mode: ?*const u8) ?*FILE;
pub extern fn PyTraceMalloc_Track(domain: c_uint, ptr: usize, size: usize) c_int;
pub extern fn PyTraceMalloc_Untrack(domain: c_uint, ptr: usize) c_int;
pub const __llvm__ = @as(c_int, 1);
pub const __clang__ = @as(c_int, 1);
pub const __clang_major__ = @as(c_int, 19);
pub const __clang_minor__ = @as(c_int, 1);
pub const __clang_patchlevel__ = @as(c_int, 0);
pub const __clang_version__ = "19.1.0 (https://github.com/ziglang/zig-bootstrap 46b9e66db90230fe62404b27b85a378ccf2c82c2)";
pub const __GNUC__ = @as(c_int, 4);
pub const __GNUC_MINOR__ = @as(c_int, 2);
pub const __GNUC_PATCHLEVEL__ = @as(c_int, 1);
pub const __GXX_ABI_VERSION = @as(c_int, 1002);
pub const __ATOMIC_RELAXED = @as(c_int, 0);
pub const __ATOMIC_CONSUME = @as(c_int, 1);
pub const __ATOMIC_ACQUIRE = @as(c_int, 2);
pub const __ATOMIC_RELEASE = @as(c_int, 3);
pub const __ATOMIC_ACQ_REL = @as(c_int, 4);
pub const __ATOMIC_SEQ_CST = @as(c_int, 5);
pub const __MEMORY_SCOPE_SYSTEM = @as(c_int, 0);
pub const __MEMORY_SCOPE_DEVICE = @as(c_int, 1);
pub const __MEMORY_SCOPE_WRKGRP = @as(c_int, 2);
pub const __MEMORY_SCOPE_WVFRNT = @as(c_int, 3);
pub const __MEMORY_SCOPE_SINGLE = @as(c_int, 4);
pub const __OPENCL_MEMORY_SCOPE_WORK_ITEM = @as(c_int, 0);
pub const __OPENCL_MEMORY_SCOPE_WORK_GROUP = @as(c_int, 1);
pub const __OPENCL_MEMORY_SCOPE_DEVICE = @as(c_int, 2);
pub const __OPENCL_MEMORY_SCOPE_ALL_SVM_DEVICES = @as(c_int, 3);
pub const __OPENCL_MEMORY_SCOPE_SUB_GROUP = @as(c_int, 4);
pub const __FPCLASS_SNAN = @as(c_int, 0x0001);
pub const __FPCLASS_QNAN = @as(c_int, 0x0002);
pub const __FPCLASS_NEGINF = @as(c_int, 0x0004);
pub const __FPCLASS_NEGNORMAL = @as(c_int, 0x0008);
pub const __FPCLASS_NEGSUBNORMAL = @as(c_int, 0x0010);
pub const __FPCLASS_NEGZERO = @as(c_int, 0x0020);
pub const __FPCLASS_POSZERO = @as(c_int, 0x0040);
pub const __FPCLASS_POSSUBNORMAL = @as(c_int, 0x0080);
pub const __FPCLASS_POSNORMAL = @as(c_int, 0x0100);
pub const __FPCLASS_POSINF = @as(c_int, 0x0200);
pub const __PRAGMA_REDEFINE_EXTNAME = @as(c_int, 1);
pub const __VERSION__ = "Clang 19.1.0 (https://github.com/ziglang/zig-bootstrap 46b9e66db90230fe62404b27b85a378ccf2c82c2)";
pub const __OBJC_BOOL_IS_BOOL = @as(c_int, 0);
pub const __CONSTANT_CFSTRINGS__ = @as(c_int, 1);
pub const __clang_literal_encoding__ = "UTF-8";
pub const __clang_wide_literal_encoding__ = "UTF-32";
pub const __ORDER_LITTLE_ENDIAN__ = @as(c_int, 1234);
pub const __ORDER_BIG_ENDIAN__ = @as(c_int, 4321);
pub const __ORDER_PDP_ENDIAN__ = @as(c_int, 3412);
pub const __BYTE_ORDER__ = __ORDER_LITTLE_ENDIAN__;
pub const __LITTLE_ENDIAN__ = @as(c_int, 1);
pub const _LP64 = @as(c_int, 1);
pub const __LP64__ = @as(c_int, 1);
pub const __CHAR_BIT__ = @as(c_int, 8);
pub const __BOOL_WIDTH__ = @as(c_int, 8);
pub const __SHRT_WIDTH__ = @as(c_int, 16);
pub const __INT_WIDTH__ = @as(c_int, 32);
pub const __LONG_WIDTH__ = @as(c_int, 64);
pub const __LLONG_WIDTH__ = @as(c_int, 64);
pub const __BITINT_MAXWIDTH__ = std.zig.c_translation.promoteIntLiteral(c_int, 8388608, .decimal);
pub const __SCHAR_MAX__ = @as(c_int, 127);
pub const __SHRT_MAX__ = @as(c_int, 32767);
pub const __INT_MAX__ = std.zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __LONG_MAX__ = std.zig.c_translation.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __LONG_LONG_MAX__ = @as(c_longlong, 9223372036854775807);
pub const __WCHAR_MAX__ = std.zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __WCHAR_WIDTH__ = @as(c_int, 32);
pub const __WINT_MAX__ = std.zig.c_translation.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const __WINT_WIDTH__ = @as(c_int, 32);
pub const __INTMAX_MAX__ = std.zig.c_translation.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __INTMAX_WIDTH__ = @as(c_int, 64);
pub const __SIZE_MAX__ = std.zig.c_translation.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const __SIZE_WIDTH__ = @as(c_int, 64);
pub const __UINTMAX_MAX__ = std.zig.c_translation.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const __UINTMAX_WIDTH__ = @as(c_int, 64);
pub const __PTRDIFF_MAX__ = std.zig.c_translation.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __PTRDIFF_WIDTH__ = @as(c_int, 64);
pub const __INTPTR_MAX__ = std.zig.c_translation.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __INTPTR_WIDTH__ = @as(c_int, 64);
pub const __UINTPTR_MAX__ = std.zig.c_translation.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const __UINTPTR_WIDTH__ = @as(c_int, 64);
pub const __SIZEOF_DOUBLE__ = @as(c_int, 8);
pub const __SIZEOF_FLOAT__ = @as(c_int, 4);
pub const __SIZEOF_INT__ = @as(c_int, 4);
pub const __SIZEOF_LONG__ = @as(c_int, 8);
pub const __SIZEOF_LONG_DOUBLE__ = @as(c_int, 16);
pub const __SIZEOF_LONG_LONG__ = @as(c_int, 8);
pub const __SIZEOF_POINTER__ = @as(c_int, 8);
pub const __SIZEOF_SHORT__ = @as(c_int, 2);
pub const __SIZEOF_PTRDIFF_T__ = @as(c_int, 8);
pub const __SIZEOF_SIZE_T__ = @as(c_int, 8);
pub const __SIZEOF_WCHAR_T__ = @as(c_int, 4);
pub const __SIZEOF_WINT_T__ = @as(c_int, 4);
pub const __SIZEOF_INT128__ = @as(c_int, 16);
pub const __INTMAX_TYPE__ = c_long;
pub const __INTMAX_FMTd__ = "ld";
pub const __INTMAX_FMTi__ = "li";
pub const __INTMAX_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `L`");
// (no file):95:9
pub const __UINTMAX_TYPE__ = c_ulong;
pub const __UINTMAX_FMTo__ = "lo";
pub const __UINTMAX_FMTu__ = "lu";
pub const __UINTMAX_FMTx__ = "lx";
pub const __UINTMAX_FMTX__ = "lX";
pub const __UINTMAX_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `UL`");
// (no file):101:9
pub const __PTRDIFF_TYPE__ = c_long;
pub const __PTRDIFF_FMTd__ = "ld";
pub const __PTRDIFF_FMTi__ = "li";
pub const __INTPTR_TYPE__ = c_long;
pub const __INTPTR_FMTd__ = "ld";
pub const __INTPTR_FMTi__ = "li";
pub const __SIZE_TYPE__ = c_ulong;
pub const __SIZE_FMTo__ = "lo";
pub const __SIZE_FMTu__ = "lu";
pub const __SIZE_FMTx__ = "lx";
pub const __SIZE_FMTX__ = "lX";
pub const __WCHAR_TYPE__ = c_int;
pub const __WINT_TYPE__ = c_uint;
pub const __SIG_ATOMIC_MAX__ = std.zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __SIG_ATOMIC_WIDTH__ = @as(c_int, 32);
pub const __CHAR16_TYPE__ = c_ushort;
pub const __CHAR32_TYPE__ = c_uint;
pub const __UINTPTR_TYPE__ = c_ulong;
pub const __UINTPTR_FMTo__ = "lo";
pub const __UINTPTR_FMTu__ = "lu";
pub const __UINTPTR_FMTx__ = "lx";
pub const __UINTPTR_FMTX__ = "lX";
pub const __FLT16_DENORM_MIN__ = @as(f16, 5.9604644775390625e-8);
pub const __FLT16_NORM_MAX__ = @as(f16, 6.5504e+4);
pub const __FLT16_HAS_DENORM__ = @as(c_int, 1);
pub const __FLT16_DIG__ = @as(c_int, 3);
pub const __FLT16_DECIMAL_DIG__ = @as(c_int, 5);
pub const __FLT16_EPSILON__ = @as(f16, 9.765625e-4);
pub const __FLT16_HAS_INFINITY__ = @as(c_int, 1);
pub const __FLT16_HAS_QUIET_NAN__ = @as(c_int, 1);
pub const __FLT16_MANT_DIG__ = @as(c_int, 11);
pub const __FLT16_MAX_10_EXP__ = @as(c_int, 4);
pub const __FLT16_MAX_EXP__ = @as(c_int, 16);
pub const __FLT16_MAX__ = @as(f16, 6.5504e+4);
pub const __FLT16_MIN_10_EXP__ = -@as(c_int, 4);
pub const __FLT16_MIN_EXP__ = -@as(c_int, 13);
pub const __FLT16_MIN__ = @as(f16, 6.103515625e-5);
pub const __FLT_DENORM_MIN__ = @as(f32, 1.40129846e-45);
pub const __FLT_NORM_MAX__ = @as(f32, 3.40282347e+38);
pub const __FLT_HAS_DENORM__ = @as(c_int, 1);
pub const __FLT_DIG__ = @as(c_int, 6);
pub const __FLT_DECIMAL_DIG__ = @as(c_int, 9);
pub const __FLT_EPSILON__ = @as(f32, 1.19209290e-7);
pub const __FLT_HAS_INFINITY__ = @as(c_int, 1);
pub const __FLT_HAS_QUIET_NAN__ = @as(c_int, 1);
pub const __FLT_MANT_DIG__ = @as(c_int, 24);
pub const __FLT_MAX_10_EXP__ = @as(c_int, 38);
pub const __FLT_MAX_EXP__ = @as(c_int, 128);
pub const __FLT_MAX__ = @as(f32, 3.40282347e+38);
pub const __FLT_MIN_10_EXP__ = -@as(c_int, 37);
pub const __FLT_MIN_EXP__ = -@as(c_int, 125);
pub const __FLT_MIN__ = @as(f32, 1.17549435e-38);
pub const __DBL_DENORM_MIN__ = @as(f64, 4.9406564584124654e-324);
pub const __DBL_NORM_MAX__ = @as(f64, 1.7976931348623157e+308);
pub const __DBL_HAS_DENORM__ = @as(c_int, 1);
pub const __DBL_DIG__ = @as(c_int, 15);
pub const __DBL_DECIMAL_DIG__ = @as(c_int, 17);
pub const __DBL_EPSILON__ = @as(f64, 2.2204460492503131e-16);
pub const __DBL_HAS_INFINITY__ = @as(c_int, 1);
pub const __DBL_HAS_QUIET_NAN__ = @as(c_int, 1);
pub const __DBL_MANT_DIG__ = @as(c_int, 53);
pub const __DBL_MAX_10_EXP__ = @as(c_int, 308);
pub const __DBL_MAX_EXP__ = @as(c_int, 1024);
pub const __DBL_MAX__ = @as(f64, 1.7976931348623157e+308);
pub const __DBL_MIN_10_EXP__ = -@as(c_int, 307);
pub const __DBL_MIN_EXP__ = -@as(c_int, 1021);
pub const __DBL_MIN__ = @as(f64, 2.2250738585072014e-308);
pub const __LDBL_DENORM_MIN__ = @as(c_longdouble, 3.64519953188247460253e-4951);
pub const __LDBL_NORM_MAX__ = @as(c_longdouble, 1.18973149535723176502e+4932);
pub const __LDBL_HAS_DENORM__ = @as(c_int, 1);
pub const __LDBL_DIG__ = @as(c_int, 18);
pub const __LDBL_DECIMAL_DIG__ = @as(c_int, 21);
pub const __LDBL_EPSILON__ = @as(c_longdouble, 1.08420217248550443401e-19);
pub const __LDBL_HAS_INFINITY__ = @as(c_int, 1);
pub const __LDBL_HAS_QUIET_NAN__ = @as(c_int, 1);
pub const __LDBL_MANT_DIG__ = @as(c_int, 64);
pub const __LDBL_MAX_10_EXP__ = @as(c_int, 4932);
pub const __LDBL_MAX_EXP__ = @as(c_int, 16384);
pub const __LDBL_MAX__ = @as(c_longdouble, 1.18973149535723176502e+4932);
pub const __LDBL_MIN_10_EXP__ = -@as(c_int, 4931);
pub const __LDBL_MIN_EXP__ = -@as(c_int, 16381);
pub const __LDBL_MIN__ = @as(c_longdouble, 3.36210314311209350626e-4932);
pub const __POINTER_WIDTH__ = @as(c_int, 64);
pub const __BIGGEST_ALIGNMENT__ = @as(c_int, 16);
pub const __WINT_UNSIGNED__ = @as(c_int, 1);
pub const __INT8_TYPE__ = i8;
pub const __INT8_FMTd__ = "hhd";
pub const __INT8_FMTi__ = "hhi";
pub const __INT8_C_SUFFIX__ = "";
pub const __INT16_TYPE__ = c_short;
pub const __INT16_FMTd__ = "hd";
pub const __INT16_FMTi__ = "hi";
pub const __INT16_C_SUFFIX__ = "";
pub const __INT32_TYPE__ = c_int;
pub const __INT32_FMTd__ = "d";
pub const __INT32_FMTi__ = "i";
pub const __INT32_C_SUFFIX__ = "";
pub const __INT64_TYPE__ = c_long;
pub const __INT64_FMTd__ = "ld";
pub const __INT64_FMTi__ = "li";
pub const __INT64_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `L`");
// (no file):202:9
pub const __UINT8_TYPE__ = u8;
pub const __UINT8_FMTo__ = "hho";
pub const __UINT8_FMTu__ = "hhu";
pub const __UINT8_FMTx__ = "hhx";
pub const __UINT8_FMTX__ = "hhX";
pub const __UINT8_C_SUFFIX__ = "";
pub const __UINT8_MAX__ = @as(c_int, 255);
pub const __INT8_MAX__ = @as(c_int, 127);
pub const __UINT16_TYPE__ = c_ushort;
pub const __UINT16_FMTo__ = "ho";
pub const __UINT16_FMTu__ = "hu";
pub const __UINT16_FMTx__ = "hx";
pub const __UINT16_FMTX__ = "hX";
pub const __UINT16_C_SUFFIX__ = "";
pub const __UINT16_MAX__ = std.zig.c_translation.promoteIntLiteral(c_int, 65535, .decimal);
pub const __INT16_MAX__ = @as(c_int, 32767);
pub const __UINT32_TYPE__ = c_uint;
pub const __UINT32_FMTo__ = "o";
pub const __UINT32_FMTu__ = "u";
pub const __UINT32_FMTx__ = "x";
pub const __UINT32_FMTX__ = "X";
pub const __UINT32_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `U`");
// (no file):224:9
pub const __UINT32_MAX__ = std.zig.c_translation.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const __INT32_MAX__ = std.zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __UINT64_TYPE__ = c_ulong;
pub const __UINT64_FMTo__ = "lo";
pub const __UINT64_FMTu__ = "lu";
pub const __UINT64_FMTx__ = "lx";
pub const __UINT64_FMTX__ = "lX";
pub const __UINT64_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `UL`");
// (no file):232:9
pub const __UINT64_MAX__ = std.zig.c_translation.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const __INT64_MAX__ = std.zig.c_translation.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __INT_LEAST8_TYPE__ = i8;
pub const __INT_LEAST8_MAX__ = @as(c_int, 127);
pub const __INT_LEAST8_WIDTH__ = @as(c_int, 8);
pub const __INT_LEAST8_FMTd__ = "hhd";
pub const __INT_LEAST8_FMTi__ = "hhi";
pub const __UINT_LEAST8_TYPE__ = u8;
pub const __UINT_LEAST8_MAX__ = @as(c_int, 255);
pub const __UINT_LEAST8_FMTo__ = "hho";
pub const __UINT_LEAST8_FMTu__ = "hhu";
pub const __UINT_LEAST8_FMTx__ = "hhx";
pub const __UINT_LEAST8_FMTX__ = "hhX";
pub const __INT_LEAST16_TYPE__ = c_short;
pub const __INT_LEAST16_MAX__ = @as(c_int, 32767);
pub const __INT_LEAST16_WIDTH__ = @as(c_int, 16);
pub const __INT_LEAST16_FMTd__ = "hd";
pub const __INT_LEAST16_FMTi__ = "hi";
pub const __UINT_LEAST16_TYPE__ = c_ushort;
pub const __UINT_LEAST16_MAX__ = std.zig.c_translation.promoteIntLiteral(c_int, 65535, .decimal);
pub const __UINT_LEAST16_FMTo__ = "ho";
pub const __UINT_LEAST16_FMTu__ = "hu";
pub const __UINT_LEAST16_FMTx__ = "hx";
pub const __UINT_LEAST16_FMTX__ = "hX";
pub const __INT_LEAST32_TYPE__ = c_int;
pub const __INT_LEAST32_MAX__ = std.zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __INT_LEAST32_WIDTH__ = @as(c_int, 32);
pub const __INT_LEAST32_FMTd__ = "d";
pub const __INT_LEAST32_FMTi__ = "i";
pub const __UINT_LEAST32_TYPE__ = c_uint;
pub const __UINT_LEAST32_MAX__ = std.zig.c_translation.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const __UINT_LEAST32_FMTo__ = "o";
pub const __UINT_LEAST32_FMTu__ = "u";
pub const __UINT_LEAST32_FMTx__ = "x";
pub const __UINT_LEAST32_FMTX__ = "X";
pub const __INT_LEAST64_TYPE__ = c_long;
pub const __INT_LEAST64_MAX__ = std.zig.c_translation.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __INT_LEAST64_WIDTH__ = @as(c_int, 64);
pub const __INT_LEAST64_FMTd__ = "ld";
pub const __INT_LEAST64_FMTi__ = "li";
pub const __UINT_LEAST64_TYPE__ = c_ulong;
pub const __UINT_LEAST64_MAX__ = std.zig.c_translation.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const __UINT_LEAST64_FMTo__ = "lo";
pub const __UINT_LEAST64_FMTu__ = "lu";
pub const __UINT_LEAST64_FMTx__ = "lx";
pub const __UINT_LEAST64_FMTX__ = "lX";
pub const __INT_FAST8_TYPE__ = i8;
pub const __INT_FAST8_MAX__ = @as(c_int, 127);
pub const __INT_FAST8_WIDTH__ = @as(c_int, 8);
pub const __INT_FAST8_FMTd__ = "hhd";
pub const __INT_FAST8_FMTi__ = "hhi";
pub const __UINT_FAST8_TYPE__ = u8;
pub const __UINT_FAST8_MAX__ = @as(c_int, 255);
pub const __UINT_FAST8_FMTo__ = "hho";
pub const __UINT_FAST8_FMTu__ = "hhu";
pub const __UINT_FAST8_FMTx__ = "hhx";
pub const __UINT_FAST8_FMTX__ = "hhX";
pub const __INT_FAST16_TYPE__ = c_short;
pub const __INT_FAST16_MAX__ = @as(c_int, 32767);
pub const __INT_FAST16_WIDTH__ = @as(c_int, 16);
pub const __INT_FAST16_FMTd__ = "hd";
pub const __INT_FAST16_FMTi__ = "hi";
pub const __UINT_FAST16_TYPE__ = c_ushort;
pub const __UINT_FAST16_MAX__ = std.zig.c_translation.promoteIntLiteral(c_int, 65535, .decimal);
pub const __UINT_FAST16_FMTo__ = "ho";
pub const __UINT_FAST16_FMTu__ = "hu";
pub const __UINT_FAST16_FMTx__ = "hx";
pub const __UINT_FAST16_FMTX__ = "hX";
pub const __INT_FAST32_TYPE__ = c_int;
pub const __INT_FAST32_MAX__ = std.zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __INT_FAST32_WIDTH__ = @as(c_int, 32);
pub const __INT_FAST32_FMTd__ = "d";
pub const __INT_FAST32_FMTi__ = "i";
pub const __UINT_FAST32_TYPE__ = c_uint;
pub const __UINT_FAST32_MAX__ = std.zig.c_translation.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const __UINT_FAST32_FMTo__ = "o";
pub const __UINT_FAST32_FMTu__ = "u";
pub const __UINT_FAST32_FMTx__ = "x";
pub const __UINT_FAST32_FMTX__ = "X";
pub const __INT_FAST64_TYPE__ = c_long;
pub const __INT_FAST64_MAX__ = std.zig.c_translation.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __INT_FAST64_WIDTH__ = @as(c_int, 64);
pub const __INT_FAST64_FMTd__ = "ld";
pub const __INT_FAST64_FMTi__ = "li";
pub const __UINT_FAST64_TYPE__ = c_ulong;
pub const __UINT_FAST64_MAX__ = std.zig.c_translation.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const __UINT_FAST64_FMTo__ = "lo";
pub const __UINT_FAST64_FMTu__ = "lu";
pub const __UINT_FAST64_FMTx__ = "lx";
pub const __UINT_FAST64_FMTX__ = "lX";
pub const __USER_LABEL_PREFIX__ = "";
pub const __FINITE_MATH_ONLY__ = @as(c_int, 0);
pub const __GNUC_STDC_INLINE__ = @as(c_int, 1);
pub const __GCC_ATOMIC_TEST_AND_SET_TRUEVAL = @as(c_int, 1);
pub const __GCC_DESTRUCTIVE_SIZE = @as(c_int, 64);
pub const __GCC_CONSTRUCTIVE_SIZE = @as(c_int, 64);
pub const __CLANG_ATOMIC_BOOL_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_CHAR_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_CHAR16_T_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_CHAR32_T_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_WCHAR_T_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_SHORT_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_INT_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_LONG_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_LLONG_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_POINTER_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_BOOL_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_CHAR_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_CHAR16_T_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_CHAR32_T_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_WCHAR_T_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_SHORT_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_INT_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_LONG_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_LLONG_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_POINTER_LOCK_FREE = @as(c_int, 2);
pub const __NO_INLINE__ = @as(c_int, 1);
pub const __PIC__ = @as(c_int, 2);
pub const __pic__ = @as(c_int, 2);
pub const __FLT_RADIX__ = @as(c_int, 2);
pub const __DECIMAL_DIG__ = __LDBL_DECIMAL_DIG__;
pub const __SSP_STRONG__ = @as(c_int, 2);
pub const __ELF__ = @as(c_int, 1);
pub const __GCC_ASM_FLAG_OUTPUTS__ = @as(c_int, 1);
pub const __code_model_small__ = @as(c_int, 1);
pub const __amd64__ = @as(c_int, 1);
pub const __amd64 = @as(c_int, 1);
pub const __x86_64 = @as(c_int, 1);
pub const __x86_64__ = @as(c_int, 1);
pub const __SEG_GS = @as(c_int, 1);
pub const __SEG_FS = @as(c_int, 1);
pub const __seg_gs = @compileError("unable to translate macro: undefined identifier `address_space`");
// (no file):366:9
pub const __seg_fs = @compileError("unable to translate macro: undefined identifier `address_space`");
// (no file):367:9
pub const __k8 = @as(c_int, 1);
pub const __k8__ = @as(c_int, 1);
pub const __tune_k8__ = @as(c_int, 1);
pub const __REGISTER_PREFIX__ = "";
pub const __NO_MATH_INLINES = @as(c_int, 1);
pub const __AES__ = @as(c_int, 1);
pub const __VAES__ = @as(c_int, 1);
pub const __PCLMUL__ = @as(c_int, 1);
pub const __VPCLMULQDQ__ = @as(c_int, 1);
pub const __LAHF_SAHF__ = @as(c_int, 1);
pub const __LZCNT__ = @as(c_int, 1);
pub const __RDRND__ = @as(c_int, 1);
pub const __FSGSBASE__ = @as(c_int, 1);
pub const __BMI__ = @as(c_int, 1);
pub const __BMI2__ = @as(c_int, 1);
pub const __POPCNT__ = @as(c_int, 1);
pub const __PRFCHW__ = @as(c_int, 1);
pub const __RDSEED__ = @as(c_int, 1);
pub const __ADX__ = @as(c_int, 1);
pub const __MOVBE__ = @as(c_int, 1);
pub const __FMA__ = @as(c_int, 1);
pub const __F16C__ = @as(c_int, 1);
pub const __GFNI__ = @as(c_int, 1);
pub const __SHA__ = @as(c_int, 1);
pub const __FXSR__ = @as(c_int, 1);
pub const __XSAVE__ = @as(c_int, 1);
pub const __XSAVEOPT__ = @as(c_int, 1);
pub const __XSAVEC__ = @as(c_int, 1);
pub const __XSAVES__ = @as(c_int, 1);
pub const __PKU__ = @as(c_int, 1);
pub const __CLFLUSHOPT__ = @as(c_int, 1);
pub const __CLWB__ = @as(c_int, 1);
pub const __SHSTK__ = @as(c_int, 1);
pub const __RDPID__ = @as(c_int, 1);
pub const __WAITPKG__ = @as(c_int, 1);
pub const __MOVDIRI__ = @as(c_int, 1);
pub const __MOVDIR64B__ = @as(c_int, 1);
pub const __PTWRITE__ = @as(c_int, 1);
pub const __INVPCID__ = @as(c_int, 1);
pub const __CRC32__ = @as(c_int, 1);
pub const __AVX2__ = @as(c_int, 1);
pub const __AVX__ = @as(c_int, 1);
pub const __SSE4_2__ = @as(c_int, 1);
pub const __SSE4_1__ = @as(c_int, 1);
pub const __SSSE3__ = @as(c_int, 1);
pub const __SSE3__ = @as(c_int, 1);
pub const __SSE2__ = @as(c_int, 1);
pub const __SSE2_MATH__ = @as(c_int, 1);
pub const __SSE__ = @as(c_int, 1);
pub const __SSE_MATH__ = @as(c_int, 1);
pub const __MMX__ = @as(c_int, 1);
pub const __GCC_HAVE_SYNC_COMPARE_AND_SWAP_1 = @as(c_int, 1);
pub const __GCC_HAVE_SYNC_COMPARE_AND_SWAP_2 = @as(c_int, 1);
pub const __GCC_HAVE_SYNC_COMPARE_AND_SWAP_4 = @as(c_int, 1);
pub const __GCC_HAVE_SYNC_COMPARE_AND_SWAP_8 = @as(c_int, 1);
pub const __GCC_HAVE_SYNC_COMPARE_AND_SWAP_16 = @as(c_int, 1);
pub const __SIZEOF_FLOAT128__ = @as(c_int, 16);
pub const unix = @as(c_int, 1);
pub const __unix = @as(c_int, 1);
pub const __unix__ = @as(c_int, 1);
pub const linux = @as(c_int, 1);
pub const __linux = @as(c_int, 1);
pub const __linux__ = @as(c_int, 1);
pub const __gnu_linux__ = @as(c_int, 1);
pub const __FLOAT128__ = @as(c_int, 1);
pub const __STDC__ = @as(c_int, 1);
pub const __STDC_HOSTED__ = @as(c_int, 1);
pub const __STDC_VERSION__ = @as(c_long, 201710);
pub const __STDC_UTF_16__ = @as(c_int, 1);
pub const __STDC_UTF_32__ = @as(c_int, 1);
pub const __STDC_EMBED_NOT_FOUND__ = @as(c_int, 0);
pub const __STDC_EMBED_FOUND__ = @as(c_int, 1);
pub const __STDC_EMBED_EMPTY__ = @as(c_int, 2);
pub const __GLIBC_MINOR__ = @as(c_int, 39);
pub const _DEBUG = @as(c_int, 1);
pub const __GCC_HAVE_DWARF2_CFI_ASM = @as(c_int, 1);
pub const PY_SSIZE_T_CLEAN = "";
pub const Py_PYTHON_H = "";
pub const PY_RELEASE_LEVEL_ALPHA = @as(c_int, 0xA);
pub const PY_RELEASE_LEVEL_BETA = @as(c_int, 0xB);
pub const PY_RELEASE_LEVEL_GAMMA = @as(c_int, 0xC);
pub const PY_RELEASE_LEVEL_FINAL = @as(c_int, 0xF);
pub const PY_MAJOR_VERSION = @as(c_int, 3);
pub const PY_MINOR_VERSION = @as(c_int, 13);
pub const PY_MICRO_VERSION = @as(c_int, 1);
pub const PY_RELEASE_LEVEL = PY_RELEASE_LEVEL_FINAL;
pub const PY_RELEASE_SERIAL = @as(c_int, 0);
pub const PY_VERSION = "3.13.1";
pub const PY_VERSION_HEX = ((((PY_MAJOR_VERSION << @as(c_int, 24)) | (PY_MINOR_VERSION << @as(c_int, 16))) | (PY_MICRO_VERSION << @as(c_int, 8))) | (PY_RELEASE_LEVEL << @as(c_int, 4))) | (PY_RELEASE_SERIAL << @as(c_int, 0));
pub const Py_PYCONFIG_H = "";
pub const ALIGNOF_LONG = @as(c_int, 8);
pub const ALIGNOF_MAX_ALIGN_T = @as(c_int, 16);
pub const ALIGNOF_SIZE_T = @as(c_int, 8);
pub const DOUBLE_IS_LITTLE_ENDIAN_IEEE754 = @as(c_int, 1);
pub const ENABLE_IPV6 = @as(c_int, 1);
pub const HAVE_ACCEPT = @as(c_int, 1);
pub const HAVE_ACCEPT4 = @as(c_int, 1);
pub const HAVE_ACOSH = @as(c_int, 1);
pub const HAVE_ADDRINFO = @as(c_int, 1);
pub const HAVE_ALARM = @as(c_int, 1);
pub const HAVE_ALLOCA_H = @as(c_int, 1);
pub const HAVE_ASINH = @as(c_int, 1);
pub const HAVE_ASM_TYPES_H = @as(c_int, 1);
pub const HAVE_ATANH = @as(c_int, 1);
pub const HAVE_BIND = @as(c_int, 1);
pub const HAVE_BIND_TEXTDOMAIN_CODESET = @as(c_int, 1);
pub const HAVE_BLUETOOTH_BLUETOOTH_H = @as(c_int, 1);
pub const HAVE_BUILTIN_ATOMIC = @as(c_int, 1);
pub const HAVE_CHMOD = @as(c_int, 1);
pub const HAVE_CHOWN = @as(c_int, 1);
pub const HAVE_CHROOT = @as(c_int, 1);
pub const HAVE_CLOCK = @as(c_int, 1);
pub const HAVE_CLOCK_GETRES = @as(c_int, 1);
pub const HAVE_CLOCK_GETTIME = @as(c_int, 1);
pub const HAVE_CLOCK_NANOSLEEP = @as(c_int, 1);
pub const HAVE_CLOCK_SETTIME = @as(c_int, 1);
pub const HAVE_CLOCK_T = @as(c_int, 1);
pub const HAVE_CLOSEFROM = @as(c_int, 1);
pub const HAVE_CLOSE_RANGE = @as(c_int, 1);
pub const HAVE_COMPUTED_GOTOS = @as(c_int, 1);
pub const HAVE_CONFSTR = @as(c_int, 1);
pub const HAVE_CONNECT = @as(c_int, 1);
pub const HAVE_COPY_FILE_RANGE = @as(c_int, 1);
pub const HAVE_CTERMID = @as(c_int, 1);
pub const HAVE_CURSES_FILTER = @as(c_int, 1);
pub const HAVE_CURSES_H = @as(c_int, 1);
pub const HAVE_CURSES_HAS_KEY = @as(c_int, 1);
pub const HAVE_CURSES_IMMEDOK = @as(c_int, 1);
pub const HAVE_CURSES_IS_PAD = @as(c_int, 1);
pub const HAVE_CURSES_IS_TERM_RESIZED = @as(c_int, 1);
pub const HAVE_CURSES_RESIZETERM = @as(c_int, 1);
pub const HAVE_CURSES_RESIZE_TERM = @as(c_int, 1);
pub const HAVE_CURSES_SYNCOK = @as(c_int, 1);
pub const HAVE_CURSES_TYPEAHEAD = @as(c_int, 1);
pub const HAVE_CURSES_USE_ENV = @as(c_int, 1);
pub const HAVE_CURSES_WCHGAT = @as(c_int, 1);
pub const HAVE_DECL_RTLD_DEEPBIND = @as(c_int, 1);
pub const HAVE_DECL_RTLD_GLOBAL = @as(c_int, 1);
pub const HAVE_DECL_RTLD_LAZY = @as(c_int, 1);
pub const HAVE_DECL_RTLD_LOCAL = @as(c_int, 1);
pub const HAVE_DECL_RTLD_MEMBER = @as(c_int, 0);
pub const HAVE_DECL_RTLD_NODELETE = @as(c_int, 1);
pub const HAVE_DECL_RTLD_NOLOAD = @as(c_int, 1);
pub const HAVE_DECL_RTLD_NOW = @as(c_int, 1);
pub const HAVE_DEVICE_MACROS = @as(c_int, 1);
pub const HAVE_DEV_PTMX = @as(c_int, 1);
pub const HAVE_DIRENT_D_TYPE = @as(c_int, 1);
pub const HAVE_DIRENT_H = @as(c_int, 1);
pub const HAVE_DIRFD = @as(c_int, 1);
pub const HAVE_DLFCN_H = @as(c_int, 1);
pub const HAVE_DLOPEN = @as(c_int, 1);
pub const HAVE_DUP = @as(c_int, 1);
pub const HAVE_DUP2 = @as(c_int, 1);
pub const HAVE_DUP3 = @as(c_int, 1);
pub const HAVE_DYNAMIC_LOADING = @as(c_int, 1);
pub const HAVE_ENDIAN_H = @as(c_int, 1);
pub const HAVE_EPOLL = @as(c_int, 1);
pub const HAVE_EPOLL_CREATE1 = @as(c_int, 1);
pub const HAVE_ERF = @as(c_int, 1);
pub const HAVE_ERFC = @as(c_int, 1);
pub const HAVE_ERRNO_H = @as(c_int, 1);
pub const HAVE_EVENTFD = @as(c_int, 1);
pub const HAVE_EXECV = @as(c_int, 1);
pub const HAVE_EXPLICIT_BZERO = @as(c_int, 1);
pub const HAVE_EXPM1 = @as(c_int, 1);
pub const HAVE_FACCESSAT = @as(c_int, 1);
pub const HAVE_FCHDIR = @as(c_int, 1);
pub const HAVE_FCHMOD = @as(c_int, 1);
pub const HAVE_FCHMODAT = @as(c_int, 1);
pub const HAVE_FCHOWN = @as(c_int, 1);
pub const HAVE_FCHOWNAT = @as(c_int, 1);
pub const HAVE_FCNTL_H = @as(c_int, 1);
pub const HAVE_FDATASYNC = @as(c_int, 1);
pub const HAVE_FDOPENDIR = @as(c_int, 1);
pub const HAVE_FEXECVE = @as(c_int, 1);
pub const HAVE_FFI_CLOSURE_ALLOC = @as(c_int, 1);
pub const HAVE_FFI_PREP_CIF_VAR = @as(c_int, 1);
pub const HAVE_FFI_PREP_CLOSURE_LOC = @as(c_int, 1);
pub const HAVE_FLOCK = @as(c_int, 1);
pub const HAVE_FORK = @as(c_int, 1);
pub const HAVE_FORKPTY = @as(c_int, 1);
pub const HAVE_FPATHCONF = @as(c_int, 1);
pub const HAVE_FSEEKO = @as(c_int, 1);
pub const HAVE_FSTATAT = @as(c_int, 1);
pub const HAVE_FSTATVFS = @as(c_int, 1);
pub const HAVE_FSYNC = @as(c_int, 1);
pub const HAVE_FTELLO = @as(c_int, 1);
pub const HAVE_FTIME = @as(c_int, 1);
pub const HAVE_FTRUNCATE = @as(c_int, 1);
pub const HAVE_FUTIMENS = @as(c_int, 1);
pub const HAVE_FUTIMES = @as(c_int, 1);
pub const HAVE_FUTIMESAT = @as(c_int, 1);
pub const HAVE_GAI_STRERROR = @as(c_int, 1);
pub const HAVE_GCC_ASM_FOR_X64 = @as(c_int, 1);
pub const HAVE_GCC_ASM_FOR_X87 = @as(c_int, 1);
pub const HAVE_GCC_UINT128_T = @as(c_int, 1);
pub const HAVE_GDBM_H = @as(c_int, 1);
pub const HAVE_GETADDRINFO = @as(c_int, 1);
pub const HAVE_GETC_UNLOCKED = @as(c_int, 1);
pub const HAVE_GETEGID = @as(c_int, 1);
pub const HAVE_GETENTROPY = @as(c_int, 1);
pub const HAVE_GETEUID = @as(c_int, 1);
pub const HAVE_GETGID = @as(c_int, 1);
pub const HAVE_GETGRENT = @as(c_int, 1);
pub const HAVE_GETGRGID = @as(c_int, 1);
pub const HAVE_GETGRGID_R = @as(c_int, 1);
pub const HAVE_GETGRNAM_R = @as(c_int, 1);
pub const HAVE_GETGROUPLIST = @as(c_int, 1);
pub const HAVE_GETGROUPS = @as(c_int, 1);
pub const HAVE_GETHOSTBYADDR = @as(c_int, 1);
pub const HAVE_GETHOSTBYNAME = @as(c_int, 1);
pub const HAVE_GETHOSTBYNAME_R = @as(c_int, 1);
pub const HAVE_GETHOSTBYNAME_R_6_ARG = @as(c_int, 1);
pub const HAVE_GETHOSTNAME = @as(c_int, 1);
pub const HAVE_GETITIMER = @as(c_int, 1);
pub const HAVE_GETLOADAVG = @as(c_int, 1);
pub const HAVE_GETLOGIN = @as(c_int, 1);
pub const HAVE_GETNAMEINFO = @as(c_int, 1);
pub const HAVE_GETPAGESIZE = @as(c_int, 1);
pub const HAVE_GETPEERNAME = @as(c_int, 1);
pub const HAVE_GETPGID = @as(c_int, 1);
pub const HAVE_GETPGRP = @as(c_int, 1);
pub const HAVE_GETPID = @as(c_int, 1);
pub const HAVE_GETPPID = @as(c_int, 1);
pub const HAVE_GETPRIORITY = @as(c_int, 1);
pub const HAVE_GETPROTOBYNAME = @as(c_int, 1);
pub const HAVE_GETPWENT = @as(c_int, 1);
pub const HAVE_GETPWNAM_R = @as(c_int, 1);
pub const HAVE_GETPWUID = @as(c_int, 1);
pub const HAVE_GETPWUID_R = @as(c_int, 1);
pub const HAVE_GETRANDOM = @as(c_int, 1);
pub const HAVE_GETRANDOM_SYSCALL = @as(c_int, 1);
pub const HAVE_GETRESGID = @as(c_int, 1);
pub const HAVE_GETRESUID = @as(c_int, 1);
pub const HAVE_GETRUSAGE = @as(c_int, 1);
pub const HAVE_GETSERVBYNAME = @as(c_int, 1);
pub const HAVE_GETSERVBYPORT = @as(c_int, 1);
pub const HAVE_GETSID = @as(c_int, 1);
pub const HAVE_GETSOCKNAME = @as(c_int, 1);
pub const HAVE_GETSPENT = @as(c_int, 1);
pub const HAVE_GETSPNAM = @as(c_int, 1);
pub const HAVE_GETUID = @as(c_int, 1);
pub const HAVE_GETWD = @as(c_int, 1);
pub const HAVE_GRANTPT = @as(c_int, 1);
pub const HAVE_GRP_H = @as(c_int, 1);
pub const HAVE_HSTRERROR = @as(c_int, 1);
pub const HAVE_HTOLE64 = @as(c_int, 1);
pub const HAVE_IF_NAMEINDEX = @as(c_int, 1);
pub const HAVE_INET_ATON = @as(c_int, 1);
pub const HAVE_INET_NTOA = @as(c_int, 1);
pub const HAVE_INET_PTON = @as(c_int, 1);
pub const HAVE_INITGROUPS = @as(c_int, 1);
pub const HAVE_INTTYPES_H = @as(c_int, 1);
pub const HAVE_KILL = @as(c_int, 1);
pub const HAVE_KILLPG = @as(c_int, 1);
pub const HAVE_LANGINFO_H = @as(c_int, 1);
pub const HAVE_LCHOWN = @as(c_int, 1);
pub const HAVE_LIBDL = @as(c_int, 1);
pub const HAVE_LIBINTL_H = @as(c_int, 1);
pub const HAVE_LIBSQLITE3 = @as(c_int, 1);
pub const HAVE_LINK = @as(c_int, 1);
pub const HAVE_LINKAT = @as(c_int, 1);
pub const HAVE_LINUX_AUXVEC_H = @as(c_int, 1);
pub const HAVE_LINUX_CAN_BCM_H = @as(c_int, 1);
pub const HAVE_LINUX_CAN_H = @as(c_int, 1);
pub const HAVE_LINUX_CAN_J1939_H = @as(c_int, 1);
pub const HAVE_LINUX_CAN_RAW_FD_FRAMES = @as(c_int, 1);
pub const HAVE_LINUX_CAN_RAW_H = @as(c_int, 1);
pub const HAVE_LINUX_CAN_RAW_JOIN_FILTERS = @as(c_int, 1);
pub const HAVE_LINUX_FS_H = @as(c_int, 1);
pub const HAVE_LINUX_LIMITS_H = @as(c_int, 1);
pub const HAVE_LINUX_MEMFD_H = @as(c_int, 1);
pub const HAVE_LINUX_NETLINK_H = @as(c_int, 1);
pub const HAVE_LINUX_QRTR_H = @as(c_int, 1);
pub const HAVE_LINUX_RANDOM_H = @as(c_int, 1);
pub const HAVE_LINUX_SOUNDCARD_H = @as(c_int, 1);
pub const HAVE_LINUX_TIPC_H = @as(c_int, 1);
pub const HAVE_LINUX_VM_SOCKETS_H = @as(c_int, 1);
pub const HAVE_LINUX_WAIT_H = @as(c_int, 1);
pub const HAVE_LISTEN = @as(c_int, 1);
pub const HAVE_LOCKF = @as(c_int, 1);
pub const HAVE_LOG1P = @as(c_int, 1);
pub const HAVE_LOG2 = @as(c_int, 1);
pub const HAVE_LOGIN_TTY = @as(c_int, 1);
pub const HAVE_LONG_DOUBLE = @as(c_int, 1);
pub const HAVE_LSTAT = @as(c_int, 1);
pub const HAVE_LUTIMES = @as(c_int, 1);
pub const HAVE_MADVISE = @as(c_int, 1);
pub const HAVE_MAKEDEV = @as(c_int, 1);
pub const HAVE_MBRTOWC = @as(c_int, 1);
pub const HAVE_MEMFD_CREATE = @as(c_int, 1);
pub const HAVE_MEMRCHR = @as(c_int, 1);
pub const HAVE_MKDIRAT = @as(c_int, 1);
pub const HAVE_MKFIFO = @as(c_int, 1);
pub const HAVE_MKFIFOAT = @as(c_int, 1);
pub const HAVE_MKNOD = @as(c_int, 1);
pub const HAVE_MKNODAT = @as(c_int, 1);
pub const HAVE_MKTIME = @as(c_int, 1);
pub const HAVE_MMAP = @as(c_int, 1);
pub const HAVE_MREMAP = @as(c_int, 1);
pub const HAVE_NANOSLEEP = @as(c_int, 1);
pub const HAVE_NCURSESW = @as(c_int, 1);
pub const HAVE_NCURSES_H = @as(c_int, 1);
pub const HAVE_NDBM_H = @as(c_int, 1);
pub const HAVE_NETDB_H = @as(c_int, 1);
pub const HAVE_NETINET_IN_H = @as(c_int, 1);
pub const HAVE_NETPACKET_PACKET_H = @as(c_int, 1);
pub const HAVE_NET_ETHERNET_H = @as(c_int, 1);
pub const HAVE_NET_IF_H = @as(c_int, 1);
pub const HAVE_NICE = @as(c_int, 1);
pub const HAVE_OPENAT = @as(c_int, 1);
pub const HAVE_OPENDIR = @as(c_int, 1);
pub const HAVE_OPENPTY = @as(c_int, 1);
pub const HAVE_PANELW = @as(c_int, 1);
pub const HAVE_PANEL_H = @as(c_int, 1);
pub const HAVE_PATHCONF = @as(c_int, 1);
pub const HAVE_PAUSE = @as(c_int, 1);
pub const HAVE_PIPE = @as(c_int, 1);
pub const HAVE_PIPE2 = @as(c_int, 1);
pub const HAVE_POLL = @as(c_int, 1);
pub const HAVE_POLL_H = @as(c_int, 1);
pub const HAVE_POSIX_FADVISE = @as(c_int, 1);
pub const HAVE_POSIX_FALLOCATE = @as(c_int, 1);
pub const HAVE_POSIX_OPENPT = @as(c_int, 1);
pub const HAVE_POSIX_SPAWN = @as(c_int, 1);
pub const HAVE_POSIX_SPAWNP = @as(c_int, 1);
pub const HAVE_POSIX_SPAWN_FILE_ACTIONS_ADDCLOSEFROM_NP = @as(c_int, 1);
pub const HAVE_PREAD = @as(c_int, 1);
pub const HAVE_PREADV = @as(c_int, 1);
pub const HAVE_PREADV2 = @as(c_int, 1);
pub const HAVE_PRLIMIT = @as(c_int, 1);
pub const HAVE_PROCESS_VM_READV = @as(c_int, 1);
pub const HAVE_PROTOTYPES = @as(c_int, 1);
pub const HAVE_PTHREAD_CONDATTR_SETCLOCK = @as(c_int, 1);
pub const HAVE_PTHREAD_GETCPUCLOCKID = @as(c_int, 1);
pub const HAVE_PTHREAD_H = @as(c_int, 1);
pub const HAVE_PTHREAD_KILL = @as(c_int, 1);
pub const HAVE_PTHREAD_SIGMASK = @as(c_int, 1);
pub const HAVE_PTSNAME = @as(c_int, 1);
pub const HAVE_PTSNAME_R = @as(c_int, 1);
pub const HAVE_PTY_H = @as(c_int, 1);
pub const HAVE_PWRITE = @as(c_int, 1);
pub const HAVE_PWRITEV = @as(c_int, 1);
pub const HAVE_PWRITEV2 = @as(c_int, 1);
pub const HAVE_READLINK = @as(c_int, 1);
pub const HAVE_READLINKAT = @as(c_int, 1);
pub const HAVE_READV = @as(c_int, 1);
pub const HAVE_REALPATH = @as(c_int, 1);
pub const HAVE_RECVFROM = @as(c_int, 1);
pub const HAVE_RENAMEAT = @as(c_int, 1);
pub const HAVE_RL_APPEND_HISTORY = @as(c_int, 1);
pub const HAVE_RL_CATCH_SIGNAL = @as(c_int, 1);
pub const HAVE_RL_COMPDISP_FUNC_T = @as(c_int, 1);
pub const HAVE_RL_COMPLETION_APPEND_CHARACTER = @as(c_int, 1);
pub const HAVE_RL_COMPLETION_DISPLAY_MATCHES_HOOK = @as(c_int, 1);
pub const HAVE_RL_COMPLETION_MATCHES = @as(c_int, 1);
pub const HAVE_RL_COMPLETION_SUPPRESS_APPEND = @as(c_int, 1);
pub const HAVE_RL_PRE_INPUT_HOOK = @as(c_int, 1);
pub const HAVE_RL_RESIZE_TERMINAL = @as(c_int, 1);
pub const HAVE_SCHED_GET_PRIORITY_MAX = @as(c_int, 1);
pub const HAVE_SCHED_H = @as(c_int, 1);
pub const HAVE_SCHED_RR_GET_INTERVAL = @as(c_int, 1);
pub const HAVE_SCHED_SETAFFINITY = @as(c_int, 1);
pub const HAVE_SCHED_SETPARAM = @as(c_int, 1);
pub const HAVE_SCHED_SETSCHEDULER = @as(c_int, 1);
pub const HAVE_SEM_CLOCKWAIT = @as(c_int, 1);
pub const HAVE_SEM_GETVALUE = @as(c_int, 1);
pub const HAVE_SEM_OPEN = @as(c_int, 1);
pub const HAVE_SEM_TIMEDWAIT = @as(c_int, 1);
pub const HAVE_SEM_UNLINK = @as(c_int, 1);
pub const HAVE_SENDFILE = @as(c_int, 1);
pub const HAVE_SENDTO = @as(c_int, 1);
pub const HAVE_SETEGID = @as(c_int, 1);
pub const HAVE_SETEUID = @as(c_int, 1);
pub const HAVE_SETGID = @as(c_int, 1);
pub const HAVE_SETGROUPS = @as(c_int, 1);
pub const HAVE_SETHOSTNAME = @as(c_int, 1);
pub const HAVE_SETITIMER = @as(c_int, 1);
pub const HAVE_SETJMP_H = @as(c_int, 1);
pub const HAVE_SETLOCALE = @as(c_int, 1);
pub const HAVE_SETNS = @as(c_int, 1);
pub const HAVE_SETPGID = @as(c_int, 1);
pub const HAVE_SETPGRP = @as(c_int, 1);
pub const HAVE_SETPRIORITY = @as(c_int, 1);
pub const HAVE_SETREGID = @as(c_int, 1);
pub const HAVE_SETRESGID = @as(c_int, 1);
pub const HAVE_SETRESUID = @as(c_int, 1);
pub const HAVE_SETREUID = @as(c_int, 1);
pub const HAVE_SETSID = @as(c_int, 1);
pub const HAVE_SETSOCKOPT = @as(c_int, 1);
pub const HAVE_SETUID = @as(c_int, 1);
pub const HAVE_SETVBUF = @as(c_int, 1);
pub const HAVE_SHADOW_H = @as(c_int, 1);
pub const HAVE_SHM_OPEN = @as(c_int, 1);
pub const HAVE_SHM_UNLINK = @as(c_int, 1);
pub const HAVE_SHUTDOWN = @as(c_int, 1);
pub const HAVE_SIGACTION = @as(c_int, 1);
pub const HAVE_SIGALTSTACK = @as(c_int, 1);
pub const HAVE_SIGFILLSET = @as(c_int, 1);
pub const HAVE_SIGINFO_T_SI_BAND = @as(c_int, 1);
pub const HAVE_SIGINTERRUPT = @as(c_int, 1);
pub const HAVE_SIGNAL_H = @as(c_int, 1);
pub const HAVE_SIGPENDING = @as(c_int, 1);
pub const HAVE_SIGRELSE = @as(c_int, 1);
pub const HAVE_SIGTIMEDWAIT = @as(c_int, 1);
pub const HAVE_SIGWAIT = @as(c_int, 1);
pub const HAVE_SIGWAITINFO = @as(c_int, 1);
pub const HAVE_SNPRINTF = @as(c_int, 1);
pub const HAVE_SOCKADDR_ALG = @as(c_int, 1);
pub const HAVE_SOCKADDR_STORAGE = @as(c_int, 1);
pub const HAVE_SOCKET = @as(c_int, 1);
pub const HAVE_SOCKETPAIR = @as(c_int, 1);
pub const HAVE_SOCKLEN_T = @as(c_int, 1);
pub const HAVE_SPAWN_H = @as(c_int, 1);
pub const HAVE_SPLICE = @as(c_int, 1);
pub const HAVE_SSIZE_T = @as(c_int, 1);
pub const HAVE_STATVFS = @as(c_int, 1);
pub const HAVE_STAT_TV_NSEC = @as(c_int, 1);
pub const HAVE_STDINT_H = @as(c_int, 1);
pub const HAVE_STDIO_H = @as(c_int, 1);
pub const HAVE_STDLIB_H = @as(c_int, 1);
pub const HAVE_STD_ATOMIC = @as(c_int, 1);
pub const HAVE_STRFTIME = @as(c_int, 1);
pub const HAVE_STRINGS_H = @as(c_int, 1);
pub const HAVE_STRING_H = @as(c_int, 1);
pub const HAVE_STRLCPY = @as(c_int, 1);
pub const HAVE_STRSIGNAL = @as(c_int, 1);
pub const HAVE_STRUCT_PASSWD_PW_GECOS = @as(c_int, 1);
pub const HAVE_STRUCT_PASSWD_PW_PASSWD = @as(c_int, 1);
pub const HAVE_STRUCT_STAT_ST_BLKSIZE = @as(c_int, 1);
pub const HAVE_STRUCT_STAT_ST_BLOCKS = @as(c_int, 1);
pub const HAVE_STRUCT_STAT_ST_RDEV = @as(c_int, 1);
pub const HAVE_STRUCT_TM_TM_ZONE = @as(c_int, 1);
pub const HAVE_SYMLINK = @as(c_int, 1);
pub const HAVE_SYMLINKAT = @as(c_int, 1);
pub const HAVE_SYNC = @as(c_int, 1);
pub const HAVE_SYSCONF = @as(c_int, 1);
pub const HAVE_SYSEXITS_H = @as(c_int, 1);
pub const HAVE_SYSLOG_H = @as(c_int, 1);
pub const HAVE_SYSTEM = @as(c_int, 1);
pub const HAVE_SYS_AUXV_H = @as(c_int, 1);
pub const HAVE_SYS_EPOLL_H = @as(c_int, 1);
pub const HAVE_SYS_EVENTFD_H = @as(c_int, 1);
pub const HAVE_SYS_FILE_H = @as(c_int, 1);
pub const HAVE_SYS_IOCTL_H = @as(c_int, 1);
pub const HAVE_SYS_MMAN_H = @as(c_int, 1);
pub const HAVE_SYS_PARAM_H = @as(c_int, 1);
pub const HAVE_SYS_POLL_H = @as(c_int, 1);
pub const HAVE_SYS_RANDOM_H = @as(c_int, 1);
pub const HAVE_SYS_RESOURCE_H = @as(c_int, 1);
pub const HAVE_SYS_SELECT_H = @as(c_int, 1);
pub const HAVE_SYS_SENDFILE_H = @as(c_int, 1);
pub const HAVE_SYS_SOCKET_H = @as(c_int, 1);
pub const HAVE_SYS_SOUNDCARD_H = @as(c_int, 1);
pub const HAVE_SYS_STATVFS_H = @as(c_int, 1);
pub const HAVE_SYS_STAT_H = @as(c_int, 1);
pub const HAVE_SYS_SYSCALL_H = @as(c_int, 1);
pub const HAVE_SYS_SYSMACROS_H = @as(c_int, 1);
pub const HAVE_SYS_TIMERFD_H = @as(c_int, 1);
pub const HAVE_SYS_TIMES_H = @as(c_int, 1);
pub const HAVE_SYS_TIME_H = @as(c_int, 1);
pub const HAVE_SYS_TYPES_H = @as(c_int, 1);
pub const HAVE_SYS_UIO_H = @as(c_int, 1);
pub const HAVE_SYS_UN_H = @as(c_int, 1);
pub const HAVE_SYS_UTSNAME_H = @as(c_int, 1);
pub const HAVE_SYS_WAIT_H = @as(c_int, 1);
pub const HAVE_SYS_XATTR_H = @as(c_int, 1);
pub const HAVE_TCGETPGRP = @as(c_int, 1);
pub const HAVE_TCSETPGRP = @as(c_int, 1);
pub const HAVE_TEMPNAM = @as(c_int, 1);
pub const HAVE_TERMIOS_H = @as(c_int, 1);
pub const HAVE_TERM_H = @as(c_int, 1);
pub const HAVE_TIMEGM = @as(c_int, 1);
pub const HAVE_TIMERFD_CREATE = @as(c_int, 1);
pub const HAVE_TIMES = @as(c_int, 1);
pub const HAVE_TMPFILE = @as(c_int, 1);
pub const HAVE_TMPNAM = @as(c_int, 1);
pub const HAVE_TMPNAM_R = @as(c_int, 1);
pub const HAVE_TM_ZONE = @as(c_int, 1);
pub const HAVE_TRUNCATE = @as(c_int, 1);
pub const HAVE_TTYNAME = @as(c_int, 1);
pub const HAVE_UMASK = @as(c_int, 1);
pub const HAVE_UNAME = @as(c_int, 1);
pub const HAVE_UNISTD_H = @as(c_int, 1);
pub const HAVE_UNLINKAT = @as(c_int, 1);
pub const HAVE_UNLOCKPT = @as(c_int, 1);
pub const HAVE_UNSHARE = @as(c_int, 1);
pub const HAVE_UTIMENSAT = @as(c_int, 1);
pub const HAVE_UTIMES = @as(c_int, 1);
pub const HAVE_UTIME_H = @as(c_int, 1);
pub const HAVE_UTMP_H = @as(c_int, 1);
pub const HAVE_UUID_GENERATE_TIME_SAFE = @as(c_int, 1);
pub const HAVE_UUID_H = @as(c_int, 1);
pub const HAVE_VFORK = @as(c_int, 1);
pub const HAVE_WAIT = @as(c_int, 1);
pub const HAVE_WAIT3 = @as(c_int, 1);
pub const HAVE_WAIT4 = @as(c_int, 1);
pub const HAVE_WAITID = @as(c_int, 1);
pub const HAVE_WAITPID = @as(c_int, 1);
pub const HAVE_WCHAR_H = @as(c_int, 1);
pub const HAVE_WCSCOLL = @as(c_int, 1);
pub const HAVE_WCSFTIME = @as(c_int, 1);
pub const HAVE_WCSXFRM = @as(c_int, 1);
pub const HAVE_WMEMCMP = @as(c_int, 1);
pub const HAVE_WORKING_TZSET = @as(c_int, 1);
pub const HAVE_WRITEV = @as(c_int, 1);
pub const HAVE_ZLIB_COPY = @as(c_int, 1);
pub const HAVE___UINT128_T = @as(c_int, 1);
pub const MAJOR_IN_SYSMACROS = @as(c_int, 1);
pub const MVWDELCH_IS_EXPRESSION = @as(c_int, 1);
pub const PTHREAD_KEY_T_IS_COMPATIBLE_WITH_INT = @as(c_int, 1);
pub const PTHREAD_SYSTEM_SCHED_SUPPORTED = @as(c_int, 1);
pub const PY_BUILTIN_HASHLIB_HASHES = "md5,sha1,sha2,sha3,blake2";
pub const PY_COERCE_C_LOCALE = @as(c_int, 1);
pub const PY_HAVE_PERF_TRAMPOLINE = @as(c_int, 1);
pub const PY_SQLITE_ENABLE_LOAD_EXTENSION = @as(c_int, 1);
pub const PY_SQLITE_HAVE_SERIALIZE = @as(c_int, 1);
pub const PY_SSL_DEFAULT_CIPHERS = @as(c_int, 1);
pub const PY_SUPPORT_TIER = @as(c_int, 1);
pub const Py_ENABLE_SHARED = @as(c_int, 1);
pub const Py_PYPORT_H = "";
pub const _Py_STATIC_CAST = std.zig.c_translation.Macros.CAST_OR_CALL;
pub const _Py_CAST = std.zig.c_translation.Macros.CAST_OR_CALL;
pub const HAVE_LONG_LONG = @as(c_int, 1);
pub const PY_LONG_LONG = c_longlong;
pub inline fn Py_CHARMASK(c: anytype) u8 {
    _ = &c;
    return std.zig.c_translation.cast(u8, c & @as(c_int, 0xff));
}
pub inline fn PyDoc_STR(str: anytype) @TypeOf(str) {
    _ = &str;
    return str;
}
pub inline fn _Py_SIZE_ROUND_DOWN(n: anytype, a: anytype) @TypeOf(std.zig.c_translation.cast(usize, n) & ~std.zig.c_translation.cast(usize, a - @as(c_int, 1))) {
    _ = &n;
    _ = &a;
    return std.zig.c_translation.cast(usize, n) & ~std.zig.c_translation.cast(usize, a - @as(c_int, 1));
}
pub inline fn _Py_SIZE_ROUND_UP(n: anytype, a: anytype) @TypeOf((std.zig.c_translation.cast(usize, n) + std.zig.c_translation.cast(usize, a - @as(c_int, 1))) & ~std.zig.c_translation.cast(usize, a - @as(c_int, 1))) {
    _ = &n;
    _ = &a;
    return (std.zig.c_translation.cast(usize, n) + std.zig.c_translation.cast(usize, a - @as(c_int, 1))) & ~std.zig.c_translation.cast(usize, a - @as(c_int, 1));
}
pub inline fn _Py_ALIGN_DOWN(p: anytype, a: anytype) ?*anyopaque {
    _ = &p;
    _ = &a;
    return std.zig.c_translation.cast(?*anyopaque, std.zig.c_translation.cast(usize, p) & ~std.zig.c_translation.cast(usize, a - @as(c_int, 1)));
}
pub inline fn _Py_ALIGN_UP(p: anytype, a: anytype) ?*anyopaque {
    _ = &p;
    _ = &a;
    return std.zig.c_translation.cast(?*anyopaque, (std.zig.c_translation.cast(usize, p) + std.zig.c_translation.cast(usize, a - @as(c_int, 1))) & ~std.zig.c_translation.cast(usize, a - @as(c_int, 1)));
}
pub inline fn _Py_IS_ALIGNED(p: anytype, a: anytype) @TypeOf(!((std.zig.c_translation.cast(usize, p) & std.zig.c_translation.cast(usize, a - @as(c_int, 1))) != 0)) {
    _ = &p;
    _ = &a;
    return !((std.zig.c_translation.cast(usize, p) & std.zig.c_translation.cast(usize, a - @as(c_int, 1))) != 0);
}
pub inline fn _Py_RVALUE(EXPR: anytype) @TypeOf(EXPR) {
    _ = &EXPR;
    return blk_1: {
        _ = std.zig.c_translation.cast(anyopaque, @as(c_int, 0));
        break :blk_1 EXPR;
    };
}
pub inline fn _Py_IS_TYPE_SIGNED(@"type": anytype) @TypeOf(@"type"(-@as(c_int, 1)) <= @as(c_int, 0)) {
    _ = &@"type";
    return @"type"(-@as(c_int, 1)) <= @as(c_int, 0);
}
pub const Py_PYMATH_H = "";
pub const Py_MATH_PIl = @as(c_longdouble, 3.1415926535897932384626433832795029);
pub const Py_MATH_PI = @as(f64, 3.14159265358979323846);
pub const Py_MATH_El = @as(c_longdouble, 2.7182818284590452353602874713526625);
pub const Py_MATH_E = @as(f64, 2.7182818284590452354);
pub const Py_MATH_TAU = @as(c_longdouble, 6.2831853071795864769252867665590057683943);
pub const Py_PYMEM_H = "";
pub const Py_CPYTHON_PYMEM_H = "";
pub const Py_PYTYPEDEFS_H = "";
pub const Py_BUFFER_H = "";
pub const PyBUF_MAX_NDIM = @as(c_int, 64);
pub const PyBUF_SIMPLE = @as(c_int, 0);
pub const PyBUF_WRITABLE = @as(c_int, 0x0001);
pub const PyBUF_WRITEABLE = PyBUF_WRITABLE;
pub const PyBUF_FORMAT = @as(c_int, 0x0004);
pub const PyBUF_ND = @as(c_int, 0x0008);
pub const PyBUF_STRIDES = @as(c_int, 0x0010) | PyBUF_ND;
pub const PyBUF_C_CONTIGUOUS = @as(c_int, 0x0020) | PyBUF_STRIDES;
pub const PyBUF_F_CONTIGUOUS = @as(c_int, 0x0040) | PyBUF_STRIDES;
pub const PyBUF_ANY_CONTIGUOUS = @as(c_int, 0x0080) | PyBUF_STRIDES;
pub const PyBUF_INDIRECT = @as(c_int, 0x0100) | PyBUF_STRIDES;
pub const PyBUF_CONTIG = PyBUF_ND | PyBUF_WRITABLE;
pub const PyBUF_CONTIG_RO = PyBUF_ND;
pub const PyBUF_STRIDED = PyBUF_STRIDES | PyBUF_WRITABLE;
pub const PyBUF_STRIDED_RO = PyBUF_STRIDES;
pub const PyBUF_RECORDS = (PyBUF_STRIDES | PyBUF_WRITABLE) | PyBUF_FORMAT;
pub const PyBUF_RECORDS_RO = PyBUF_STRIDES | PyBUF_FORMAT;
pub const PyBUF_FULL = (PyBUF_INDIRECT | PyBUF_WRITABLE) | PyBUF_FORMAT;
pub const PyBUF_FULL_RO = PyBUF_INDIRECT | PyBUF_FORMAT;
pub const PyBUF_READ = @as(c_int, 0x100);
pub const PyBUF_WRITE = @as(c_int, 0x200);
pub const Py_PYSTATS_H = "";
pub inline fn _Py_INCREF_STAT_INC() anyopaque {
    return std.zig.c_translation.cast(anyopaque, @as(c_int, 0));
}
pub inline fn _Py_DECREF_STAT_INC() anyopaque {
    return std.zig.c_translation.cast(anyopaque, @as(c_int, 0));
}
pub const Py_ATOMIC_H = "";
pub const Py_CPYTHON_ATOMIC_H = "";
pub const _Py_USE_GCC_BUILTIN_ATOMICS = @as(c_int, 1);
pub const Py_ATOMIC_GCC_H = "";
pub inline fn _Py_atomic_load_ulong(p: anytype) @TypeOf(_Py_atomic_load_uint64(std.zig.c_translation.cast(?*u64, p))) {
    _ = &p;
    return _Py_atomic_load_uint64(std.zig.c_translation.cast(?*u64, p));
}
pub inline fn _Py_atomic_load_ulong_relaxed(p: anytype) @TypeOf(_Py_atomic_load_uint64_relaxed(std.zig.c_translation.cast(?*u64, p))) {
    _ = &p;
    return _Py_atomic_load_uint64_relaxed(std.zig.c_translation.cast(?*u64, p));
}
pub inline fn _Py_atomic_store_ulong(p: anytype, v: anytype) @TypeOf(_Py_atomic_store_uint64(std.zig.c_translation.cast(?*u64, p), v)) {
    _ = &p;
    _ = &v;
    return _Py_atomic_store_uint64(std.zig.c_translation.cast(?*u64, p), v);
}
pub inline fn _Py_atomic_store_ulong_relaxed(p: anytype, v: anytype) @TypeOf(_Py_atomic_store_uint64_relaxed(std.zig.c_translation.cast(?*u64, p), v)) {
    _ = &p;
    _ = &v;
    return _Py_atomic_store_uint64_relaxed(std.zig.c_translation.cast(?*u64, p), v);
}
pub const Py_LOCK_H = "";
pub const Py_CPYTHON_LOCK_H = "";
pub const _Py_UNLOCKED = @as(c_int, 0);
pub const _Py_LOCKED = @as(c_int, 1);
pub const Py_OBJECT_H = "";
pub const PyObject_HEAD = @compileError("unable to translate macro: undefined identifier `ob_base`");
// /usr/include/python3.13/object.h:60:9
pub const _PyObject_EXTRA_INIT = "";
pub const PyObject_HEAD_INIT = @compileError("unable to translate C expr: unexpected token '{'");
// /usr/include/python3.13/object.h:135:9
pub const PyVarObject_HEAD_INIT = @compileError("unable to translate C expr: unexpected token '{'");
// /usr/include/python3.13/object.h:142:9
pub const PyObject_VAR_HEAD = @compileError("unable to translate macro: undefined identifier `ob_base`");
// /usr/include/python3.13/object.h:154:9
pub const Py_INVALID_SIZE = std.zig.c_translation.cast(Py_ssize_t, -@as(c_int, 1));
pub const _PyObject_CAST = @compileError("unable to translate C expr: unexpected token ','");
// /usr/include/python3.13/object.h:222:9
pub const _PyVarObject_CAST = @compileError("unable to translate C expr: unexpected token ','");
// /usr/include/python3.13/object.h:230:9
pub const Py_PRINT_RAW = @as(c_int, 1);
pub const _Py_TPFLAGS_STATIC_BUILTIN = @as(c_int, 1) << @as(c_int, 1);
pub const Py_TPFLAGS_INLINE_VALUES = @as(c_int, 1) << @as(c_int, 2);
pub const Py_TPFLAGS_MANAGED_WEAKREF = @as(c_int, 1) << @as(c_int, 3);
pub const Py_TPFLAGS_MANAGED_DICT = @as(c_int, 1) << @as(c_int, 4);
pub const Py_TPFLAGS_PREHEADER = Py_TPFLAGS_MANAGED_WEAKREF | Py_TPFLAGS_MANAGED_DICT;
pub const Py_TPFLAGS_SEQUENCE = @as(c_int, 1) << @as(c_int, 5);
pub const Py_TPFLAGS_MAPPING = @as(c_int, 1) << @as(c_int, 6);
pub const Py_TPFLAGS_DISALLOW_INSTANTIATION = @as(c_ulong, 1) << @as(c_int, 7);
pub const Py_TPFLAGS_IMMUTABLETYPE = @as(c_ulong, 1) << @as(c_int, 8);
pub const Py_TPFLAGS_HEAPTYPE = @as(c_ulong, 1) << @as(c_int, 9);
pub const Py_TPFLAGS_BASETYPE = @as(c_ulong, 1) << @as(c_int, 10);
pub const Py_TPFLAGS_HAVE_VECTORCALL = @as(c_ulong, 1) << @as(c_int, 11);
pub const _Py_TPFLAGS_HAVE_VECTORCALL = Py_TPFLAGS_HAVE_VECTORCALL;
pub const Py_TPFLAGS_READY = @as(c_ulong, 1) << @as(c_int, 12);
pub const Py_TPFLAGS_READYING = @as(c_ulong, 1) << @as(c_int, 13);
pub const Py_TPFLAGS_HAVE_GC = @as(c_ulong, 1) << @as(c_int, 14);
pub const Py_TPFLAGS_HAVE_STACKLESS_EXTENSION = @as(c_int, 0);
pub const Py_TPFLAGS_METHOD_DESCRIPTOR = @as(c_ulong, 1) << @as(c_int, 17);
pub const Py_TPFLAGS_VALID_VERSION_TAG = @as(c_ulong, 1) << @as(c_int, 19);
pub const Py_TPFLAGS_IS_ABSTRACT = @as(c_ulong, 1) << @as(c_int, 20);
pub const _Py_TPFLAGS_MATCH_SELF = @as(c_ulong, 1) << @as(c_int, 22);
pub const Py_TPFLAGS_ITEMS_AT_END = @as(c_ulong, 1) << @as(c_int, 23);
pub const Py_TPFLAGS_LONG_SUBCLASS = @as(c_ulong, 1) << @as(c_int, 24);
pub const Py_TPFLAGS_LIST_SUBCLASS = @as(c_ulong, 1) << @as(c_int, 25);
pub const Py_TPFLAGS_TUPLE_SUBCLASS = @as(c_ulong, 1) << @as(c_int, 26);
pub const Py_TPFLAGS_BYTES_SUBCLASS = @as(c_ulong, 1) << @as(c_int, 27);
pub const Py_TPFLAGS_UNICODE_SUBCLASS = @as(c_ulong, 1) << @as(c_int, 28);
pub const Py_TPFLAGS_DICT_SUBCLASS = @as(c_ulong, 1) << @as(c_int, 29);
pub const Py_TPFLAGS_BASE_EXC_SUBCLASS = @as(c_ulong, 1) << @as(c_int, 30);
pub const Py_TPFLAGS_TYPE_SUBCLASS = @as(c_ulong, 1) << @as(c_int, 31);
pub const Py_TPFLAGS_DEFAULT = Py_TPFLAGS_HAVE_STACKLESS_EXTENSION | @as(c_int, 0);
pub const Py_TPFLAGS_HAVE_FINALIZE = @as(c_ulong, 1) << @as(c_int, 0);
pub const Py_TPFLAGS_HAVE_VERSION_TAG = @as(c_ulong, 1) << @as(c_int, 18);
pub const Py_CLEAR = @compileError("unable to translate macro: undefined identifier `_tmp_op_ptr`");
// /usr/include/python3.13/object.h:1005:9
pub const Py_CONSTANT_NONE = @as(c_int, 0);
pub const Py_CONSTANT_FALSE = @as(c_int, 1);
pub const Py_CONSTANT_TRUE = @as(c_int, 2);
pub const Py_CONSTANT_ELLIPSIS = @as(c_int, 3);
pub const Py_CONSTANT_NOT_IMPLEMENTED = @as(c_int, 4);
pub const Py_CONSTANT_ZERO = @as(c_int, 5);
pub const Py_CONSTANT_ONE = @as(c_int, 6);
pub const Py_CONSTANT_EMPTY_STR = @as(c_int, 7);
pub const Py_CONSTANT_EMPTY_BYTES = @as(c_int, 8);
pub const Py_CONSTANT_EMPTY_TUPLE = @as(c_int, 9);
// /usr/include/python3.13/object.h:1106:11: warning: macro 'Py_None' contains a runtime value, translated to function
pub inline fn Py_None() @TypeOf(&_Py_NoneStruct) {
    return &_Py_NoneStruct;
}
pub const Py_RETURN_NONE = @compileError("unable to translate C expr: unexpected token 'return'");
// /usr/include/python3.13/object.h:1114:9

// /usr/include/python3.13/object.h:1125:11: warning: macro 'Py_NotImplemented' contains a runtime value, translated to function
pub inline fn Py_NotImplemented() @TypeOf(&_Py_NotImplementedStruct) {
    return &_Py_NotImplementedStruct;
}
pub const Py_RETURN_NOTIMPLEMENTED = @compileError("unable to translate C expr: unexpected token 'return'");
// /usr/include/python3.13/object.h:1129:9
pub const Py_LT = @as(c_int, 0);
pub const Py_LE = @as(c_int, 1);
pub const Py_EQ = @as(c_int, 2);
pub const Py_NE = @as(c_int, 3);
pub const Py_GT = @as(c_int, 4);
pub const Py_GE = @as(c_int, 5);
pub const Py_RETURN_RICHCOMPARE = @compileError("unable to translate C expr: unexpected token 'do'");
// /usr/include/python3.13/object.h:1153:9
pub const Py_CPYTHON_OBJECT_H = "";
pub const _Py_static_string_init = @compileError("unable to translate C expr: unexpected token '{'");
// /usr/include/python3.13/cpython/object.h:53:9
pub const _Py_static_string = @compileError("unable to translate C expr: unexpected token 'static'");
// /usr/include/python3.13/cpython/object.h:54:9
pub const _Py_IDENTIFIER = @compileError("unable to translate macro: undefined identifier `PyId_`");
// /usr/include/python3.13/cpython/object.h:55:9
pub const Py_SETREF = @compileError("unable to translate macro: undefined identifier `_tmp_dst_ptr`");
// /usr/include/python3.13/cpython/object.h:327:9
pub const Py_XSETREF = @compileError("unable to translate macro: undefined identifier `_tmp_dst_ptr`");
// /usr/include/python3.13/cpython/object.h:349:9
pub const _PyObject_ASSERT_WITH_MSG = @compileError("unable to translate macro: undefined identifier `__FILE__`");
// /usr/include/python3.13/cpython/object.h:395:9
pub const _PyObject_ASSERT_FAILED_MSG = @compileError("unable to translate macro: undefined identifier `__FILE__`");
// /usr/include/python3.13/cpython/object.h:400:9
pub const Py_TRASHCAN_HEADROOM = @as(c_int, 50);
pub const Py_TRASHCAN_BEGIN = @compileError("unable to translate macro: undefined identifier `tstate`");
// /usr/include/python3.13/cpython/object.h:479:9
pub const Py_TRASHCAN_END = @compileError("unable to translate macro: undefined identifier `tstate`");
// /usr/include/python3.13/cpython/object.h:488:9
pub const TYPE_MAX_WATCHERS = @as(c_int, 8);
pub inline fn PyType_FastSubclass(@"type": anytype, flag: anytype) @TypeOf(PyType_HasFeature(@"type", flag)) {
    _ = &@"type";
    _ = &flag;
    return PyType_HasFeature(@"type", flag);
}
pub const _PyType_CAST = @compileError("unable to translate C expr: unexpected token ','");
// /usr/include/python3.13/object.h:1253:9
pub const Py_OBJIMPL_H = "";
pub const PyObject_MALLOC = PyObject_Malloc;
pub const PyObject_REALLOC = PyObject_Realloc;
pub const PyObject_FREE = PyObject_Free;
pub const PyObject_Del = PyObject_Free;
pub const PyObject_DEL = PyObject_Free;
pub inline fn PyObject_INIT(op: anytype, typeobj: anytype) @TypeOf(PyObject_Init(_PyObject_CAST(op), typeobj)) {
    _ = &op;
    _ = &typeobj;
    return PyObject_Init(_PyObject_CAST(op), typeobj);
}
pub inline fn PyObject_INIT_VAR(op: anytype, typeobj: anytype, size: anytype) @TypeOf(PyObject_InitVar(_PyVarObject_CAST(op), typeobj, size)) {
    _ = &op;
    _ = &typeobj;
    _ = &size;
    return PyObject_InitVar(_PyVarObject_CAST(op), typeobj, size);
}
pub const PyObject_New = @compileError("unable to translate C expr: unexpected token ')'");
// /usr/include/python3.13/objimpl.h:130:9
pub inline fn PyObject_NEW(@"type": anytype, typeobj: anytype) @TypeOf(PyObject_New(@"type", typeobj)) {
    _ = &@"type";
    _ = &typeobj;
    return PyObject_New(@"type", typeobj);
}
pub const PyObject_NewVar = @compileError("unable to translate C expr: unexpected token ')'");
// /usr/include/python3.13/objimpl.h:136:9
pub inline fn PyObject_NEW_VAR(@"type": anytype, typeobj: anytype, n: anytype) @TypeOf(PyObject_NewVar(@"type", typeobj, n)) {
    _ = &@"type";
    _ = &typeobj;
    _ = &n;
    return PyObject_NewVar(@"type", typeobj, n);
}
pub inline fn PyType_IS_GC(t: anytype) @TypeOf(PyType_HasFeature(t, Py_TPFLAGS_HAVE_GC)) {
    _ = &t;
    return PyType_HasFeature(t, Py_TPFLAGS_HAVE_GC);
}
pub const PyObject_GC_Resize = @compileError("unable to translate C expr: unexpected token ')'");
// /usr/include/python3.13/objimpl.h:160:9
pub const PyObject_GC_New = @compileError("unable to translate C expr: unexpected token ','");
// /usr/include/python3.13/objimpl.h:180:9
pub const PyObject_GC_NewVar = @compileError("unable to translate C expr: unexpected token ','");
// /usr/include/python3.13/objimpl.h:182:9
pub const Py_VISIT = @compileError("unable to translate macro: undefined identifier `vret`");
// /usr/include/python3.13/objimpl.h:193:9
pub const Py_CPYTHON_OBJIMPL_H = "";
pub const Py_bf_getbuffer = @as(c_int, 1);
pub const Py_bf_releasebuffer = @as(c_int, 2);
pub const Py_mp_ass_subscript = @as(c_int, 3);
pub const Py_mp_length = @as(c_int, 4);
pub const Py_mp_subscript = @as(c_int, 5);
pub const Py_nb_absolute = @as(c_int, 6);
pub const Py_nb_add = @as(c_int, 7);
pub const Py_nb_and = @as(c_int, 8);
pub const Py_nb_bool = @as(c_int, 9);
pub const Py_nb_divmod = @as(c_int, 10);
pub const Py_nb_float = @as(c_int, 11);
pub const Py_nb_floor_divide = @as(c_int, 12);
pub const Py_nb_index = @as(c_int, 13);
pub const Py_nb_inplace_add = @as(c_int, 14);
pub const Py_nb_inplace_and = @as(c_int, 15);
pub const Py_nb_inplace_floor_divide = @as(c_int, 16);
pub const Py_nb_inplace_lshift = @as(c_int, 17);
pub const Py_nb_inplace_multiply = @as(c_int, 18);
pub const Py_nb_inplace_or = @as(c_int, 19);
pub const Py_nb_inplace_power = @as(c_int, 20);
pub const Py_nb_inplace_remainder = @as(c_int, 21);
pub const Py_nb_inplace_rshift = @as(c_int, 22);
pub const Py_nb_inplace_subtract = @as(c_int, 23);
pub const Py_nb_inplace_true_divide = @as(c_int, 24);
pub const Py_nb_inplace_xor = @as(c_int, 25);
pub const Py_nb_int = @as(c_int, 26);
pub const Py_nb_invert = @as(c_int, 27);
pub const Py_nb_lshift = @as(c_int, 28);
pub const Py_nb_multiply = @as(c_int, 29);
pub const Py_nb_negative = @as(c_int, 30);
pub const Py_nb_or = @as(c_int, 31);
pub const Py_nb_positive = @as(c_int, 32);
pub const Py_nb_power = @as(c_int, 33);
pub const Py_nb_remainder = @as(c_int, 34);
pub const Py_nb_rshift = @as(c_int, 35);
pub const Py_nb_subtract = @as(c_int, 36);
pub const Py_nb_true_divide = @as(c_int, 37);
pub const Py_nb_xor = @as(c_int, 38);
pub const Py_sq_ass_item = @as(c_int, 39);
pub const Py_sq_concat = @as(c_int, 40);
pub const Py_sq_contains = @as(c_int, 41);
pub const Py_sq_inplace_concat = @as(c_int, 42);
pub const Py_sq_inplace_repeat = @as(c_int, 43);
pub const Py_sq_item = @as(c_int, 44);
pub const Py_sq_length = @as(c_int, 45);
pub const Py_sq_repeat = @as(c_int, 46);
pub const Py_tp_alloc = @as(c_int, 47);
pub const Py_tp_base = @as(c_int, 48);
pub const Py_tp_bases = @as(c_int, 49);
pub const Py_tp_call = @as(c_int, 50);
pub const Py_tp_clear = @as(c_int, 51);
pub const Py_tp_dealloc = @as(c_int, 52);
pub const Py_tp_del = @as(c_int, 53);
pub const Py_tp_descr_get = @as(c_int, 54);
pub const Py_tp_descr_set = @as(c_int, 55);
pub const Py_tp_doc = @as(c_int, 56);
pub const Py_tp_getattr = @as(c_int, 57);
pub const Py_tp_getattro = @as(c_int, 58);
pub const Py_tp_hash = @as(c_int, 59);
pub const Py_tp_init = @as(c_int, 60);
pub const Py_tp_is_gc = @as(c_int, 61);
pub const Py_tp_iter = @as(c_int, 62);
pub const Py_tp_iternext = @as(c_int, 63);
pub const Py_tp_methods = @as(c_int, 64);
pub const Py_tp_new = @as(c_int, 65);
pub const Py_tp_repr = @as(c_int, 66);
pub const Py_tp_richcompare = @as(c_int, 67);
pub const Py_tp_setattr = @as(c_int, 68);
pub const Py_tp_setattro = @as(c_int, 69);
pub const Py_tp_str = @as(c_int, 70);
pub const Py_tp_traverse = @as(c_int, 71);
pub const Py_tp_members = @as(c_int, 72);
pub const Py_tp_getset = @as(c_int, 73);
pub const Py_tp_free = @as(c_int, 74);
pub const Py_nb_matrix_multiply = @as(c_int, 75);
pub const Py_nb_inplace_matrix_multiply = @as(c_int, 76);
pub const Py_am_await = @as(c_int, 77);
pub const Py_am_aiter = @as(c_int, 78);
pub const Py_am_anext = @as(c_int, 79);
pub const Py_tp_finalize = @as(c_int, 80);
pub const Py_am_send = @as(c_int, 81);
pub const Py_HASH_H = "";
pub const Py_HASH_CUTOFF = @as(c_int, 0);
pub const Py_HASH_EXTERNAL = @as(c_int, 0);
pub const Py_HASH_SIPHASH24 = @as(c_int, 1);
pub const Py_HASH_FNV = @as(c_int, 2);
pub const Py_HASH_SIPHASH13 = @as(c_int, 3);
pub const Py_HASH_ALGORITHM = Py_HASH_SIPHASH13;
pub const Py_CPYTHON_HASH_H = "";
pub const PyHASH_MULTIPLIER = @as(c_ulong, 1000003);
pub const PyHASH_BITS = @as(c_int, 61);
pub const PyHASH_MODULUS = (std.zig.c_translation.cast(usize, @as(c_int, 1)) << _PyHASH_BITS) - @as(c_int, 1);
pub const PyHASH_INF = std.zig.c_translation.promoteIntLiteral(c_int, 314159, .decimal);
pub const PyHASH_IMAG = PyHASH_MULTIPLIER;
pub const _PyHASH_MULTIPLIER = PyHASH_MULTIPLIER;
pub const _PyHASH_BITS = PyHASH_BITS;
pub const _PyHASH_MODULUS = PyHASH_MODULUS;
pub const _PyHASH_INF = PyHASH_INF;
pub const _PyHASH_IMAG = PyHASH_IMAG;
pub const _Py_HashPointer = Py_HashPointer;
pub const Py_PYDEBUG_H = "";
pub const Py_BYTEARRAYOBJECT_H = "";
pub inline fn PyByteArray_Check(self: anytype) @TypeOf(PyObject_TypeCheck(self, &PyByteArray_Type)) {
    _ = &self;
    return PyObject_TypeCheck(self, &PyByteArray_Type);
}
pub inline fn PyByteArray_CheckExact(self: anytype) @TypeOf(Py_IS_TYPE(self, &PyByteArray_Type)) {
    _ = &self;
    return Py_IS_TYPE(self, &PyByteArray_Type);
}
pub const Py_CPYTHON_BYTEARRAYOBJECT_H = "";
pub const _PyByteArray_CAST = @compileError("unable to translate C expr: unexpected token ','");
// /usr/include/python3.13/cpython/bytearrayobject.h:17:9
pub const Py_BYTESOBJECT_H = "";
pub inline fn PyBytes_Check(op: anytype) @TypeOf(PyType_FastSubclass(Py_TYPE(op), Py_TPFLAGS_BYTES_SUBCLASS)) {
    _ = &op;
    return PyType_FastSubclass(Py_TYPE(op), Py_TPFLAGS_BYTES_SUBCLASS);
}
pub inline fn PyBytes_CheckExact(op: anytype) @TypeOf(Py_IS_TYPE(op, &PyBytes_Type)) {
    _ = &op;
    return Py_IS_TYPE(op, &PyBytes_Type);
}
pub const Py_CPYTHON_BYTESOBJECT_H = "";
pub const _PyBytes_CAST = @compileError("unable to translate C expr: unexpected token ','");
// /usr/include/python3.13/cpython/bytesobject.h:20:9
pub const Py_UNICODEOBJECT_H = "";
pub const Py_USING_UNICODE = "";
pub const Py_UNICODE_WIDE = "";
pub inline fn PyUnicode_Check(op: anytype) @TypeOf(PyType_FastSubclass(Py_TYPE(op), Py_TPFLAGS_UNICODE_SUBCLASS)) {
    _ = &op;
    return PyType_FastSubclass(Py_TYPE(op), Py_TPFLAGS_UNICODE_SUBCLASS);
}
pub inline fn PyUnicode_CheckExact(op: anytype) @TypeOf(Py_IS_TYPE(op, &PyUnicode_Type)) {
    _ = &op;
    return Py_IS_TYPE(op, &PyUnicode_Type);
}
pub const Py_UNICODE_REPLACEMENT_CHARACTER = std.zig.c_translation.cast(Py_UCS4, std.zig.c_translation.promoteIntLiteral(c_int, 0xFFFD, .hex));
pub const Py_CPYTHON_UNICODEOBJECT_H = "";
pub const _PyASCIIObject_CAST = @compileError("unable to translate C expr: unexpected token ','");
// /usr/include/python3.13/cpython/unicodeobject.h:175:9
pub const _PyCompactUnicodeObject_CAST = @compileError("unable to translate C expr: unexpected token ','");
// /usr/include/python3.13/cpython/unicodeobject.h:178:9
pub const _PyUnicodeObject_CAST = @compileError("unable to translate C expr: unexpected token ','");
// /usr/include/python3.13/cpython/unicodeobject.h:181:9
pub const SSTATE_NOT_INTERNED = @as(c_int, 0);
pub const SSTATE_INTERNED_MORTAL = @as(c_int, 1);
pub const SSTATE_INTERNED_IMMORTAL = @as(c_int, 2);
pub const SSTATE_INTERNED_IMMORTAL_STATIC = @as(c_int, 3);
pub inline fn PyUnicode_KIND(op: anytype) @TypeOf(_Py_RVALUE(_PyASCIIObject_CAST(op).*.state.kind)) {
    _ = &op;
    return _Py_RVALUE(_PyASCIIObject_CAST(op).*.state.kind);
}
pub const PyUnicode_1BYTE_DATA = @compileError("unable to translate C expr: unexpected token ','");
// /usr/include/python3.13/cpython/unicodeobject.h:274:9
pub const PyUnicode_2BYTE_DATA = @compileError("unable to translate C expr: unexpected token ','");
// /usr/include/python3.13/cpython/unicodeobject.h:275:9
pub const PyUnicode_4BYTE_DATA = @compileError("unable to translate C expr: unexpected token ','");
// /usr/include/python3.13/cpython/unicodeobject.h:276:9
pub inline fn _PyUnicodeWriter_Prepare(WRITER: anytype, LENGTH: anytype, MAXCHAR: anytype) @TypeOf(if ((MAXCHAR <= WRITER.*.maxchar) and (LENGTH <= (WRITER.*.size - WRITER.*.pos))) @as(c_int, 0) else if (LENGTH == @as(c_int, 0)) @as(c_int, 0) else _PyUnicodeWriter_PrepareInternal(WRITER, LENGTH, MAXCHAR)) {
    _ = &WRITER;
    _ = &LENGTH;
    _ = &MAXCHAR;
    return if ((MAXCHAR <= WRITER.*.maxchar) and (LENGTH <= (WRITER.*.size - WRITER.*.pos))) @as(c_int, 0) else if (LENGTH == @as(c_int, 0)) @as(c_int, 0) else _PyUnicodeWriter_PrepareInternal(WRITER, LENGTH, MAXCHAR);
}
pub inline fn _PyUnicodeWriter_PrepareKind(WRITER: anytype, KIND: anytype) @TypeOf(if (KIND <= WRITER.*.kind) @as(c_int, 0) else _PyUnicodeWriter_PrepareKindInternal(WRITER, KIND)) {
    _ = &WRITER;
    _ = &KIND;
    return if (KIND <= WRITER.*.kind) @as(c_int, 0) else _PyUnicodeWriter_PrepareKindInternal(WRITER, KIND);
}
pub const _PyUnicode_AsString = PyUnicode_AsUTF8;
pub inline fn Py_UNICODE_ISLOWER(ch: anytype) @TypeOf(_PyUnicode_IsLowercase(ch)) {
    _ = &ch;
    return _PyUnicode_IsLowercase(ch);
}
pub inline fn Py_UNICODE_ISUPPER(ch: anytype) @TypeOf(_PyUnicode_IsUppercase(ch)) {
    _ = &ch;
    return _PyUnicode_IsUppercase(ch);
}
pub inline fn Py_UNICODE_ISTITLE(ch: anytype) @TypeOf(_PyUnicode_IsTitlecase(ch)) {
    _ = &ch;
    return _PyUnicode_IsTitlecase(ch);
}
pub inline fn Py_UNICODE_ISLINEBREAK(ch: anytype) @TypeOf(_PyUnicode_IsLinebreak(ch)) {
    _ = &ch;
    return _PyUnicode_IsLinebreak(ch);
}
pub inline fn Py_UNICODE_TOLOWER(ch: anytype) @TypeOf(_PyUnicode_ToLowercase(ch)) {
    _ = &ch;
    return _PyUnicode_ToLowercase(ch);
}
pub inline fn Py_UNICODE_TOUPPER(ch: anytype) @TypeOf(_PyUnicode_ToUppercase(ch)) {
    _ = &ch;
    return _PyUnicode_ToUppercase(ch);
}
pub inline fn Py_UNICODE_TOTITLE(ch: anytype) @TypeOf(_PyUnicode_ToTitlecase(ch)) {
    _ = &ch;
    return _PyUnicode_ToTitlecase(ch);
}
pub inline fn Py_UNICODE_ISDECIMAL(ch: anytype) @TypeOf(_PyUnicode_IsDecimalDigit(ch)) {
    _ = &ch;
    return _PyUnicode_IsDecimalDigit(ch);
}
pub inline fn Py_UNICODE_ISDIGIT(ch: anytype) @TypeOf(_PyUnicode_IsDigit(ch)) {
    _ = &ch;
    return _PyUnicode_IsDigit(ch);
}
pub inline fn Py_UNICODE_ISNUMERIC(ch: anytype) @TypeOf(_PyUnicode_IsNumeric(ch)) {
    _ = &ch;
    return _PyUnicode_IsNumeric(ch);
}
pub inline fn Py_UNICODE_ISPRINTABLE(ch: anytype) @TypeOf(_PyUnicode_IsPrintable(ch)) {
    _ = &ch;
    return _PyUnicode_IsPrintable(ch);
}
pub inline fn Py_UNICODE_TODECIMAL(ch: anytype) @TypeOf(_PyUnicode_ToDecimalDigit(ch)) {
    _ = &ch;
    return _PyUnicode_ToDecimalDigit(ch);
}
pub inline fn Py_UNICODE_TODIGIT(ch: anytype) @TypeOf(_PyUnicode_ToDigit(ch)) {
    _ = &ch;
    return _PyUnicode_ToDigit(ch);
}
pub inline fn Py_UNICODE_TONUMERIC(ch: anytype) @TypeOf(_PyUnicode_ToNumeric(ch)) {
    _ = &ch;
    return _PyUnicode_ToNumeric(ch);
}
pub inline fn Py_UNICODE_ISALPHA(ch: anytype) @TypeOf(_PyUnicode_IsAlpha(ch)) {
    _ = &ch;
    return _PyUnicode_IsAlpha(ch);
}
pub const Py_ERRORS_H = "";
pub inline fn PyExceptionClass_Check(x: anytype) @TypeOf((PyType_Check(x) != 0) and (PyType_FastSubclass(std.zig.c_translation.cast(?*PyTypeObject, x), Py_TPFLAGS_BASE_EXC_SUBCLASS) != 0)) {
    _ = &x;
    return (PyType_Check(x) != 0) and (PyType_FastSubclass(std.zig.c_translation.cast(?*PyTypeObject, x), Py_TPFLAGS_BASE_EXC_SUBCLASS) != 0);
}
pub inline fn PyExceptionInstance_Check(x: anytype) @TypeOf(PyType_FastSubclass(Py_TYPE(x), Py_TPFLAGS_BASE_EXC_SUBCLASS)) {
    _ = &x;
    return PyType_FastSubclass(Py_TYPE(x), Py_TPFLAGS_BASE_EXC_SUBCLASS);
}
pub inline fn PyExceptionInstance_Class(x: anytype) @TypeOf(_PyObject_CAST(Py_TYPE(x))) {
    _ = &x;
    return _PyObject_CAST(Py_TYPE(x));
}
pub inline fn _PyBaseExceptionGroup_Check(x: anytype) @TypeOf(PyObject_TypeCheck(x, std.zig.c_translation.cast(?*PyTypeObject, PyExc_BaseExceptionGroup))) {
    _ = &x;
    return PyObject_TypeCheck(x, std.zig.c_translation.cast(?*PyTypeObject, PyExc_BaseExceptionGroup));
}
pub const Py_CPYTHON_ERRORS_H = "";
pub const PyException_HEAD = @compileError("unable to translate macro: undefined identifier `dict`");
// /usr/include/python3.13/cpython/pyerrors.h:8:9
pub const Py_LONGOBJECT_H = "";
pub inline fn PyLong_Check(op: anytype) @TypeOf(PyType_FastSubclass(Py_TYPE(op), Py_TPFLAGS_LONG_SUBCLASS)) {
    _ = &op;
    return PyType_FastSubclass(Py_TYPE(op), Py_TPFLAGS_LONG_SUBCLASS);
}
pub inline fn PyLong_CheckExact(op: anytype) @TypeOf(Py_IS_TYPE(op, &PyLong_Type)) {
    _ = &op;
    return Py_IS_TYPE(op, &PyLong_Type);
}
pub inline fn PyLong_AS_LONG(op: anytype) @TypeOf(PyLong_AsLong(op)) {
    _ = &op;
    return PyLong_AsLong(op);
}
pub const _Py_PARSE_PID = "i";
pub const PyLong_FromPid = PyLong_FromLong;
pub const PyLong_AsPid = PyLong_AsInt;
pub const _Py_PARSE_INTPTR = "l";
pub const _Py_PARSE_UINTPTR = "k";
pub const Py_CPYTHON_LONGOBJECT_H = "";
pub const Py_ASNATIVEBYTES_DEFAULTS = -@as(c_int, 1);
pub const Py_ASNATIVEBYTES_BIG_ENDIAN = @as(c_int, 0);
pub const Py_ASNATIVEBYTES_LITTLE_ENDIAN = @as(c_int, 1);
pub const Py_ASNATIVEBYTES_NATIVE_ENDIAN = @as(c_int, 3);
pub const Py_ASNATIVEBYTES_UNSIGNED_BUFFER = @as(c_int, 4);
pub const Py_ASNATIVEBYTES_REJECT_NEGATIVE = @as(c_int, 8);
pub const Py_ASNATIVEBYTES_ALLOW_INDEX = @as(c_int, 16);
pub const Py_LONGINTREPR_H = "";
pub const PyLong_SHIFT = @as(c_int, 30);
pub const _PyLong_DECIMAL_SHIFT = @as(c_int, 9);
pub const _PyLong_DECIMAL_BASE = std.zig.c_translation.cast(digit, std.zig.c_translation.promoteIntLiteral(c_int, 1000000000, .decimal));
pub const PyLong_BASE = std.zig.c_translation.cast(digit, @as(c_int, 1)) << PyLong_SHIFT;
pub const PyLong_MASK = std.zig.c_translation.cast(digit, PyLong_BASE - @as(c_int, 1));
pub const _PyLong_SIGN_MASK = @as(c_int, 3);
pub const _PyLong_NON_SIZE_BITS = @as(c_int, 3);
pub const Py_BOOLOBJECT_H = "";
pub inline fn PyBool_Check(x: anytype) @TypeOf(Py_IS_TYPE(x, &PyBool_Type)) {
    _ = &x;
    return Py_IS_TYPE(x, &PyBool_Type);
}
// /usr/include/python3.13/boolobject.h:25:11: warning: macro 'Py_False' contains a runtime value, translated to function
pub inline fn Py_False() @TypeOf(_PyObject_CAST(&_Py_FalseStruct)) {
    return _PyObject_CAST(&_Py_FalseStruct);
}
// /usr/include/python3.13/boolobject.h:26:11: warning: macro 'Py_True' contains a runtime value, translated to function
pub inline fn Py_True() @TypeOf(_PyObject_CAST(&_Py_TrueStruct)) {
    return _PyObject_CAST(&_Py_TrueStruct);
}
pub const Py_RETURN_TRUE = @compileError("unable to translate C expr: unexpected token 'return'");
// /usr/include/python3.13/boolobject.h:38:9
pub const Py_RETURN_FALSE = @compileError("unable to translate C expr: unexpected token 'return'");
// /usr/include/python3.13/boolobject.h:39:9
pub const Py_FLOATOBJECT_H = "";
pub inline fn PyFloat_Check(op: anytype) @TypeOf(PyObject_TypeCheck(op, &PyFloat_Type)) {
    _ = &op;
    return PyObject_TypeCheck(op, &PyFloat_Type);
}
pub inline fn PyFloat_CheckExact(op: anytype) @TypeOf(Py_IS_TYPE(op, &PyFloat_Type)) {
    _ = &op;
    return Py_IS_TYPE(op, &PyFloat_Type);
}
pub const Py_RETURN_NAN = @compileError("unable to translate C expr: unexpected token 'return'");
// /usr/include/python3.13/floatobject.h:19:9
pub const Py_RETURN_INF = @compileError("unable to translate C expr: unexpected token 'do'");
// /usr/include/python3.13/floatobject.h:21:9
pub const Py_CPYTHON_FLOATOBJECT_H = "";
pub const _PyFloat_CAST = @compileError("unable to translate C expr: unexpected token ','");
// /usr/include/python3.13/cpython/floatobject.h:10:9
pub const Py_COMPLEXOBJECT_H = "";
pub inline fn PyComplex_Check(op: anytype) @TypeOf(PyObject_TypeCheck(op, &PyComplex_Type)) {
    _ = &op;
    return PyObject_TypeCheck(op, &PyComplex_Type);
}
pub inline fn PyComplex_CheckExact(op: anytype) @TypeOf(Py_IS_TYPE(op, &PyComplex_Type)) {
    _ = &op;
    return Py_IS_TYPE(op, &PyComplex_Type);
}
pub const Py_CPYTHON_COMPLEXOBJECT_H = "";
pub const Py_RANGEOBJECT_H = "";
pub inline fn PyRange_Check(op: anytype) @TypeOf(Py_IS_TYPE(op, &PyRange_Type)) {
    _ = &op;
    return Py_IS_TYPE(op, &PyRange_Type);
}
pub const Py_MEMORYOBJECT_H = "";
pub inline fn PyMemoryView_Check(op: anytype) @TypeOf(Py_IS_TYPE(op, &PyMemoryView_Type)) {
    _ = &op;
    return Py_IS_TYPE(op, &PyMemoryView_Type);
}
pub const Py_CPYTHON_MEMORYOBJECT_H = "";
pub const _Py_MANAGED_BUFFER_RELEASED = @as(c_int, 0x001);
pub const _Py_MANAGED_BUFFER_FREE_FORMAT = @as(c_int, 0x002);
pub const _Py_MEMORYVIEW_RELEASED = @as(c_int, 0x001);
pub const _Py_MEMORYVIEW_C = @as(c_int, 0x002);
pub const _Py_MEMORYVIEW_FORTRAN = @as(c_int, 0x004);
pub const _Py_MEMORYVIEW_SCALAR = @as(c_int, 0x008);
pub const _Py_MEMORYVIEW_PIL = @as(c_int, 0x010);
pub const _Py_MEMORYVIEW_RESTRICTED = @as(c_int, 0x020);
pub const _PyMemoryView_CAST = @compileError("unable to translate C expr: unexpected token ','");
// /usr/include/python3.13/cpython/memoryobject.h:38:9
pub const Py_TUPLEOBJECT_H = "";
pub inline fn PyTuple_Check(op: anytype) @TypeOf(PyType_FastSubclass(Py_TYPE(op), Py_TPFLAGS_TUPLE_SUBCLASS)) {
    _ = &op;
    return PyType_FastSubclass(Py_TYPE(op), Py_TPFLAGS_TUPLE_SUBCLASS);
}
pub inline fn PyTuple_CheckExact(op: anytype) @TypeOf(Py_IS_TYPE(op, &PyTuple_Type)) {
    _ = &op;
    return Py_IS_TYPE(op, &PyTuple_Type);
}
pub const Py_CPYTHON_TUPLEOBJECT_H = "";
pub const _PyTuple_CAST = @compileError("unable to translate C expr: unexpected token ','");
// /usr/include/python3.13/cpython/tupleobject.h:16:9
pub inline fn PyTuple_GET_ITEM(op: anytype, index_1: anytype) @TypeOf(_PyTuple_CAST(op).*.ob_item[@as(usize, @intCast(index_1))]) {
    _ = &op;
    _ = &index_1;
    return _PyTuple_CAST(op).*.ob_item[@as(usize, @intCast(index_1))];
}
pub const Py_LISTOBJECT_H = "";
pub inline fn PyList_Check(op: anytype) @TypeOf(PyType_FastSubclass(Py_TYPE(op), Py_TPFLAGS_LIST_SUBCLASS)) {
    _ = &op;
    return PyType_FastSubclass(Py_TYPE(op), Py_TPFLAGS_LIST_SUBCLASS);
}
pub inline fn PyList_CheckExact(op: anytype) @TypeOf(Py_IS_TYPE(op, &PyList_Type)) {
    _ = &op;
    return Py_IS_TYPE(op, &PyList_Type);
}
pub const Py_CPYTHON_LISTOBJECT_H = "";
pub const _PyList_CAST = @compileError("unable to translate C expr: unexpected token ','");
// /usr/include/python3.13/cpython/listobject.h:25:9
pub inline fn PyList_GET_ITEM(op: anytype, index_1: anytype) @TypeOf(_PyList_CAST(op).*.ob_item[@as(usize, @intCast(index_1))]) {
    _ = &op;
    _ = &index_1;
    return _PyList_CAST(op).*.ob_item[@as(usize, @intCast(index_1))];
}
pub const Py_DICTOBJECT_H = "";
pub inline fn PyDict_Check(op: anytype) @TypeOf(PyType_FastSubclass(Py_TYPE(op), Py_TPFLAGS_DICT_SUBCLASS)) {
    _ = &op;
    return PyType_FastSubclass(Py_TYPE(op), Py_TPFLAGS_DICT_SUBCLASS);
}
pub inline fn PyDict_CheckExact(op: anytype) @TypeOf(Py_IS_TYPE(op, &PyDict_Type)) {
    _ = &op;
    return Py_IS_TYPE(op, &PyDict_Type);
}
pub inline fn PyDictKeys_Check(op: anytype) @TypeOf(PyObject_TypeCheck(op, &PyDictKeys_Type)) {
    _ = &op;
    return PyObject_TypeCheck(op, &PyDictKeys_Type);
}
pub inline fn PyDictValues_Check(op: anytype) @TypeOf(PyObject_TypeCheck(op, &PyDictValues_Type)) {
    _ = &op;
    return PyObject_TypeCheck(op, &PyDictValues_Type);
}
pub inline fn PyDictItems_Check(op: anytype) @TypeOf(PyObject_TypeCheck(op, &PyDictItems_Type)) {
    _ = &op;
    return PyObject_TypeCheck(op, &PyDictItems_Type);
}
pub inline fn PyDictViewSet_Check(op: anytype) @TypeOf((PyDictKeys_Check(op) != 0) or (PyDictItems_Check(op) != 0)) {
    _ = &op;
    return (PyDictKeys_Check(op) != 0) or (PyDictItems_Check(op) != 0);
}
pub const Py_CPYTHON_DICTOBJECT_H = "";
pub const PY_FOREACH_DICT_EVENT = @compileError("unable to translate macro: undefined identifier `ADDED`");
// /usr/include/python3.13/cpython/dictobject.h:77:9
pub const PY_DEF_EVENT = @compileError("unable to translate macro: undefined identifier `PyDict_EVENT_`");
// /usr/include/python3.13/cpython/dictobject.h:86:13
pub const Py_ODICTOBJECT_H = "";
pub inline fn PyODict_Check(op: anytype) @TypeOf(PyObject_TypeCheck(op, &PyODict_Type)) {
    _ = &op;
    return PyObject_TypeCheck(op, &PyODict_Type);
}
pub inline fn PyODict_CheckExact(op: anytype) @TypeOf(Py_IS_TYPE(op, &PyODict_Type)) {
    _ = &op;
    return Py_IS_TYPE(op, &PyODict_Type);
}
pub inline fn PyODict_SIZE(op: anytype) @TypeOf(PyDict_GET_SIZE(op)) {
    _ = &op;
    return PyDict_GET_SIZE(op);
}
pub inline fn PyODict_GetItem(od: anytype, key: anytype) @TypeOf(PyDict_GetItem(_PyObject_CAST(od), key)) {
    _ = &od;
    _ = &key;
    return PyDict_GetItem(_PyObject_CAST(od), key);
}
pub inline fn PyODict_GetItemWithError(od: anytype, key: anytype) @TypeOf(PyDict_GetItemWithError(_PyObject_CAST(od), key)) {
    _ = &od;
    _ = &key;
    return PyDict_GetItemWithError(_PyObject_CAST(od), key);
}
pub inline fn PyODict_Contains(od: anytype, key: anytype) @TypeOf(PyDict_Contains(_PyObject_CAST(od), key)) {
    _ = &od;
    _ = &key;
    return PyDict_Contains(_PyObject_CAST(od), key);
}
pub inline fn PyODict_Size(od: anytype) @TypeOf(PyDict_Size(_PyObject_CAST(od))) {
    _ = &od;
    return PyDict_Size(_PyObject_CAST(od));
}
pub inline fn PyODict_GetItemString(od: anytype, key: anytype) @TypeOf(PyDict_GetItemString(_PyObject_CAST(od), key)) {
    _ = &od;
    _ = &key;
    return PyDict_GetItemString(_PyObject_CAST(od), key);
}
pub const Py_ENUMOBJECT_H = "";
pub const Py_SETOBJECT_H = "";
pub inline fn PyFrozenSet_CheckExact(ob: anytype) @TypeOf(Py_IS_TYPE(ob, &PyFrozenSet_Type)) {
    _ = &ob;
    return Py_IS_TYPE(ob, &PyFrozenSet_Type);
}
pub inline fn PyFrozenSet_Check(ob: anytype) @TypeOf((Py_IS_TYPE(ob, &PyFrozenSet_Type) != 0) or (PyType_IsSubtype(Py_TYPE(ob), &PyFrozenSet_Type) != 0)) {
    _ = &ob;
    return (Py_IS_TYPE(ob, &PyFrozenSet_Type) != 0) or (PyType_IsSubtype(Py_TYPE(ob), &PyFrozenSet_Type) != 0);
}
pub inline fn PyAnySet_CheckExact(ob: anytype) @TypeOf((Py_IS_TYPE(ob, &PySet_Type) != 0) or (Py_IS_TYPE(ob, &PyFrozenSet_Type) != 0)) {
    _ = &ob;
    return (Py_IS_TYPE(ob, &PySet_Type) != 0) or (Py_IS_TYPE(ob, &PyFrozenSet_Type) != 0);
}
pub inline fn PyAnySet_Check(ob: anytype) @TypeOf((((Py_IS_TYPE(ob, &PySet_Type) != 0) or (Py_IS_TYPE(ob, &PyFrozenSet_Type) != 0)) or (PyType_IsSubtype(Py_TYPE(ob), &PySet_Type) != 0)) or (PyType_IsSubtype(Py_TYPE(ob), &PyFrozenSet_Type) != 0)) {
    _ = &ob;
    return (((Py_IS_TYPE(ob, &PySet_Type) != 0) or (Py_IS_TYPE(ob, &PyFrozenSet_Type) != 0)) or (PyType_IsSubtype(Py_TYPE(ob), &PySet_Type) != 0)) or (PyType_IsSubtype(Py_TYPE(ob), &PyFrozenSet_Type) != 0);
}
pub inline fn PySet_CheckExact(op: anytype) @TypeOf(Py_IS_TYPE(op, &PySet_Type)) {
    _ = &op;
    return Py_IS_TYPE(op, &PySet_Type);
}
pub inline fn PySet_Check(ob: anytype) @TypeOf((Py_IS_TYPE(ob, &PySet_Type) != 0) or (PyType_IsSubtype(Py_TYPE(ob), &PySet_Type) != 0)) {
    _ = &ob;
    return (Py_IS_TYPE(ob, &PySet_Type) != 0) or (PyType_IsSubtype(Py_TYPE(ob), &PySet_Type) != 0);
}
pub const Py_CPYTHON_SETOBJECT_H = "";
pub const PySet_MINSIZE = @as(c_int, 8);
pub const _PySet_CAST = @compileError("unable to translate C expr: unexpected token ','");
// /usr/include/python3.13/cpython/setobject.h:61:9
pub const Py_METHODOBJECT_H = "";
pub inline fn PyCFunction_CheckExact(op: anytype) @TypeOf(Py_IS_TYPE(op, &PyCFunction_Type)) {
    _ = &op;
    return Py_IS_TYPE(op, &PyCFunction_Type);
}
pub inline fn PyCFunction_Check(op: anytype) @TypeOf(PyObject_TypeCheck(op, &PyCFunction_Type)) {
    _ = &op;
    return PyObject_TypeCheck(op, &PyCFunction_Type);
}
pub const _PyCFunction_CAST = @compileError("unable to translate C expr: unexpected token ')'");
// /usr/include/python3.13/methodobject.h:52:9
pub const METH_VARARGS = @as(c_int, 0x0001);
pub const METH_KEYWORDS = @as(c_int, 0x0002);
pub const METH_NOARGS = @as(c_int, 0x0004);
pub const METH_O = @as(c_int, 0x0008);
pub const METH_CLASS = @as(c_int, 0x0010);
pub const METH_STATIC = @as(c_int, 0x0020);
pub const METH_COEXIST = @as(c_int, 0x0040);
pub const METH_FASTCALL = @as(c_int, 0x0080);
pub const METH_STACKLESS = @as(c_int, 0x0000);
pub const METH_METHOD = @as(c_int, 0x0200);
pub const Py_CPYTHON_METHODOBJECT_H = "";
pub const _PyCFunctionObject_CAST = @compileError("unable to translate C expr: unexpected token ','");
// /usr/include/python3.13/cpython/methodobject.h:16:9
pub const _PyCMethodObject_CAST = @compileError("unable to translate C expr: unexpected token ','");
// /usr/include/python3.13/cpython/methodobject.h:28:9
pub inline fn PyCMethod_CheckExact(op: anytype) @TypeOf(Py_IS_TYPE(op, &PyCMethod_Type)) {
    _ = &op;
    return Py_IS_TYPE(op, &PyCMethod_Type);
}
pub inline fn PyCMethod_Check(op: anytype) @TypeOf(PyObject_TypeCheck(op, &PyCMethod_Type)) {
    _ = &op;
    return PyObject_TypeCheck(op, &PyCMethod_Type);
}
pub const Py_MODULEOBJECT_H = "";
pub inline fn PyModule_Check(op: anytype) @TypeOf(PyObject_TypeCheck(op, &PyModule_Type)) {
    _ = &op;
    return PyObject_TypeCheck(op, &PyModule_Type);
}
pub inline fn PyModule_CheckExact(op: anytype) @TypeOf(Py_IS_TYPE(op, &PyModule_Type)) {
    _ = &op;
    return Py_IS_TYPE(op, &PyModule_Type);
}
pub const PyModuleDef_HEAD_INIT = @compileError("unable to translate C expr: unexpected token '{'");
// /usr/include/python3.13/moduleobject.h:60:9
pub const Py_mod_create = @as(c_int, 1);
pub const Py_mod_exec = @as(c_int, 2);
pub const Py_mod_multiple_interpreters = @as(c_int, 3);
pub const Py_mod_gil = @as(c_int, 4);
pub const _Py_mod_LAST_SLOT = @as(c_int, 4);
pub const Py_MOD_MULTIPLE_INTERPRETERS_NOT_SUPPORTED = std.zig.c_translation.cast(?*anyopaque, @as(c_int, 0));
pub const Py_MOD_MULTIPLE_INTERPRETERS_SUPPORTED = std.zig.c_translation.cast(?*anyopaque, @as(c_int, 1));
pub const Py_MOD_PER_INTERPRETER_GIL_SUPPORTED = std.zig.c_translation.cast(?*anyopaque, @as(c_int, 2));
pub const Py_MOD_GIL_USED = std.zig.c_translation.cast(?*anyopaque, @as(c_int, 0));
pub const Py_MOD_GIL_NOT_USED = std.zig.c_translation.cast(?*anyopaque, @as(c_int, 1));
pub const Py_MONITORING_H = "";
pub const Py_CPYTHON_MONITORING_H = "";
pub const PY_MONITORING_EVENT_PY_START = @as(c_int, 0);
pub const PY_MONITORING_EVENT_PY_RESUME = @as(c_int, 1);
pub const PY_MONITORING_EVENT_PY_RETURN = @as(c_int, 2);
pub const PY_MONITORING_EVENT_PY_YIELD = @as(c_int, 3);
pub const PY_MONITORING_EVENT_CALL = @as(c_int, 4);
pub const PY_MONITORING_EVENT_LINE = @as(c_int, 5);
pub const PY_MONITORING_EVENT_INSTRUCTION = @as(c_int, 6);
pub const PY_MONITORING_EVENT_JUMP = @as(c_int, 7);
pub const PY_MONITORING_EVENT_BRANCH = @as(c_int, 8);
pub const PY_MONITORING_EVENT_STOP_ITERATION = @as(c_int, 9);
pub inline fn PY_MONITORING_IS_INSTRUMENTED_EVENT(ev: anytype) @TypeOf(ev < _PY_MONITORING_LOCAL_EVENTS) {
    _ = &ev;
    return ev < _PY_MONITORING_LOCAL_EVENTS;
}
pub const PY_MONITORING_EVENT_RAISE = @as(c_int, 10);
pub const PY_MONITORING_EVENT_EXCEPTION_HANDLED = @as(c_int, 11);
pub const PY_MONITORING_EVENT_PY_UNWIND = @as(c_int, 12);
pub const PY_MONITORING_EVENT_PY_THROW = @as(c_int, 13);
pub const PY_MONITORING_EVENT_RERAISE = @as(c_int, 14);
pub const PY_MONITORING_EVENT_C_RETURN = @as(c_int, 15);
pub const PY_MONITORING_EVENT_C_RAISE = @as(c_int, 16);
pub const _PYMONITORING_IF_ACTIVE = @compileError("unable to translate C expr: unexpected token 'if'");
// /usr/include/python3.13/cpython/monitoring.h:107:9
pub const Py_FUNCOBJECT_H = "";
pub const _Py_COMMON_FIELDS = @compileError("unable to translate macro: undefined identifier `globals`");
// /usr/include/python3.13/cpython/funcobject.h:11:9
pub inline fn PyFunction_Check(op: anytype) @TypeOf(Py_IS_TYPE(op, &PyFunction_Type)) {
    _ = &op;
    return Py_IS_TYPE(op, &PyFunction_Type);
}
pub const _PyFunction_CAST = @compileError("unable to translate C expr: unexpected token ','");
// /usr/include/python3.13/cpython/funcobject.h:84:9
pub const PY_FOREACH_FUNC_EVENT = @compileError("unable to translate macro: undefined identifier `CREATE`");
// /usr/include/python3.13/cpython/funcobject.h:131:9
pub const Py_CLASSOBJECT_H = "";
pub inline fn PyMethod_Check(op: anytype) @TypeOf(Py_IS_TYPE(op, &PyMethod_Type)) {
    _ = &op;
    return Py_IS_TYPE(op, &PyMethod_Type);
}
pub const _PyMethod_CAST = @compileError("unable to translate C expr: unexpected token ','");
// /usr/include/python3.13/cpython/classobject.h:29:9
pub inline fn PyInstanceMethod_Check(op: anytype) @TypeOf(Py_IS_TYPE(op, &PyInstanceMethod_Type)) {
    _ = &op;
    return Py_IS_TYPE(op, &PyInstanceMethod_Type);
}
pub const _PyInstanceMethod_CAST = @compileError("unable to translate C expr: unexpected token ','");
// /usr/include/python3.13/cpython/classobject.h:56:9
pub const Py_FILEOBJECT_H = "";
pub const PY_STDIOTEXTMODE = "b";
pub const Py_CPYTHON_FILEOBJECT_H = "";
pub const Py_CAPSULE_H = "";
pub inline fn PyCapsule_CheckExact(op: anytype) @TypeOf(Py_IS_TYPE(op, &PyCapsule_Type)) {
    _ = &op;
    return Py_IS_TYPE(op, &PyCapsule_Type);
}
pub const Py_CODE_H = "";
pub const _PY_MONITORING_LOCAL_EVENTS = @as(c_int, 10);
pub const _PY_MONITORING_UNGROUPED_EVENTS = @as(c_int, 15);
pub const _PY_MONITORING_EVENTS = @as(c_int, 17);
pub const _PyCode_DEF = @compileError("unable to translate macro: undefined identifier `co_consts`");
// /usr/include/python3.13/cpython/code.h:73:9
pub const CO_OPTIMIZED = @as(c_int, 0x0001);
pub const CO_NEWLOCALS = @as(c_int, 0x0002);
pub const CO_VARARGS = @as(c_int, 0x0004);
pub const CO_VARKEYWORDS = @as(c_int, 0x0008);
pub const CO_NESTED = @as(c_int, 0x0010);
pub const CO_GENERATOR = @as(c_int, 0x0020);
pub const CO_COROUTINE = @as(c_int, 0x0080);
pub const CO_ITERABLE_COROUTINE = @as(c_int, 0x0100);
pub const CO_ASYNC_GENERATOR = @as(c_int, 0x0200);
pub const CO_FUTURE_DIVISION = std.zig.c_translation.promoteIntLiteral(c_int, 0x20000, .hex);
pub const CO_FUTURE_ABSOLUTE_IMPORT = std.zig.c_translation.promoteIntLiteral(c_int, 0x40000, .hex);
pub const CO_FUTURE_WITH_STATEMENT = std.zig.c_translation.promoteIntLiteral(c_int, 0x80000, .hex);
pub const CO_FUTURE_PRINT_FUNCTION = std.zig.c_translation.promoteIntLiteral(c_int, 0x100000, .hex);
pub const CO_FUTURE_UNICODE_LITERALS = std.zig.c_translation.promoteIntLiteral(c_int, 0x200000, .hex);
pub const CO_FUTURE_BARRY_AS_BDFL = std.zig.c_translation.promoteIntLiteral(c_int, 0x400000, .hex);
pub const CO_FUTURE_GENERATOR_STOP = std.zig.c_translation.promoteIntLiteral(c_int, 0x800000, .hex);
pub const CO_FUTURE_ANNOTATIONS = std.zig.c_translation.promoteIntLiteral(c_int, 0x1000000, .hex);
pub const CO_NO_MONITORING_EVENTS = std.zig.c_translation.promoteIntLiteral(c_int, 0x2000000, .hex);
pub const PY_PARSER_REQUIRES_FUTURE_KEYWORD = "";
pub const CO_MAXBLOCKS = @as(c_int, 21);
pub inline fn PyCode_Check(op: anytype) @TypeOf(Py_IS_TYPE(op, &PyCode_Type)) {
    _ = &op;
    return Py_IS_TYPE(op, &PyCode_Type);
}
pub const PY_FOREACH_CODE_EVENT = @compileError("unable to translate macro: undefined identifier `CREATE`");
// /usr/include/python3.13/cpython/code.h:243:9
pub const Py_PYFRAME_H = "";
pub const Py_CPYTHON_PYFRAME_H = "";
pub inline fn PyFrame_Check(op: anytype) @TypeOf(Py_IS_TYPE(op, &PyFrame_Type)) {
    _ = &op;
    return Py_IS_TYPE(op, &PyFrame_Type);
}
pub inline fn PyFrameLocalsProxy_Check(op: anytype) @TypeOf(Py_IS_TYPE(op, &PyFrameLocalsProxy_Type)) {
    _ = &op;
    return Py_IS_TYPE(op, &PyFrameLocalsProxy_Type);
}
pub const PyUnstable_EXECUTABLE_KIND_SKIP = @as(c_int, 0);
pub const PyUnstable_EXECUTABLE_KIND_PY_FUNCTION = @as(c_int, 1);
pub const PyUnstable_EXECUTABLE_KIND_BUILTIN_FUNCTION = @as(c_int, 3);
pub const PyUnstable_EXECUTABLE_KIND_METHOD_DESCRIPTOR = @as(c_int, 4);
pub const PyUnstable_EXECUTABLE_KINDS = @as(c_int, 5);
pub const Py_TRACEBACK_H = "";
pub inline fn PyTraceBack_Check(v: anytype) @TypeOf(Py_IS_TYPE(v, &PyTraceBack_Type)) {
    _ = &v;
    return Py_IS_TYPE(v, &PyTraceBack_Type);
}
pub const Py_CPYTHON_TRACEBACK_H = "";
pub const Py_SLICEOBJECT_H = "";
// /usr/include/python3.13/sliceobject.h:14:11: warning: macro 'Py_Ellipsis' contains a runtime value, translated to function
pub inline fn Py_Ellipsis() @TypeOf(&_Py_EllipsisObject) {
    return &_Py_EllipsisObject;
}
pub inline fn PySlice_Check(op: anytype) @TypeOf(Py_IS_TYPE(op, &PySlice_Type)) {
    _ = &op;
    return Py_IS_TYPE(op, &PySlice_Type);
}
pub const Py_CELLOBJECT_H = "";
pub inline fn PyCell_Check(op: anytype) @TypeOf(Py_IS_TYPE(op, &PyCell_Type)) {
    _ = &op;
    return Py_IS_TYPE(op, &PyCell_Type);
}
pub const Py_ITEROBJECT_H = "";
pub inline fn PySeqIter_Check(op: anytype) @TypeOf(Py_IS_TYPE(op, &PySeqIter_Type)) {
    _ = &op;
    return Py_IS_TYPE(op, &PySeqIter_Type);
}
pub inline fn PyCallIter_Check(op: anytype) @TypeOf(Py_IS_TYPE(op, &PyCallIter_Type)) {
    _ = &op;
    return Py_IS_TYPE(op, &PyCallIter_Type);
}
pub const Py_PYCORECONFIG_H = "";
pub const Py_PYSTATE_H = "";
pub const MAX_CO_EXTRA_USERS = @as(c_int, 255);
pub inline fn PyThreadState_GET() @TypeOf(PyThreadState_Get()) {
    return PyThreadState_Get();
}
pub const Py_CPYTHON_PYSTATE_H = "";
pub const PyTrace_CALL = @as(c_int, 0);
pub const PyTrace_EXCEPTION = @as(c_int, 1);
pub const PyTrace_LINE = @as(c_int, 2);
pub const PyTrace_RETURN = @as(c_int, 3);
pub const PyTrace_C_CALL = @as(c_int, 4);
pub const PyTrace_C_EXCEPTION = @as(c_int, 5);
pub const PyTrace_C_RETURN = @as(c_int, 6);
pub const PyTrace_OPCODE = @as(c_int, 7);
pub const Py_C_RECURSION_LIMIT = @as(c_int, 10000);
pub const _PyThreadState_UncheckedGet = PyThreadState_GetUnchecked;
pub const Py_GENOBJECT_H = "";
pub const _PyGenObject_HEAD = @compileError("unable to translate macro: undefined identifier `_weakreflist`");
// /usr/include/python3.13/cpython/genobject.h:14:9
pub inline fn PyGen_Check(op: anytype) @TypeOf(PyObject_TypeCheck(op, &PyGen_Type)) {
    _ = &op;
    return PyObject_TypeCheck(op, &PyGen_Type);
}
pub inline fn PyGen_CheckExact(op: anytype) @TypeOf(Py_IS_TYPE(op, &PyGen_Type)) {
    _ = &op;
    return Py_IS_TYPE(op, &PyGen_Type);
}
pub inline fn PyCoro_CheckExact(op: anytype) @TypeOf(Py_IS_TYPE(op, &PyCoro_Type)) {
    _ = &op;
    return Py_IS_TYPE(op, &PyCoro_Type);
}
pub inline fn PyAsyncGen_CheckExact(op: anytype) @TypeOf(Py_IS_TYPE(op, &PyAsyncGen_Type)) {
    _ = &op;
    return Py_IS_TYPE(op, &PyAsyncGen_Type);
}
pub inline fn PyAsyncGenASend_CheckExact(op: anytype) @TypeOf(Py_IS_TYPE(op, &_PyAsyncGenASend_Type)) {
    _ = &op;
    return Py_IS_TYPE(op, &_PyAsyncGenASend_Type);
}
pub const Py_DESCROBJECT_H = "";
pub const Py_T_SHORT = @as(c_int, 0);
pub const Py_T_INT = @as(c_int, 1);
pub const Py_T_LONG = @as(c_int, 2);
pub const Py_T_FLOAT = @as(c_int, 3);
pub const Py_T_DOUBLE = @as(c_int, 4);
pub const Py_T_STRING = @as(c_int, 5);
pub const _Py_T_OBJECT = @as(c_int, 6);
pub const Py_T_CHAR = @as(c_int, 7);
pub const Py_T_BYTE = @as(c_int, 8);
pub const Py_T_UBYTE = @as(c_int, 9);
pub const Py_T_USHORT = @as(c_int, 10);
pub const Py_T_UINT = @as(c_int, 11);
pub const Py_T_ULONG = @as(c_int, 12);
pub const Py_T_STRING_INPLACE = @as(c_int, 13);
pub const Py_T_BOOL = @as(c_int, 14);
pub const Py_T_OBJECT_EX = @as(c_int, 16);
pub const Py_T_LONGLONG = @as(c_int, 17);
pub const Py_T_ULONGLONG = @as(c_int, 18);
pub const Py_T_PYSSIZET = @as(c_int, 19);
pub const _Py_T_NONE = @as(c_int, 20);
pub const Py_READONLY = @as(c_int, 1);
pub const Py_AUDIT_READ = @as(c_int, 2);
pub const _Py_WRITE_RESTRICTED = @as(c_int, 4);
pub const Py_RELATIVE_OFFSET = @as(c_int, 8);
pub const Py_CPYTHON_DESCROBJECT_H = "";
pub const PyWrapperFlag_KEYWORDS = @as(c_int, 1);
pub const PyDescr_COMMON = @compileError("unable to translate macro: undefined identifier `d_common`");
// /usr/include/python3.13/cpython/descrobject.h:33:9
pub inline fn PyDescr_TYPE(x: anytype) @TypeOf(std.zig.c_translation.cast(?*PyDescrObject, x).*.d_type) {
    _ = &x;
    return std.zig.c_translation.cast(?*PyDescrObject, x).*.d_type;
}
pub inline fn PyDescr_NAME(x: anytype) @TypeOf(std.zig.c_translation.cast(?*PyDescrObject, x).*.d_name) {
    _ = &x;
    return std.zig.c_translation.cast(?*PyDescrObject, x).*.d_name;
}
pub const Py_GENERICALIASOBJECT_H = "";
pub const Py_WARNINGS_H = "";
pub const Py_CPYTHON_WARNINGS_H = "";
pub inline fn PyErr_Warn(category: anytype, msg: anytype) @TypeOf(PyErr_WarnEx(category, msg, @as(c_int, 1))) {
    _ = &category;
    _ = &msg;
    return PyErr_WarnEx(category, msg, @as(c_int, 1));
}
pub const Py_WEAKREFOBJECT_H = "";
pub inline fn PyWeakref_CheckRef(op: anytype) @TypeOf(PyObject_TypeCheck(op, &_PyWeakref_RefType)) {
    _ = &op;
    return PyObject_TypeCheck(op, &_PyWeakref_RefType);
}
pub inline fn PyWeakref_CheckRefExact(op: anytype) @TypeOf(Py_IS_TYPE(op, &_PyWeakref_RefType)) {
    _ = &op;
    return Py_IS_TYPE(op, &_PyWeakref_RefType);
}
pub inline fn PyWeakref_CheckProxy(op: anytype) @TypeOf((Py_IS_TYPE(op, &_PyWeakref_ProxyType) != 0) or (Py_IS_TYPE(op, &_PyWeakref_CallableProxyType) != 0)) {
    _ = &op;
    return (Py_IS_TYPE(op, &_PyWeakref_ProxyType) != 0) or (Py_IS_TYPE(op, &_PyWeakref_CallableProxyType) != 0);
}
pub inline fn PyWeakref_Check(op: anytype) @TypeOf((PyWeakref_CheckRef(op) != 0) or (PyWeakref_CheckProxy(op) != 0)) {
    _ = &op;
    return (PyWeakref_CheckRef(op) != 0) or (PyWeakref_CheckProxy(op) != 0);
}
pub const Py_CPYTHON_WEAKREFOBJECT_H = "";
pub const Py_STRUCTSEQ_H = "";
pub const PyStructSequence_SET_ITEM = PyStructSequence_SetItem;
pub const PyStructSequence_GET_ITEM = PyStructSequence_GetItem;
pub const Py_PICKLEBUFOBJECT_H = "";
pub inline fn PyPickleBuffer_Check(op: anytype) @TypeOf(Py_IS_TYPE(op, &PyPickleBuffer_Type)) {
    _ = &op;
    return Py_IS_TYPE(op, &PyPickleBuffer_Type);
}
pub const Py_PYTIME_H = "";
pub const Py_CODECREGISTRY_H = "";
pub const Py_PYTHREAD_H = "";
pub const PY_HAVE_THREAD_NATIVE_ID = "";
pub const WAIT_LOCK = @as(c_int, 1);
pub const NOWAIT_LOCK = @as(c_int, 0);
pub const PY_TIMEOUT_T = c_longlong;
pub const Py_CPYTHON_PYTHREAD_H = "";
pub const PYTHREAD_INVALID_THREAD_ID = std.zig.c_translation.cast(c_ulong, -@as(c_int, 1));
pub const _PTHREAD_H = @as(c_int, 1);
pub const _SCHED_H = @as(c_int, 1);
pub const _BITS_SCHED_H = @as(c_int, 1);
pub const __jmp_buf_tag_defined = @as(c_int, 1);
// /usr/include/pthread.h:738:11
pub inline fn PyContext_CheckExact(o: anytype) @TypeOf(Py_IS_TYPE(o, &PyContext_Type)) {
    _ = &o;
    return Py_IS_TYPE(o, &PyContext_Type);
}
pub inline fn PyContextVar_CheckExact(o: anytype) @TypeOf(Py_IS_TYPE(o, &PyContextVar_Type)) {
    _ = &o;
    return Py_IS_TYPE(o, &PyContextVar_Type);
}
pub inline fn PyContextToken_CheckExact(o: anytype) @TypeOf(Py_IS_TYPE(o, &PyContextToken_Type)) {
    _ = &o;
    return Py_IS_TYPE(o, &PyContextToken_Type);
}
pub const Py_MODSUPPORT_H = "";
pub const PyModule_AddIntMacro = @compileError("unable to translate C expr: unexpected token '#'");
// /usr/include/python3.13/modsupport.h:47:9
pub const PyModule_AddStringMacro = @compileError("unable to translate C expr: unexpected token '#'");
// /usr/include/python3.13/modsupport.h:48:9
pub const Py_CLEANUP_SUPPORTED = std.zig.c_translation.promoteIntLiteral(c_int, 0x20000, .hex);
pub const PYTHON_API_VERSION = @as(c_int, 1013);
pub const PYTHON_API_STRING = "1013";
pub const PYTHON_ABI_VERSION = @as(c_int, 3);
pub const PYTHON_ABI_STRING = "3";
pub inline fn PyModule_Create(module: anytype) @TypeOf(PyModule_Create2(module, PYTHON_API_VERSION)) {
    _ = &module;
    return PyModule_Create2(module, PYTHON_API_VERSION);
}
pub inline fn PyModule_FromDefAndSpec(module: anytype, spec: anytype) @TypeOf(PyModule_FromDefAndSpec2(module, spec, PYTHON_API_VERSION)) {
    _ = &module;
    _ = &spec;
    return PyModule_FromDefAndSpec2(module, spec, PYTHON_API_VERSION);
}
pub const Py_CPYTHON_MODSUPPORT_H = "";
pub const Py_COMPILE_H = "";
pub const Py_single_input = @as(c_int, 256);
pub const Py_file_input = @as(c_int, 257);
pub const Py_eval_input = @as(c_int, 258);
pub const Py_func_type_input = @as(c_int, 345);
pub const Py_CPYTHON_COMPILE_H = "";
pub const PyCF_MASK = ((((((CO_FUTURE_DIVISION | CO_FUTURE_ABSOLUTE_IMPORT) | CO_FUTURE_WITH_STATEMENT) | CO_FUTURE_PRINT_FUNCTION) | CO_FUTURE_UNICODE_LITERALS) | CO_FUTURE_BARRY_AS_BDFL) | CO_FUTURE_GENERATOR_STOP) | CO_FUTURE_ANNOTATIONS;
pub const PyCF_MASK_OBSOLETE = CO_NESTED;
pub const PyCF_SOURCE_IS_UTF8 = @as(c_int, 0x0100);
pub const PyCF_DONT_IMPLY_DEDENT = @as(c_int, 0x0200);
pub const PyCF_ONLY_AST = @as(c_int, 0x0400);
pub const PyCF_IGNORE_COOKIE = @as(c_int, 0x0800);
pub const PyCF_TYPE_COMMENTS = @as(c_int, 0x1000);
pub const PyCF_ALLOW_TOP_LEVEL_AWAIT = @as(c_int, 0x2000);
pub const PyCF_ALLOW_INCOMPLETE_INPUT = @as(c_int, 0x4000);
pub const PyCF_OPTIMIZED_AST = std.zig.c_translation.promoteIntLiteral(c_int, 0x8000, .hex) | PyCF_ONLY_AST;
pub const PyCF_COMPILE_MASK = ((((PyCF_ONLY_AST | PyCF_ALLOW_TOP_LEVEL_AWAIT) | PyCF_TYPE_COMMENTS) | PyCF_DONT_IMPLY_DEDENT) | PyCF_ALLOW_INCOMPLETE_INPUT) | PyCF_OPTIMIZED_AST;
pub const _PyCompilerFlags_INIT = std.mem.zeroInit(PyCompilerFlags, .{
    .cf_flags = @as(c_int, 0),
    .cf_feature_version = PY_MINOR_VERSION,
});
pub const FUTURE_NESTED_SCOPES = "nested_scopes";
pub const FUTURE_GENERATORS = "generators";
pub const FUTURE_DIVISION = "division";
pub const FUTURE_ABSOLUTE_IMPORT = "absolute_import";
pub const FUTURE_WITH_STATEMENT = "with_statement";
pub const FUTURE_PRINT_FUNCTION = "print_function";
pub const FUTURE_UNICODE_LITERALS = "unicode_literals";
pub const FUTURE_BARRY_AS_BDFL = "barry_as_FLUFL";
pub const FUTURE_GENERATOR_STOP = "generator_stop";
pub const FUTURE_ANNOTATIONS = "annotations";
pub const Py_PYTHONRUN_H = "";
pub const PYOS_STACK_MARGIN = @as(c_int, 2048);
pub const Py_CPYTHON_PYTHONRUN_H = "";
pub inline fn Py_CompileStringFlags(str: anytype, p: anytype, s: anytype, f: anytype) @TypeOf(Py_CompileStringExFlags(str, p, s, f, -@as(c_int, 1))) {
    _ = &str;
    _ = &p;
    _ = &s;
    _ = &f;
    return Py_CompileStringExFlags(str, p, s, f, -@as(c_int, 1));
}
pub const Py_PYLIFECYCLE_H = "";
pub const Py_CPYTHON_PYLIFECYCLE_H = "";
pub const PyInterpreterConfig_DEFAULT_GIL = @as(c_int, 0);
pub const PyInterpreterConfig_SHARED_GIL = @as(c_int, 1);
pub const PyInterpreterConfig_OWN_GIL = @as(c_int, 2);
pub const _PyInterpreterConfig_INIT = @compileError("unable to translate C expr: unexpected token '{'");
// /usr/include/python3.13/cpython/pylifecycle.h:55:9
pub const _PyInterpreterConfig_LEGACY_CHECK_MULTI_INTERP_EXTENSIONS = @as(c_int, 0);
pub const _PyInterpreterConfig_LEGACY_INIT = @compileError("unable to translate C expr: unexpected token '{'");
// /usr/include/python3.13/cpython/pylifecycle.h:75:9
pub const Py_CEVAL_H = "";
pub const Py_BEGIN_ALLOW_THREADS = @compileError("unable to translate macro: undefined identifier `_save`");
// /usr/include/python3.13/ceval.h:119:9
pub const Py_BLOCK_THREADS = @compileError("unable to translate macro: undefined identifier `_save`");
// /usr/include/python3.13/ceval.h:122:9
pub const Py_UNBLOCK_THREADS = @compileError("unable to translate macro: undefined identifier `_save`");
// /usr/include/python3.13/ceval.h:123:9
pub const Py_END_ALLOW_THREADS = @compileError("unable to translate macro: undefined identifier `_save`");
// /usr/include/python3.13/ceval.h:124:9
pub const FVC_MASK = @as(c_int, 0x3);
pub const FVC_NONE = @as(c_int, 0x0);
pub const FVC_STR = @as(c_int, 0x1);
pub const FVC_REPR = @as(c_int, 0x2);
pub const FVC_ASCII = @as(c_int, 0x3);
pub const FVS_MASK = @as(c_int, 0x4);
pub const FVS_HAVE_SPEC = @as(c_int, 0x4);
pub const Py_CPYTHON_CEVAL_H = "";
pub const Py_SYSMODULE_H = "";
pub const Py_CPYTHON_SYSMODULE_H = "";
pub const Py_OSMODULE_H = "";
pub const Py_INTRCHECK_H = "";
pub const Py_IMPORT_H = "";
pub inline fn PyImport_ImportModuleEx(n: anytype, g: anytype, l: anytype, f: anytype) @TypeOf(PyImport_ImportModuleLevel(n, g, l, f, @as(c_int, 0))) {
    _ = &n;
    _ = &g;
    _ = &l;
    _ = &f;
    return PyImport_ImportModuleLevel(n, g, l, f, @as(c_int, 0));
}
pub const Py_CPYTHON_IMPORT_H = "";
pub const Py_ABSTRACTOBJECT_H = "";
pub const PY_VECTORCALL_ARGUMENTS_OFFSET = _Py_STATIC_CAST(usize, @as(c_int, 1)) << ((@as(c_int, 8) * std.zig.c_translation.sizeof(usize)) - @as(c_int, 1));
pub inline fn PySequence_Fast_GET_SIZE(o: anytype) @TypeOf(if (PyList_Check(o)) PyList_GET_SIZE(o) else PyTuple_GET_SIZE(o)) {
    _ = &o;
    return if (PyList_Check(o)) PyList_GET_SIZE(o) else PyTuple_GET_SIZE(o);
}
pub inline fn PySequence_Fast_GET_ITEM(o: anytype, i: anytype) @TypeOf(if (PyList_Check(o)) PyList_GET_ITEM(o, i) else PyTuple_GET_ITEM(o, i)) {
    _ = &o;
    _ = &i;
    return if (PyList_Check(o)) PyList_GET_ITEM(o, i) else PyTuple_GET_ITEM(o, i);
}
pub inline fn PySequence_Fast_ITEMS(sf: anytype) @TypeOf(if (PyList_Check(sf)) std.zig.c_translation.cast(?*PyListObject, sf).*.ob_item else std.zig.c_translation.cast(?*PyTupleObject, sf).*.ob_item) {
    _ = &sf;
    return if (PyList_Check(sf)) std.zig.c_translation.cast(?*PyListObject, sf).*.ob_item else std.zig.c_translation.cast(?*PyTupleObject, sf).*.ob_item;
}
pub inline fn PyMapping_DelItemString(O: anytype, K: anytype) @TypeOf(PyObject_DelItemString(O, K)) {
    _ = &O;
    _ = &K;
    return PyObject_DelItemString(O, K);
}
pub inline fn PyMapping_DelItem(O: anytype, K: anytype) @TypeOf(PyObject_DelItem(O, K)) {
    _ = &O;
    _ = &K;
    return PyObject_DelItem(O, K);
}
pub const Py_CPYTHON_ABSTRACTOBJECT_H = "";
pub const _PyObject_Vectorcall = PyObject_Vectorcall;
pub const _PyObject_VectorcallMethod = PyObject_VectorcallMethod;
pub const _PyObject_FastCallDict = PyObject_VectorcallDict;
pub const _PyVectorcall_Function = PyVectorcall_Function;
pub const _PyObject_CallOneArg = PyObject_CallOneArg;
pub const _PyObject_CallMethodNoArgs = PyObject_CallMethodNoArgs;
pub const _PyObject_CallMethodOneArg = PyObject_CallMethodOneArg;
pub inline fn PySequence_ITEM(o: anytype, i: anytype) @TypeOf(Py_TYPE(o).*.tp_as_sequence.*.sq_item(o, i)) {
    _ = &o;
    _ = &i;
    return Py_TYPE(o).*.tp_as_sequence.*.sq_item(o, i);
}
pub const Py_BLTINMODULE_H = "";
pub const Py_CRITICAL_SECTION_H = "";
pub const Py_CPYTHON_CRITICAL_SECTION_H = "";
pub const Py_BEGIN_CRITICAL_SECTION = @compileError("unable to translate C expr: unexpected token '{'");
// /usr/include/python3.13/cpython/critical_section.h:86:10
pub const Py_END_CRITICAL_SECTION = @compileError("unable to translate C expr: unexpected token '}'");
// /usr/include/python3.13/cpython/critical_section.h:88:10
pub const Py_BEGIN_CRITICAL_SECTION2 = @compileError("unable to translate C expr: unexpected token '{'");
// /usr/include/python3.13/cpython/critical_section.h:90:10
pub const Py_END_CRITICAL_SECTION2 = @compileError("unable to translate C expr: unexpected token '}'");
// /usr/include/python3.13/cpython/critical_section.h:92:10
pub const PYCTYPE_H = "";
pub const PY_CTF_LOWER = @as(c_int, 0x01);
pub const PY_CTF_UPPER = @as(c_int, 0x02);
pub const PY_CTF_ALPHA = PY_CTF_LOWER | PY_CTF_UPPER;
pub const PY_CTF_DIGIT = @as(c_int, 0x04);
pub const PY_CTF_ALNUM = PY_CTF_ALPHA | PY_CTF_DIGIT;
pub const PY_CTF_SPACE = @as(c_int, 0x08);
pub const PY_CTF_XDIGIT = @as(c_int, 0x10);
pub inline fn Py_ISLOWER(c: anytype) @TypeOf(_Py_ctype_table[@as(usize, @intCast(Py_CHARMASK(c)))] & PY_CTF_LOWER) {
    _ = &c;
    return _Py_ctype_table[@as(usize, @intCast(Py_CHARMASK(c)))] & PY_CTF_LOWER;
}
pub inline fn Py_ISUPPER(c: anytype) @TypeOf(_Py_ctype_table[@as(usize, @intCast(Py_CHARMASK(c)))] & PY_CTF_UPPER) {
    _ = &c;
    return _Py_ctype_table[@as(usize, @intCast(Py_CHARMASK(c)))] & PY_CTF_UPPER;
}
pub inline fn Py_ISALPHA(c: anytype) @TypeOf(_Py_ctype_table[@as(usize, @intCast(Py_CHARMASK(c)))] & PY_CTF_ALPHA) {
    _ = &c;
    return _Py_ctype_table[@as(usize, @intCast(Py_CHARMASK(c)))] & PY_CTF_ALPHA;
}
pub inline fn Py_ISDIGIT(c: anytype) @TypeOf(_Py_ctype_table[@as(usize, @intCast(Py_CHARMASK(c)))] & PY_CTF_DIGIT) {
    _ = &c;
    return _Py_ctype_table[@as(usize, @intCast(Py_CHARMASK(c)))] & PY_CTF_DIGIT;
}
pub inline fn Py_ISXDIGIT(c: anytype) @TypeOf(_Py_ctype_table[@as(usize, @intCast(Py_CHARMASK(c)))] & PY_CTF_XDIGIT) {
    _ = &c;
    return _Py_ctype_table[@as(usize, @intCast(Py_CHARMASK(c)))] & PY_CTF_XDIGIT;
}
pub inline fn Py_ISALNUM(c: anytype) @TypeOf(_Py_ctype_table[@as(usize, @intCast(Py_CHARMASK(c)))] & PY_CTF_ALNUM) {
    _ = &c;
    return _Py_ctype_table[@as(usize, @intCast(Py_CHARMASK(c)))] & PY_CTF_ALNUM;
}
pub inline fn Py_ISSPACE(c: anytype) @TypeOf(_Py_ctype_table[@as(usize, @intCast(Py_CHARMASK(c)))] & PY_CTF_SPACE) {
    _ = &c;
    return _Py_ctype_table[@as(usize, @intCast(Py_CHARMASK(c)))] & PY_CTF_SPACE;
}
pub inline fn Py_TOLOWER(c: anytype) @TypeOf(_Py_ctype_tolower[@as(usize, @intCast(Py_CHARMASK(c)))]) {
    _ = &c;
    return _Py_ctype_tolower[@as(usize, @intCast(Py_CHARMASK(c)))];
}
pub inline fn Py_TOUPPER(c: anytype) @TypeOf(_Py_ctype_toupper[@as(usize, @intCast(Py_CHARMASK(c)))]) {
    _ = &c;
    return _Py_ctype_toupper[@as(usize, @intCast(Py_CHARMASK(c)))];
}
pub const Py_STRTOD_H = "";
pub const Py_DTSF_SIGN = @as(c_int, 0x01);
pub const Py_DTSF_ADD_DOT_0 = @as(c_int, 0x02);
pub const Py_DTSF_ALT = @as(c_int, 0x04);
pub const Py_DTSF_NO_NEG_0 = @as(c_int, 0x08);
pub const Py_DTST_FINITE = @as(c_int, 0);
pub const Py_DTST_INFINITE = @as(c_int, 1);
pub const Py_DTST_NAN = @as(c_int, 2);
pub const Py_STRCMP_H = "";
pub const PyOS_strnicmp = PyOS_mystrnicmp;
pub const PyOS_stricmp = PyOS_mystricmp;
pub const Py_FILEUTILS_H = "";
pub const Py_CPYTHON_FILEUTILS_H = "";
pub const Py_PYFPE_H = "";
pub const PyFPE_START_PROTECT = @compileError("unable to translate C expr: unexpected token ''");
// /usr/include/python3.13/cpython/pyfpe.h:11:9
pub const PyFPE_END_PROTECT = @compileError("unable to translate C expr: unexpected token ''");
// /usr/include/python3.13/cpython/pyfpe.h:12:9
pub const Py_TRACEMALLOC_H = "";

extern fn PyUnstable_Module_SetGIL(module: *PyObject, gil: ?*anyopaque) void;
pub const pyunstable_module_setgil = if (builtin.single_threaded) null else PyUnstable_Module_SetGIL;
