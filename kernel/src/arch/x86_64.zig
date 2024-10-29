pub fn cpuInit() void {}

pub inline fn halt() noreturn {
    while (true) {
        asm volatile ("hlt; cli");
    }
}

pub const serial = @import("x86_64/serial.zig");
