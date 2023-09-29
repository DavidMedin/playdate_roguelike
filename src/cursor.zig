const std = @import("std");
const pdapi = @import("playdate.zig");
const context = @import("context.zig");
const transform = @import("transform.zig");

pub const Cursor = struct {
    const Self = @This();
    position : transform.Vector(i32) = .{.x = 0, .y= 0},
    active : bool = false,
    bitmap : *pdapi.LCDBitmap,
    pub fn draw(self : *Self,ctx : *context.Context) void {
        const map_space = transform.game_to_screen(self.*.position);
        ctx.*.playdate.graphics.drawBitmap(
            self.*.bitmap, 
            map_space.x,
            map_space.y,
            pdapi.LCDBitmapFlip.BitmapUnflipped
        );
    }
};