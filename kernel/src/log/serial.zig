pub fn writeByte(value: u8) void {
    switch (builtin.cpu.arch) {
        .x86_64 => x86_64_serial.writeByte(value),
        else => unreachable,
    }
}

pub fn write(msg: []const u8) void {
    for (msg) |value| {
        writeByte(value);
    }
}
pub fn init() void {
    switch (builtin.cpu.arch) {
        .x86_64 => x86_64_serial.init(),
        else => unreachable,
    }
}

const builtin = @import("builtin");
const x86_64_serial = @import("../arch/x86_64/serial.zig");
