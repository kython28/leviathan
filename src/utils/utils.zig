const std = @import("std");
const builtin = @import("builtin");

const python_c = @import("python_c");
const jdz_allocator = @import("jdz_allocator");

const CallbackManager = @import("../callback_manager.zig");


pub var gpa = blk: {
    if (builtin.mode == .Debug) {
        break :blk std.heap.GeneralPurposeAllocator(.{}){};
    }else{
        break :blk jdz_allocator.JdzAllocator(.{}).init();
    }
};

pub inline fn get_data_ptr(comptime T: type, leviathan_pyobject: anytype) *T {
    const type_info = @typeInfo(@TypeOf(leviathan_pyobject));
    if (type_info != .pointer) {
        @compileError("leviathan_pyobject must be a pointer");
    }

    if (type_info.pointer.size != .One) {
        @compileError("leviathan_pyobject must be a single pointer");
    }

    if (!@hasField(type_info.pointer.child, "data")) {
        @compileError("T must have a data field");
    }

    return @as(*T, @ptrFromInt(@intFromPtr(leviathan_pyobject) + @offsetOf(type_info.pointer.child, "data")));
}

pub inline fn get_parent_ptr(comptime T: type, leviathan_object: anytype) *T {
    const type_info = @typeInfo(@TypeOf(leviathan_object));
    if (type_info != .pointer) {
        @compileError("leviathan_pyobject must be a pointer");
    }

    if (type_info.pointer.size != .One) {
        @compileError("leviathan_pyobject must be a single pointer");
    }
    
    return @as(*T, @ptrFromInt(@intFromPtr(leviathan_object) - @offsetOf(T, "data")));
}

pub fn print_error_traces(
    trace: ?*std.builtin.StackTrace, @"error": anyerror,
) void {
    const writer = std.io.getStdErr().writer();
    if (trace == null) {
        writer.print("No zig's traces available", .{}) catch unreachable;
        return;
    }

    var debug_info = std.debug.getSelfDebugInfo() catch {
        writer.print("No zig's traces available", .{}) catch unreachable;
        return;
    };
    defer debug_info.deinit();

    std.debug.writeStackTrace(
        trace.?.*, writer, debug_info,
        std.io.tty.detectConfig(std.io.getStdOut())
    ) catch {
        writer.print("No zig's traces available", .{}) catch unreachable;
        return;
    };
    writer.print("\nError name: {s}\n", .{@errorName(@"error")}) catch unreachable;
}

fn get_func_return_type(func: anytype) type {
    const func_type_info = @typeInfo(@TypeOf(func));
    if (func_type_info != .@"fn") {
        @compileError("func argument must be a function");
    }

    const return_type = @typeInfo(func_type_info.@"fn".return_type.?);
    if (return_type != .error_union) {
        @compileError("return type must be an error union");
    }

    const return_payload = return_type.error_union.payload;
    if (return_payload == CallbackManager.ExecuteCallbacksReturn) {
        return return_payload;
    }

    return switch (@typeInfo(return_payload)) {
        .int => return_payload,
        .noreturn => @compileError("return type must not be noreturn"),
        else => ?return_payload
    };
}

pub inline fn handle_zig_function_error(@"error": anyerror, return_value: anytype) @TypeOf(return_value) {
    switch (@"error") {
        error.PythonError => {},
        error.OutOfMemory => python_c.raise_python_error(python_c.PyExc_MemoryError, null),
        else => {
            const err_trace = @errorReturnTrace();
            print_error_traces(err_trace, @"error");

            python_c.raise_python_runtime_error(@errorName(@"error"));
        }
    }

    return return_value;
}

pub inline fn execute_zig_function(func: anytype, args: anytype) get_func_return_type(func) {
    return @call(.auto, func, args) catch |err| {
        const return_value = blk: {
            const ret_type = get_func_return_type(func);
            const ret_type_info = @typeInfo(ret_type);
            if (ret_type_info == .int) {
                if (ret_type_info.int.signedness == .signed) {
                    break :blk -1;
                }else{
                    break :blk 0;
                }
            }
            break :blk null;
        };

        return handle_zig_function_error(err, return_value);
    };
}

