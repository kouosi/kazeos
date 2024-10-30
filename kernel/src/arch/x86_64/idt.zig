const max_idt_entries = 255;
var idt_entries: [max_idt_entries]IdtEntry = undefined;

const IdtDesc = packed struct {
    size: u16,
    offset: u64,

    pub fn load(self: IdtDesc) void {
        asm volatile ("lidt (%[idtr])"
            :
            : [idtr] "r" (&self),
            : "memory"
        );
    }
};

const IntFrame = packed struct {
    r15: u64,
    r14: u64,
    r13: u64,
    r12: u64,
    r11: u64,
    r10: u64,
    r9: u64,
    r8: u64,

    rsi: u64,
    rdi: u64,
    rbp: u64,
    rdx: u64,
    rcx: u64,
    rbx: u64,
    rax: u64,

    vec: u64,
    err: u64,

    rip: u64,
    cs: u64,
    flags: u64,
    rsp: u64,
    ss: u64,

    pub fn dump(self: IntFrame) void {
        std.log.err("rax: 0x{x:0>16}, rbx: 0x{x:0>16}, rcx: 0x{x:0>16}", .{ self.rax, self.rbx, self.rcx });
        std.log.err("rdx: 0x{x:0>16}, rdp: 0x{x:0>16}, rdi: 0x{x:0>16}", .{ self.rdx, self.rbp, self.rdi });
        std.log.err("rsi: 0x{x:0>16}, r8:  0x{x:0>16}, r9:  0x{x:0>16}", .{ self.rsi, self.r8, self.r9 });
        std.log.err("r10: 0x{x:0>16}, r11: 0x{x:0>16}, r12: 0x{x:0>16}", .{ self.r10, self.r11, self.r12 });
        std.log.err("r13: 0x{x:0>16}, r14: 0x{x:0>16}, r15: 0x{x:0>16}", .{ self.r13, self.r14, self.r15 });
        std.log.err("ss:  0x{x:0>16}, rsp: 0x{x:0>16}, rip: 0x{x:0>16}", .{ self.ss, self.rsp, self.rip });
        std.log.err("cs:  0x{x:0>16}, flags: 0x{x:0>16}, EC: 0x{x:0>16}", .{ self.cs, self.flags, self.err });
    }
};

const IntHandler = *const fn (frame: *IntFrame) callconv(.C) void;
const RawIntHandler = *const fn () callconv(.Naked) void;

const IdtEntry = packed struct {
    offset_low: u16,
    selector: u16,
    ist: u3 = 0,
    reserved_low: u5 = 0,
    gate_type: GateType,
    reserved_mid: u1 = 0,
    dpl: u2,
    present: u1,
    offset_high: u48,
    reserved_high: u32 = 0,

    const GateType = enum(u4) {
        int_gate = 0b1110,
        trap_gate = 0b1111,
    };

    pub fn install(
        self: *IdtEntry,
        intHandlerFn: RawIntHandler,
        selector: u16,
        gate_type: GateType,
        is_present: bool,
        is_userspace: bool,
    ) void {
        const fn_addr = @intFromPtr(intHandlerFn);
        self.* = @as(IdtEntry, .{
            .offset_low = @truncate(fn_addr),
            .selector = selector,
            .gate_type = gate_type,
            .dpl = if (is_userspace) 1 else 0,
            .present = if (is_present) 1 else 0,
            .offset_high = @truncate(fn_addr >> 16),
        });
    }
};

const IntExcep = packed struct {
    const exception_names = [_][]const u8{
        "Divide by Zero Exception",
        "Debug Exception",
        "NMI Interrupt",
        "Breakpoint Exception",
        "Overflow Exception",
        "Bound Range Exceeded",
        "Invalid Opcode Exception",
        "Device Not Available Exception",
        "Double Fault Exception",
        "Coprocessor Segment Overrun",
        "Invalid TSS Exception",
        "Segment Not Present Exception",
        "Stack Fault Exception",
        "General Protection Fault",
        "Page Fault Exception",
        "Reserved Exception 15",
        "Floating Point Error",
        "Alignment Check Exception",
        "Machine-Check Exception",
        "SIMD Floating-Point Exception",
        "Virtualization Exception",
        "Control Protection Exception",
        "Reserved Exception 22",
        "Reserved Exception 23",
        "Reserved Exception 24",
        "Reserved Exception 25",
        "Reserved Exception 26",
        "Reserved Exception 27",
        "Hypervisor Injection Exception",
        "VMM Communication Exception",
        "Security Exception",
        "Reserved Exception 31",
    };

    pub fn getExcepName(int_vec: u64) []const u8 {
        return switch (int_vec) {
            0...31 => exception_names[int_vec],
            else => "Not Exception",
        };
    }

    pub fn handleExcep(frame: *IntFrame) callconv(.C) void {
        std.log.err("Exception: {}, {s} ", .{ frame.vec, getExcepName(frame.vec) });
        frame.dump();
        @panic("Unhandled Exception");
    }
};

fn genIntHandler(comptime int_vec: u8, comptime intFn: IntHandler) RawIntHandler {
    return struct {
        fn defaultHandler() callconv(.Naked) void {
            switch (int_vec) {
                8, 10...14, 17, 21, 29, 30 => {},
                else => asm volatile ("push $0"),
            }

            asm volatile ("push %[vec]"
                :
                : [vec] "i" (int_vec),
            );

            asm volatile (
                \\ pushq %rax
                \\ pushq %rbx
                \\ pushq %rcx
                \\ pushq %rdx
                \\ pushq %rbp
                \\ pushq %rdi
                \\ pushq %rsi
                \\ pushq %r8
                \\ pushq %r9
                \\ pushq %r10
                \\ pushq %r11
                \\ pushq %r12
                \\ pushq %r13
                \\ pushq %r14
                \\ pushq %r15
                \\ movq %rsp, %rdi
                \\ cld
            );

            asm volatile (
                \\ movq %[intFn], %rbx
                \\ call *%rbx
                :
                : [intFn] "r" (@intFromPtr(intFn)),
            );

            asm volatile (
                \\ popq %r15
                \\ popq %r14
                \\ popq %r13
                \\ popq %r12
                \\ popq %r11
                \\ popq %r10
                \\ popq %r9
                \\ popq %r8
                \\ popq %rsi
                \\ popq %rdi
                \\ popq %rbp
                \\ popq %rdx
                \\ popq %rcx
                \\ popq %rbx
                \\ popq %rax
                \\ add $16, %rsp
                \\ iretq
            );
        }
    }.defaultHandler;
}

pub fn init() void {
    const kernel_code_segment = asm volatile (
        \\ mov %%cs, %[cs]
        : [cs] "=r" (-> u16),
    );

    const idtr: IdtDesc = .{
        .size = @sizeOf(IdtEntry) * idt_entries.len - 1,
        .offset = @intFromPtr(&idt_entries),
    };

    inline for (0..32) |i| {
        idt_entries[i].install(
            genIntHandler(@truncate(i), IntExcep.handleExcep),
            kernel_code_segment,
            .trap_gate,
            true,
            false,
        );
    }

    idtr.load();
    std.log.info("IDT initialised", .{});
}

const std = @import("std");
