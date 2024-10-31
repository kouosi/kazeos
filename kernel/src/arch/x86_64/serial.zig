var is_init: bool = false;

pub inline fn inb(port: u16) u8 {
    return asm volatile ("inb %[port], %[ret]"
        : [ret] "={al}" (-> u8),
        : [port] "{dx}" (port),
    );
}

pub inline fn outb(port: u16, val: u8) void {
    asm volatile ("outb %[val], %[port]"
        :
        : [val] "{al}" (val),
          [port] "{dx}" (port),
    );
}

pub fn writeByte(value: u8) void {
    while (inb(0x3f8 + 5) & 0x20 == 0) {}
    outb(0x3f8, value);
}

pub const Color = enum(u8) { red, yellow, blue, white, reset, panic };

pub fn getColorCode(color: Color) []const u8 {
    return switch (color) {
        .red => "\x1b[31m",
        .yellow => "\x1b[33m",
        .blue => "\x1b[34m",
        .white => "\x1b[37m",
        .reset => "\x1b[0m",
        .panic => "\x1b[1;37;41m",
    };
}

pub fn write(msg: []const u8, color: Color) void {
    for (getColorCode(color)) |value| writeByte(value);
    defer for (getColorCode(Color.reset)) |value| writeByte(value);

    for (msg) |value| {
        writeByte(value);
    }
}

pub fn print(msg: []const u8) void {
    for (msg) |value| {
        writeByte(value);
    }
}

pub fn init() void {
    if (is_init) return;
    outb(0x3f8 + 1, 0x00);
    outb(0x3f8 + 3, 0x80);
    outb(0x3f8 + 0, 0x03);
    outb(0x3f8 + 1, 0x00);
    outb(0x3f8 + 3, 0x03);
    outb(0x3f8 + 2, 0xC7);
    outb(0x3f8 + 4, 0x0B);
    outb(0x3f8 + 4, 0x1E);
    outb(0x3f8 + 0, 0xAE);
    outb(0x3f8 + 4, 0x0F);
    is_init = true;
}

const std = @import("std");
