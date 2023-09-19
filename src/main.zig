// Author : David Medin
// Email : david@davidmedin.com
// Zig Version : 0.12.0-dev.21+ac95cfe44

const std = @import("std");

const pdapi = @import("playdate_api_definitions.zig");
const ecs = @import("ecs");

const image = @import("image.zig");
const controls = @import("controls.zig");
const transform = @import("transform.zig");
const brain = @import("brain.zig");
const body = @import("body.zig");

// TODO:
// [] Draw a map from an ID image
// [] Collidable walls
// [] Make GUI framework for menus
// [] GUI ECS viewer/editor in and/or out of the playdate. HARD
// [] Inventory menu
// [] Pick up item on floor
// [] collidable chest with items
// [] damage!

var global_playdate: ?*pdapi.PlaydateAPI = null;

fn component_allocator(playdate_api: *pdapi.PlaydateAPI) std.mem.Allocator {
    return std.mem.Allocator{
        .ptr = playdate_api,
        .vtable = &std.mem.Allocator.VTable{
            .alloc = struct {
                pub fn alloc(ctx: *anyopaque, len: usize, ptr_align: u8, _: usize) ?[*]u8 {
                    const playdate: *pdapi.PlaydateAPI = @ptrCast(@alignCast(ctx));
                    _ = ptr_align;
                    // TODO: Don't just throw away the ptr_align thing.
                    return @ptrCast(playdate.system.realloc(null, len));
                }
            }.alloc,
            .resize = struct {
                pub fn resize(ctx: *anyopaque, buf: []u8, buf_align: u8, new_len: usize, _: usize) bool {
                    const playdate: *pdapi.PlaydateAPI = @ptrCast(@alignCast(ctx));
                    _ = buf_align;
                    const new_addr = playdate.system.realloc(buf.ptr, new_len) orelse return false;
                    if (new_addr == @as(*anyopaque, buf.ptr)) {
                        return true;
                    } else {
                        _ = playdate.system.realloc(new_addr, 0);
                        return false;
                    }
                }
            }.resize,
            .free = struct {
                pub fn free(ctx: *anyopaque, buf: []u8, buf_align: u8, _: usize) void {
                    const playdate: *pdapi.PlaydateAPI = @ptrCast(@alignCast(ctx));
                    _ = buf_align;
                    _ = playdate.system.realloc(buf.ptr, 0);
                }
            }.free,
        },
    };
}
var playdate_allocator: ?std.mem.Allocator = null;

// This is how you can use std.log.* using the Playdate's logToConsole function. If want to use std.debug.print, cry, seeth, cope, commit nix
pub const std_options = struct {
    pub fn logFn(comptime level: std.log.Level, comptime scope: @TypeOf(.EnumLiteral), comptime format: []const u8, args: anytype) void {
        _ = scope;
        const ED = comptime "\x1b[";
        _ = ED;
        const reset = "\x1b[0m";
        _ = reset;

        const prefix = "[" ++ comptime level.asText() ++ "] ";
        const fmtd_string: [:0]u8 = std.fmt.allocPrintZ(playdate_allocator.?, prefix ++ format, args) catch unreachable;
        nosuspend global_playdate.?.*.system.logToConsole(@ptrCast(fmtd_string));
        playdate_allocator.?.free(fmtd_string);
    }
};

var world: ecs.ECS = undefined;

pub export fn eventHandler(playdate: *pdapi.PlaydateAPI, event: pdapi.PDSystemEvent, arg: u32) callconv(.C) c_int {
    _ = arg;
    switch (event) {
        .EventInit => {
            global_playdate = playdate;
            playdate_allocator = component_allocator(playdate);
            // g_playdate_image = playdate.graphics.loadBitmap("playdate_image", null).?;
            const font = playdate.graphics.loadFont("/System/Fonts/Asheville-Sans-14-Bold.pft", null).?;
            playdate.graphics.setFont(font);

            const ecs_config = ecs.ECSConfig{ .component_allocator = playdate_allocator.? };
            world = ecs.ECS.init(ecs_config) catch unreachable;
            init_ecs(playdate) catch unreachable;
            playdate.system.setUpdateCallback(update_and_render, playdate);
            playdate.system.resetElapsedTime();
            tick(playdate) catch unreachable;
        },
        else => {},
    }
    return 0;
}

fn init_ecs(playdate: *pdapi.PlaydateAPI) !void {
    const playdate_image = playdate.graphics.loadBitmap("playdate_image", null).?;

    // Brain entity
    const player_brain: ecs.Entity = try world.new_entity();
    try world.add_component(player_brain, "brain", brain.Brain{ .reaction_time = 1, .body = undefined });
    try world.add_component(player_brain, "controls", controls.Controls{ .movement = 0 });
    var brain_component: *brain.Brain = (try world.get_component(player_brain, "brain", brain.Brain)).?;

    // Body entity
    const player_body: ecs.Entity = try world.new_entity();
    brain_component.*.body = player_body; // Linking the body to the brain
    try world.add_component(player_body, "body", body.Body{ .brain = player_brain });

    try world.add_component(player_body, "image", image.Image{ .bitmap = playdate_image });
    try world.add_component(player_body, "transform", transform.Transform{ .x = 4, .y = 4 });
}

var time_leftovers: f32 = 0;
fn update_and_render(userdata: ?*anyopaque) callconv(.C) c_int {
    const playdate: *pdapi.PlaydateAPI = @ptrCast(@alignCast(userdata.?));

    const tick_length: f32 = 0.25; // In seconds (microsecond accuracy)
    const time: f32 = playdate.system.getElapsedTime();
    if (time + time_leftovers >= tick_length) {
        time_leftovers = time + time_leftovers - tick_length;
        if (time_leftovers >= tick_length) {
            std.log.warn("Dropping frames! {} leftover seconds, {} dropped frames.", .{ time_leftovers, std.math.floor(time_leftovers / tick_length) });
        }
        playdate.system.resetElapsedTime();
        std.log.debug("Tick! ({})", .{time_leftovers});
        tick(playdate) catch unreachable;
    }

    // Iterate through all 'Controllable's.
    var move_iter = ecs.data_iter(.{ .controls = controls.Controls }).init(&world);
    while (move_iter.next()) |slice| {
        controls.update_controls(playdate, slice.controls);
    }

    // returning 1 signals to the OS to draw the frame.
    // we always want this frame drawn
    return 1;
}

fn tick(playdate: *pdapi.PlaydateAPI) !void {
    const to_draw = "Hello from Zig!";

    playdate.graphics.clear(@intFromEnum(pdapi.LCDSolidColor.ColorWhite));
    const pixel_width = playdate.graphics.drawText(to_draw, to_draw.len, .UTF8Encoding, 0, 0);
    _ = pixel_width;

    var move_iter = ecs.data_iter(.{ .controls = controls.Controls, .brain = brain.Brain }).init(&world);
    while (move_iter.next()) |slice| {
        controls.update_movement(&world, slice.controls, slice.brain);
    }
    // world.print_info();

    // Iterate through all images and draw them
    var image_iter = ecs.data_iter(.{ .image = image.Image, .transform = transform.Transform }).init(&world);
    while (image_iter.next()) |slice| {
        std.debug.assert(slice.entity != null);
        slice.image.draw(playdate, .{ .x = slice.transform.*.x, .y = slice.transform.*.y });
    }
}
