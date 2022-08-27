const std = @import("std");

const Buffer = @import("../main.zig").Buffer;

pub const Rect = struct {
    // origin x
    row: usize = 0,
    // origin y
    col: usize = 0,
    // width
    w: usize = 0,
    // height
    h: usize = 0,
};

const Widget = @This();

ptr: *anyopaque,
drawFn: fn (*anyopaque, *Buffer) void,
rectFn: fn (*anyopaque) *Rect,

pub fn make(ptr: anytype) Widget {
    const Ptr = @TypeOf(ptr);
    const ptr_info = @typeInfo(Ptr);

    std.debug.assert(ptr_info == .Pointer); // Must be a pointer
    std.debug.assert(ptr_info.Pointer.size == .One); // Must be a single-item pointer

    const alignment = ptr_info.Pointer.alignment;

    const gen = struct {
        pub fn drawImpl(pointer: *anyopaque, buffer: *Buffer) void {
            const self = @ptrCast(Ptr, @alignCast(alignment, pointer));

            return @call(.{ .modifier = .always_inline }, ptr_info.Pointer.child.draw, .{ self, buffer });
        }

        pub fn rectImpl(pointer: *anyopaque) *Rect {
            const self = @ptrCast(Ptr, @alignCast(alignment, pointer));

            return @call(.{ .modifier = .always_inline }, ptr_info.Pointer.child._rect, .{self});
        }
    };

    return .{
        .ptr = ptr,
        .drawFn = gen.drawImpl,
        .rectFn = gen.rectImpl,
    };
}

pub fn draw(widget: Widget, buffer: *Buffer) void {
    widget.drawFn(widget.ptr, buffer);
}

pub fn rect(widget: Widget) *Rect {
    return widget.rectFn(widget.ptr);
}

test "refAllDecls" {
    std.testing.refAllDecls(Widget);
}
