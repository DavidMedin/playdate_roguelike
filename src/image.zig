const ecs = @import("ecs");
const pdapi = @import("playdate_api_definitions.zig");

pub const Image = struct {
    const Self = @This();
    bitmap: *pdapi.LCDBitmap,
    pub fn draw(self: *Self, playdate: *pdapi.PlaydateAPI, x: i32, y: i32) void {
        playdate.graphics.drawBitmap(self.*.bitmap, x, y, .BitmapUnflipped);
    }
};
