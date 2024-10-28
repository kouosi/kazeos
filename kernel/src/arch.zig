pub fn cpuInit() void {
    switch (builtin.cpu.arch) {
        .x86_64 => x86_64.cpuInit(),
        else => unreachable,
    }
}

pub const serial = switch (builtin.cpu.arch) {
    .x86_64 => @import("arch/x86_64/serial.zig"),
    else => unreachable,
};

const builtin = @import("builtin");
const x86_64 = @import("arch/x86_64.zig");
