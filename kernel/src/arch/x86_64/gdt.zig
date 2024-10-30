var gdt_entries: [5]GdtEntry = undefined;

const GdtDesc = packed struct {
    size: u16,
    offset: u64,

    pub fn load(self: GdtDesc) void {
        asm volatile (
            \\ lgdt (%[gdtr])
            :
            : [gdtr] "r" (&self),
            : "memory"
        );

        asm volatile (
            \\ push $0x08
            \\ lea .reloadGdt(%rip), %rax
            \\ push %rax
            \\ lretq
            \\.reloadGdt:
            \\ mov $0x10, %eax
            \\ mov %eax, %ds
            \\ mov %eax, %es
            \\ mov %eax, %fs
            \\ mov %eax, %gs
            \\ mov %eax, %ss
            ::: "rax");
    }
};

const GdtEntry = packed struct {
    limit_low: u16,
    base_low: u24,
    access_byte: u8,
    limit_high: u4,
    flags: u4,
    base_high: u8,

    pub fn new(base: u32, limit: u20, access_byte: u8, flags: u4) GdtEntry {
        return @as(GdtEntry, .{
            .limit_low = @truncate(limit),
            .base_low = @truncate(base),
            .access_byte = access_byte,
            .limit_high = @truncate(limit >> 16),
            .flags = flags,
            .base_high = @truncate(base >> 24),
        });
    }
    pub fn getDefault() [5]GdtEntry {
        return .{
            GdtEntry.new(0, 0x00000, 0x00, 0x0), // null desc
            GdtEntry.new(0, 0xfffff, 0x9a, 0xa), // kernel code desc
            GdtEntry.new(0, 0xfffff, 0x92, 0xc), // kernel data desc
            GdtEntry.new(0, 0xfffff, 0xfa, 0xa), // user code desc
            GdtEntry.new(0, 0xfffff, 0xf2, 0xc), // user data desc
        };
    }
};

// TODO: Implement Gdt tss
const GdtTssEntry = packed struct {
    limit_low: u16,
    base_low: u24,
    access_byte: u8,
    limit_high: u4,
    flags: u4,
    base_high: u40,
    reserved: u32 = 0,
};

pub fn init() void {
    gdt_entries = GdtEntry.getDefault();
    const gdtr: GdtDesc = .{
        .size = @sizeOf(GdtEntry) * gdt_entries.len - 1,
        .offset = @intFromPtr(&gdt_entries),
    };
    gdtr.load();
    std.log.info("GDT initialised", .{});
}

const std = @import("std");
