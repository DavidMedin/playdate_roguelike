const pdapi = @import("playdate.zig");
const ecs = @import("ecs");
const context = @import("context.zig");

// pub const InvGui = struct {
//     visible : bool = false
// };

pub fn draw_inv_gui(ctx: *context.Context) void {
    const playdate = ctx.*.playdate;

    // playdate.graphics.fillRect(0,0,100,240, @intFromEnum(pdapi.LCDSolidColor.ColorWhite));
    playdate.graphics.drawBitmap(ctx.*.inv_img, 0, 0, pdapi.LCDBitmapFlip.BitmapUnflipped);
    // ctx.*.world.
}
