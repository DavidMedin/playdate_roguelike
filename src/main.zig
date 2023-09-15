const std = @import("std");
const ecs = @import("ecs");
const pdapi = @import("playdate_api_definitions.zig");

const image = @import("image.zig");
const controls = @import("controls.zig");
const transform = @import("transform.zig");

// fn component_allocator(playdate_api: *pdapi.PlaydateAPI) std.mem.Allocator {
//     return std.mem.Allocator{
//         .ptr = playdate_api,
//         .vtable = &std.mem.Allocator.VTable{
//             .alloc = struct {
//                 pub fn alloc(ctx: *anyopaque, len: usize, ptr_align: u8, _: usize) ?[*]u8 {
//                     const playdate: *pdapi.PlaydateAPI = @ptrCast(@alignCast(ctx));
//                     _ = ptr_align;
//                     // TODO: Don't just throw away the ptr_align thing.
//                     return @ptrCast(playdate.system.realloc(null, len));
//                 }
//             }.alloc,
//             .resize = struct {
//                 pub fn resize(ctx: *anyopaque, buf: []u8, buf_align: u8, new_len: usize, _: usize) bool {
//                     const playdate: *pdapi.PlaydateAPI = @ptrCast(@alignCast(ctx));
//                     _ = buf_align;
//                     const new_addr = playdate.system.realloc(buf.ptr, new_len) orelse return false;
//                     if (new_addr == @as(*anyopaque, buf.ptr)) {
//                         return true;
//                     } else {
//                         _ = playdate.system.realloc(new_addr, 0);
//                         return false;
//                     }
//                 }
//             }.resize,
//             .free = struct {
//                 pub fn free(ctx: *anyopaque, buf: []u8, buf_align: u8, _: usize) void {
//                     const playdate: *pdapi.PlaydateAPI = @ptrCast(@alignCast(ctx));
//                     _ = buf_align;
//                     _ = playdate.system.realloc(buf.ptr, 0);
//                 }
//             }.free,
//         },
//     };
// }

// var g_playdate_image: *pdapi.LCDBitmap = undefined;
var world: ecs.ECS = undefined;

pub export fn eventHandler(playdate: *pdapi.PlaydateAPI, event: pdapi.PDSystemEvent, arg: u32) callconv(.C) c_int {
    _ = arg;
    switch (event) {
        .EventInit => {
            // g_playdate_image = playdate.graphics.loadBitmap("playdate_image", null).?;
            // const font = playdate.graphics.loadFont("/System/Fonts/Asheville-Sans-14-Bold.pft", null).?;
            // playdate.graphics.setFont(font);

            // world = ecs.ECS.init(component_allocator(playdate)) catch unreachable;
            // init_ecs(playdate) catch unreachable;
            playdate.system.setUpdateCallback(update_and_render, playdate);
        },
        else => {},
    }
    return 0;
}

// fn init_ecs(playdate: *pdapi.PlaydateAPI) !void {
//     const playdate_icon = try world.new_entity();
//     const playdate_image = playdate.graphics.loadBitmap("playdate_image", null).?;
//     try world.add_component(playdate_icon, "image", image.Image{ .bitmap = playdate_image });
//     try world.add_component(playdate_icon, "transform", transform.Transform{ .x = pdapi.LCD_COLUMNS / 2 - 16, .y = pdapi.LCD_ROWS / 2 - 16 });
//     try world.add_component(playdate_icon, "controls", controls.Controls{ .dummy_data = 3 });
// }

fn update_and_render(userdata: ?*anyopaque) callconv(.C) c_int {
    const playdate: *pdapi.PlaydateAPI = @ptrCast(@alignCast(userdata.?));
    // const to_draw = "Hello from Zig!";

    // playdate.graphics.clear(@intFromEnum(pdapi.LCDSolidColor.ColorWhite));
    // const pixel_width = playdate.graphics.drawText(to_draw, to_draw.len, .UTF8Encoding, 0, 0);
    const current: pdapi.PDButtons = 0;
    const current_ptr: *pdapi.PDButtons = @constCast(&current);
    playdate.system.getButtonState(null, current_ptr, null);

    // Iterate through all 'Controllable's.
    // var move_iter = ecs.data_iter(.{ .controls = controls.Controls, .transform = transform.Transform }).init(&world);
    // _ = move_iter;
    // while (move_iter.next()) |slice| {
    //     _ = slice;
    //     // controls.update_controls(playdate, slice.transform);
    // }

    // // Iterate through all images and draw them
    // var image_iter = ecs.data_iter(.{ .image = image.Image, .transform = transform.Transform }).init(&world);
    // while (image_iter.next()) |slice| {
    //     slice.image.draw(playdate, slice.transform.*.x, slice.transform.*.y);
    // }

    //returning 1 signals to the OS to draw the frame.
    //we always want this frame drawn
    return 1;
}
