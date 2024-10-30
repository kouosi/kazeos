pub fn cpuInit() void {
    gdt.init();
    idt.init();
}

pub inline fn halt() noreturn {
    while (true) {
        asm volatile ("hlt; cli");
    }
}

const gdt = @import("x86_64/gdt.zig");
const idt = @import("x86_64/idt.zig");
pub const serial = @import("x86_64/serial.zig");
