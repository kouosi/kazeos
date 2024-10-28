pub const std_options: std.Options = .{ .logFn = @import("log.zig").logFn };

pub export var base_revision: limine.BaseRevision = .{ .revision = 2 };
pub export var fb_req: limine.FramebufferRequest = .{};
pub export var mmap_req: limine.MemoryMapRequest = .{};

pub fn panic(msg: []const u8, _: ?*std.builtin.StackTrace, last_ret_addr: ?usize) noreturn {
    @setCold(true);
    var buff: [1024]u8 = undefined;
    const fmt = std.fmt.bufPrint(&buff, "PANIC: {s}\nADDR: {x}", .{ msg, last_ret_addr orelse 0 }) catch halt();
    log.panic(fmt);
    halt();
}

inline fn halt() noreturn {
    while (true) {
        switch (builtin.cpu.arch) {
            .x86_64 => asm volatile ("hlt"),
            else => unreachable,
        }
    }
}

export fn _start() callconv(.C) noreturn {
    if (!base_revision.is_supported()) halt();

    if (fb_req.response == null) halt();
    // TODO: Make framebuffer optional
    if (fb_req.response) |fb_res| {
        if (fb_res.framebuffer_count < 1) {
            halt();
        }
        log.init(fb_res.framebuffers()[0]);
    }

    std.log.info("Hello, World!", .{});
    halt();
}

const std = @import("std");
const builtin = @import("builtin");
const limine = @import("limine");
const log = @import("log.zig");
