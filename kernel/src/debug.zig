pub fn dumpStackTrace(start_addr: usize) void {
    if (builtin.strip_debug_info) {
        std.log.err("Unable to dump stack trace: debug info stripped\n", .{}) catch return;
        return;
    }
    write("Stack Trace: \n", .{});
    var it = std.debug.StackIterator.init(start_addr, null);
    while (it.next()) |addr| {
        write("  -> addr: 0x{x}\n", .{addr});
    }
}

pub fn panicHandler(msg: []const u8, trace_addr: usize) noreturn {
    @setCold(true);

    term.setPanic();
    write("panic: {s}\naddr: {x}\n", .{ msg, trace_addr });
    dumpStackTrace(trace_addr);

    arch.halt();
}

pub fn write(comptime fmt: []const u8, args: anytype) void {
    var buff: [1024]u8 = undefined;
    const msg = std.fmt.bufPrint(&buff, fmt, args) catch return;
    arch.serial.write(msg, .panic);
    term.write(msg, 0xffffff);
}

const std = @import("std");
const builtin = @import("builtin");
const arch = @import("arch.zig");
const term = @import("log/term.zig");
