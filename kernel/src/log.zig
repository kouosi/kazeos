fn print(comptime format: []const u8, args: anytype) void {
    var buf: [1024]u8 = undefined;
    const msg = std.fmt.bufPrint(&buf, format, args) catch return;
    serial.write(msg);
    term.write(msg);
}

pub fn logFn(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    const scope_prefix = comptime if (scope != .default) "(" ++ @tagName(scope) ++ ")" else "";
    const prefix = comptime level.asText() ++ scope_prefix ++ ": ";
    print(prefix ++ format ++ "\n", args);
}

pub fn panic(msg: []const u8) void {
    serial.write(msg);
    term.panic(msg);
}

pub fn init(fb: *limine.Framebuffer) void {
    serial.init();
    term.init(fb);
}

const std = @import("std");
const builtin = @import("builtin");
const limine = @import("limine");
const serial = @import("arch.zig").serial;
const term = @import("log/term.zig");
