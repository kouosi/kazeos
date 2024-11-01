pub const std_options: std.Options = .{ .logFn = @import("log.zig").logFn };

pub export var base_revision: limine.BaseRevision = .{ .revision = 2 };
pub export var fb_req: limine.FramebufferRequest = .{};
pub export var mmap_req: limine.MemoryMapRequest = .{};
pub export var hhdm_req: limine.HhdmRequest = .{};
pub export var krn_file_req: limine.KernelFileRequest = .{};

pub fn panic(msg: []const u8, _: ?*std.builtin.StackTrace, first_trace_addr: ?usize) noreturn {
    @setCold(true);

    const trace_addr = first_trace_addr orelse @returnAddress();
    debug.panicHandler(msg, trace_addr);
}

fn getLimineResponse(res_type: type, req: anytype) *res_type {
    if (req.response) |response| {
        return response;
    } else {
        std.debug.panic("Unable to get {s} found null", .{@typeName(res_type)});
    }
}

export fn _start() callconv(.C) noreturn {
    if (!base_revision.is_supported()) arch.halt();

    if (fb_req.response == null) arch.halt();
    // TODO: Make framebuffer optional
    if (fb_req.response) |fb_res| {
        if (fb_res.framebuffer_count < 1) {
            arch.halt();
        }
        log.init(fb_res.framebuffers()[0]);
    }

    _ = getLimineResponse(limine.HhdmResponse, hhdm_req);
    _ = getLimineResponse(limine.KernelFileResponse, krn_file_req);
    const mmap_res = getLimineResponse(limine.MemoryMapResponse, mmap_req);

    pmm.init(mmap_res.entries());

    std.log.info("Hello, World!", .{});
    arch.cpuInit();

    unreachable;
}

const std = @import("std");
const limine = @import("limine");
const log = @import("log.zig");
const arch = @import("arch.zig");
const pmm = @import("mem/pmm.zig");
const debug = @import("debug.zig");
