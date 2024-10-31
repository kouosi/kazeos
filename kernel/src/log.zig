inline fn print(level: std.log.Level, comptime format: []const u8, args: anytype) void {
    var buf: [1024]u8 = undefined;

    const msg = std.fmt.bufPrint(&buf, format, args) catch return;

    serial.write(msg, switch (level) {
        .err => .red,
        .warn => .yellow,
        .debug => .blue,
        .info => .white,
    });
    term.write(msg, switch (level) {
        .err => 0xcc241d,
        .warn => 0xfabd2f,
        .debug => 0x458588,
        .info => 0x928374,
    });
}

pub fn logFn(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    const scope_prefix = comptime if (scope != .default) "(" ++ @tagName(scope) ++ ")" else "";
    const prefix = comptime level.asText() ++ scope_prefix ++ ": ";
    print(level, prefix ++ format ++ "\n", args);
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
