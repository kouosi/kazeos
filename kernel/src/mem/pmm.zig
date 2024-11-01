var bitmap: []u1 = undefined;

const free_page = 0;
const used_page = 1;

inline fn markPageUsed(paddr: usize) void {
    const index = paddr / std.mem.page_size;
    if (bitmap[index] == free_page) {
        bitmap[index] = used_page;
    }
}

inline fn markPagesUsed(paddr: usize, page_count: usize) void {
    for (0..page_count) |i| {
        markPageUsed(paddr + std.mem.page_size * i);
    }
}

inline fn markPageFree(paddr: usize) void {
    const index = paddr / std.mem.page_size;
    if (bitmap[index] == used_page) {
        bitmap[index] = free_page;
    }
}

inline fn markPagesFree(paddr: usize, page_count: usize) void {
    for (0..page_count) |i| {
        markPageFree(paddr + std.mem.page_size * i);
    }
}

inline fn earlyAlloc(mmap_info: []*limine.MemoryMapEntry, size: usize) usize {
    for (mmap_info) |entry| {
        if (entry.kind == .usable and entry.length >= size) {
            std.log.debug("Found bitmap memory at 0x{x}", .{vmm.getVaddr(entry.base)});
            return vmm.getVaddr(entry.base);
        }
    }
    @panic("Out of memory");
}

inline fn getTotalPages(mmap_info: []*limine.MemoryMapEntry) usize {
    var total_pages: usize = 0;
    for (mmap_info) |entry| {
        total_pages += entry.length;
    }
    return (total_pages / std.mem.page_size) + std.mem.page_size * 2;
}

pub fn isPageFree(paddr: usize) bool {
    const index = paddr / std.mem.page_size;
    if (index >= bitmap.len) return false;
    if (bitmap[index] == free_page) true else false;
}

pub fn allocatePage() usize {
    for (bitmap, 0..) |page, i| {
        if (page == free_page) {
            const addr = i * std.mem.page_size;
            markPageUsed(addr);
            return addr;
        }
    }
    return 0;
}

pub fn freePage(phy_addr: usize) void {
    markPageFree(phy_addr);
}

pub fn allocatePages(page_count: usize) usize {
    if (page_count == 0) {
        return 0;
    } else if (page_count == 1) {
        return allocatePage();
    }

    var i: usize = 0;
    out: while (i < bitmap.len) : (i += 1) {
        if (bitmap[i] == used_page) continue;
        for (0..page_count) |j| {
            if (bitmap[i + j] == used_page) {
                i += j + 1;
                continue :out;
            }
        }
        const addr = i * std.mem.page_size;
        markPagesUsed(addr, page_count);
        return addr;
    }
    return 0;
}

pub fn freePages(base_addr: usize, page_count: usize) void {
    if (page_count == 0) {
        return;
    } else if (page_count == 0) {
        freePage(base_addr);
    }
    markPagesFree(base_addr, page_count);
}

pub fn init(mmap_info: []*limine.MemoryMapEntry) void {
    const total_pages = getTotalPages(mmap_info);
    bitmap.len = total_pages;
    bitmap.ptr = @ptrFromInt(earlyAlloc(mmap_info, total_pages));

    @memset(bitmap, used_page);

    for (mmap_info) |entry| {
        const entry_page_size = entry.length / std.mem.page_size;
        switch (entry.kind) {
            .usable => markPagesFree(entry.base, entry.length / entry_page_size),
            else => {},
        }
    }
    std.log.info("PMM initialised", .{});
}

const std = @import("std");
const limine = @import("limine");
const vmm = @import("vmm.zig");
