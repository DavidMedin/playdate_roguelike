const pdapi = @import("playdate_api_definitions.zig");
const ecs = @import("ecs");
const transform = @import("transform.zig");

pub const Dude = struct {
    const Self = @This();
    radius: i32,

    pub fn draw(self: *Self, playdate: *pdapi.PlaydateAPI, trans: *transform.Transform) void {
        playdate.graphics.drawEllipse(trans.*.x, trans.*.y, self.*.radius * 2, self.*.radius * 2, 2, 0, 0, @intFromEnum(pdapi.LCDSolidColor.ColorBlack));
    }
};
