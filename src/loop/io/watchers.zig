const python_c = @import("python_c");
const PyObject = *python_c.PyObject;

const utils = @import("../../utils/utils.zig");

const Handle = @import("../../handle.zig");
const Loop = @import("../main.zig");

const LoopObject = Loop.Python.LoopObject;


pub fn loop_add_reader(
    self: ?*LoopObject, args: ?[*]?PyObject, nargs: isize
) callconv(.C) ?*Handle.PythonHandleObject {
    
}
