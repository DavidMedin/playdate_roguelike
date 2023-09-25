const ecs = @import("ecs");
const pdapi = @import("playdate.zig");

const context = @import("context.zig");

const transform = @import("transform.zig");

const BLOCK_SIZE = 16;
const BLOCK_COUNT = transform.Vector{ .x = pdapi.LCD_COLUMNS / BLOCK_SIZE, .y = pdapi.LCD_ROWS / BLOCK_SIZE }; // (24, 15)

pub fn world_to_screen(vector: transform.Vector(i32)) transform.Vector(i32) {
    return .{ .x = vector.x * BLOCK_SIZE, .y = vector.y * BLOCK_SIZE };
}

pub const Image = struct {
    const Self = @This();
    bitmap: *pdapi.LCDBitmap,
    pub fn draw(self: *Self,ctx : *context.Context, vector: transform.Vector(i32)) void {
        const screen_vector = world_to_screen(vector);
        ctx.*.playdate.graphics.drawBitmap(self.*.bitmap, screen_vector.x, screen_vector.y, .BitmapUnflipped);
    }
};
