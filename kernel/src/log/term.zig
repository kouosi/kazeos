var framebuffer: *limine.Framebuffer = undefined;
const bg_color = 0x222222;
var cursor_x: usize = 0;
var cursor_y: usize = 0;

inline fn putPixel(x: usize, y: usize, pixel: u32) void {
    @as(*u32, @ptrFromInt(@intFromPtr(framebuffer.address) + framebuffer.pitch * y + 4 * x)).* = pixel;
}

fn writeChar(x: usize, y: usize, val: u8, color: u32) void {
    const pos_x = 1 + x * font.width;
    const pos_y = y * font.height;

    const glyph = font.data[val - 32];
    for (0..font.height) |i| {
        for (0..font.width) |j| {
            const is_pixel = glyph[i] & (@as(u64, 1) << @truncate(font.mask - j)) != 0;
            putPixel(pos_x + j, pos_y + i, if (is_pixel) color else bg_color);
        }
    }
}

pub fn print(msg: []const u8) void {
    write(msg, 0xffffff);
}

pub fn write(msg: []const u8, color: u32) void {
    const max_width = framebuffer.width / font.width;
    const max_height = framebuffer.height / font.height;

    for (msg) |ch| {
        switch (ch) {
            '\n' => {
                cursor_x = 0;
                cursor_y += 1;
                if (cursor_y >= max_height) {
                    scroll();
                }
            },
            else => {
                if (cursor_x >= max_width) {
                    cursor_x = 0;
                    cursor_y += 1;
                    if (cursor_y >= max_height) {
                        scroll();
                    }
                }
                writeChar(cursor_x, cursor_y, ch, color);
                cursor_x += 1;
            },
        }
    }
}

// FIXME: This is fucking slow
fn scroll() void {
    const max_height = framebuffer.height / font.height;
    const max_addr = framebuffer.width * font.height * max_height;
    const discard_addr = framebuffer.width * font.height;
    const fb_base = @as([*]u32, @ptrCast(@alignCast(framebuffer.address)));

    for (0..max_addr) |i| {
        fb_base[i] = fb_base[i + discard_addr];
    }

    for (max_addr - discard_addr..max_addr + discard_addr) |i| {
        fb_base[i] = bg_color;
    }
    cursor_y -= 1;
}

fn clearScreen(color: u32) void {
    const fb = @as([*]u32, @ptrCast(@alignCast(framebuffer.address)));
    const fb_size = framebuffer.width * framebuffer.height;
    @memset(fb[0..fb_size], color);
}

pub fn init(fb: *limine.Framebuffer) void {
    framebuffer = fb;
    clearScreen(bg_color);
    cursor_x = 0;
    cursor_y = 0;
}

pub fn setPanic() void {
    @setCold(true);
    const fb = @as([*]u64, @ptrCast(@alignCast(framebuffer.address)));
    const fb_size = (framebuffer.width * framebuffer.height) / 2;
    for (fb[0..fb_size]) |*value| value.* |= 0x0088000000880000;
}

const std = @import("std");
const font = @import("font.zig");
const limine = @import("limine");
