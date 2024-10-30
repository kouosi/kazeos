pub fn cpuInit() void {
    gdt.init();
}

pub inline fn halt() noreturn {
    while (true) {
        asm volatile ("hlt; cli");
    }
}

const gdt = @import("x86_64/gdt.zig");
pub const serial = @import("x86_64/serial.zig");
