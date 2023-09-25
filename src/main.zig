// Author : David Medin
// Email : david@davidmedin.com
// Zig Version : 0.12.0-dev.21+ac95cfe44

const std = @import("std");

const pdapi = @import("playdate.zig");
const ecs = @import("ecs");

// Helpers
const context = @import("context.zig");
const map = @import("map.zig");

// Components
const image = @import("image.zig");
const controls = @import("controls.zig");
const transform = @import("transform.zig");
const brain = @import("brain.zig");
const body = @import("body.zig");

// TODO:
// [x] Draw a map from an ID image
// [x] Collidable walls
// [] Make GUI framework for menus
// [] GUI ECS viewer/editor in and/or out of the playdate. HARD
// [] Inventory menu
// [] Pick up item on floor
// [] collidable chest with items
// [] damage!


// ===============================================================
// Don't use these unless your logFn (you're not).
var GLOBAL_PLAYDATE: ?*pdapi.PlaydateAPI = null;
var GLOBAL_ALLOCATOR: ?std.mem.Allocator = null;

// This is how you can use std.log.* using the Playdate's logToConsole function. If want to use std.debug.print, cry, seeth, cope, commit nix
pub const std_options = struct {
    pub fn logFn(comptime level: std.log.Level, comptime scope: @TypeOf(.EnumLiteral), comptime format: []const u8, args: anytype) void {
        _ = scope;
        const ED = comptime "\x1b[";
        _ = ED;
        const reset = "\x1b[0m";
        _ = reset;

        const prefix = "[" ++ comptime level.asText() ++ "] ";
        const fmtd_string: [:0]u8 = std.fmt.allocPrintZ(GLOBAL_ALLOCATOR.?, prefix ++ format, args) catch unreachable;
        nosuspend GLOBAL_PLAYDATE.?.*.system.logToConsole(@ptrCast(fmtd_string));
        GLOBAL_ALLOCATOR.?.free(fmtd_string);
    }
};
// ===============================================================


fn component_allocator(playdate_api: *pdapi.PlaydateAPI) std.mem.Allocator {
    return std.mem.Allocator{
        .ptr = playdate_api,
        .vtable = &std.mem.Allocator.VTable{
            .alloc = struct {
                pub fn alloc(ctx: *anyopaque, len: usize, ptr_align: u8, ret_addr: usize) ?[*]u8 {
                    // std.log.debug("Alloc : len : {}, ptr_align : {}, red_addr : {}", .{len,ptr_align,ret_addr});
                    GLOBAL_PLAYDATE.?.*.system.logToConsole("Alloc : len : %p, ptr_align : %d, ret_addr : %p\n", len, ptr_align, ret_addr);
                    const playdate: *pdapi.PlaydateAPI = @ptrCast(@alignCast(ctx));
                    // TODO: Don't just throw away the ptr_align thing.
                    return @ptrCast(playdate.system.realloc(null, len));
                }
            }.alloc,
            .resize = struct {
                pub fn resize(ctx: *anyopaque, buf: []u8, buf_align: u8, new_len: usize, ret_addr: usize) bool {
                    _ = ctx;
                    GLOBAL_PLAYDATE.?.*.system.logToConsole("Resize : buff_ptr : %p, buff_len : %d, new_len : %d, ret_addr : %p\n", buf.ptr,buf.len,buf_align,new_len,ret_addr);
                    // const playdate: *pdapi.PlaydateAPI = @ptrCast(@alignCast(ctx)); 
                    // const maybe_new_addr : ?*anyopaque = playdate.system.realloc(buf.ptr, new_len);
                    // if(maybe_new_addr == null) {
                    //     unreachable;
                    // }
                    // const new_addr = maybe_new_addr.?;
                    // if (new_addr == @as(*anyopaque, buf.ptr)) {
                    //     return true;
                    // } else {
                    //     _ = playdate.system.realloc(new_addr, 0);
                    //     return false;
                    // }
                    return false; // Playdate doesn't have a function to *attempt* to resize without moving. It will just allocate it.
                    // So, lets hope that every user of .resize will have a fallback 'free' and 'alloc'.
                }
            }.resize,
            .free = struct {
                pub fn free(ctx: *anyopaque, buf: []u8, buf_align: u8, ret_addr: usize) void {
                    // std.log.debug("Free : buff_ptr : {*}. buff_len : {}, buf_align : {}, ret_addr : {}", .{buf.ptr,buf.len,buf_align,ret_addr});
                    GLOBAL_PLAYDATE.?.*.system.logToConsole("Free : buff_ptr : %p, buff_len : %d, ret_addr : %p\n", buf.ptr,buf.len,buf_align,ret_addr);
                    

                    const playdate: *pdapi.PlaydateAPI = @ptrCast(@alignCast(ctx));
                    _ = playdate.system.realloc(buf.ptr, 0);
                }
            }.free,
        },
    };
}

// var world: ecs.ECS = undefined;
// var world_map : map.Map = undefined;

pub export fn eventHandler(playdate: *pdapi.PlaydateAPI, event: pdapi.PDSystemEvent, arg: u32) callconv(.C) c_int {
    _ = arg;
    switch (event) {
        .EventInit => {
            GLOBAL_PLAYDATE = playdate;
            GLOBAL_ALLOCATOR = component_allocator(playdate);

            const ecs_config = ecs.ECSConfig{ .component_allocator = GLOBAL_ALLOCATOR.? };
            var ctx : *context.Context = GLOBAL_ALLOCATOR.?.create(context.Context) catch unreachable; // allocate a context. This will never be free'd
            ctx.* =  context.Context{
                .playdate = playdate,
                .allocator = component_allocator(playdate),
                .world = ecs.ECS.init(ecs_config) catch unreachable,
                .map = map.Map.init(ctx), // Kinda sus, but does work. As long as map.init does't assume .tileset has been written to...
                .tileset = playdate.graphics.loadBitmapTable("tilemap", null).?
            };
            // g_playdate_image = playdate.graphics.loadBitmap("playdate_image", null).?;
            const font = playdate.graphics.loadFont("/System/Fonts/Asheville-Sans-14-Bold.pft", null).?;
            playdate.graphics.setFont(font);

            init(ctx) catch unreachable;
            
            playdate.system.setUpdateCallback(update, ctx);
        },
        .EventTerminate => {
            // Nothing happens. heh.
        },
        else => {},
    }
    return 0;
}

fn init(ctx : *context.Context) !void {
    const playdate = ctx.*.playdate;
    const world = &ctx.*.world;

    // ECS things
    // const playdate_image = playdate.graphics.loadBitmap("playdate_image", null).?;
    const hero_image = playdate.graphics.getTableBitmap(ctx.*.tileset,4).?; // Index 5 is the person sprite
    const goblin_image = playdate.graphics.getTableBitmap(ctx.*.tileset,5).?; // Index 5 is the person sprite

{    // Brain entity
    const player_brain: ecs.Entity = try world.new_entity();
    try world.add_component(player_brain, "brain", brain.Brain{ .reaction_time = 1, .body = undefined });
    try world.add_component(player_brain, "controls", controls.Controls{ .movement = 0 });
    var brain_component: *brain.Brain = (try world.get_component(player_brain, "brain", brain.Brain)).?;

    // Body entity
    const player_body: ecs.Entity = try world.new_entity();
    brain_component.*.body = player_body; // Linking the body to the brain
    try world.add_component(player_body, "body", body.Body{ .brain = player_brain });

    try world.add_component(player_body, "image", image.Image{ .bitmap = hero_image });
    try world.add_component(player_body, "transform", transform.Transform{ .x = 4, .y = 4 });
}

{    // Brain entity
    const player_brain: ecs.Entity = try world.new_entity();
    try world.add_component(player_brain, "brain", brain.Brain{ .reaction_time = 1, .body = undefined });
    try world.add_component(player_brain, "controls", controls.Controls{ .movement = 0 });
    var brain_component: *brain.Brain = (try world.get_component(player_brain, "brain", brain.Brain)).?;

    // // Body entity
    const player_body: ecs.Entity = try world.new_entity();
    brain_component.*.body = player_body; // Linking the body to the brain
    try world.add_component(player_body, "body", body.Body{ .brain = player_brain });

    try world.add_component(player_body, "image", image.Image{ .bitmap = goblin_image });
    try world.add_component(player_body, "transform", transform.Transform{ .x = 4, .y = 6 });
}
    // world.print_info();
    // Time stuff
    playdate.system.resetElapsedTime();
    tick(ctx) catch unreachable;

    std.log.debug("Finished the init!",.{});
}

var time_leftovers: f32 = 0;
fn update(userdata: ?*anyopaque) callconv(.C) c_int {
    const ctx: *context.Context = @ptrCast(@alignCast(userdata.?));
    const playdate = ctx.*.playdate;
    const world = &ctx.*.world;


    const tick_length: f32 = 0.25; // In seconds (microsecond accuracy)
    const time: f32 = playdate.system.getElapsedTime();
    if (time + time_leftovers >= tick_length) {
        time_leftovers = time + time_leftovers - tick_length;
        if (time_leftovers >= tick_length) {
            std.log.warn("Dropping frames! {} leftover seconds, {} dropped frames.", .{ time_leftovers, std.math.floor(time_leftovers / tick_length) });
        }
        playdate.system.resetElapsedTime();
        // std.log.debug("Tick! ({})", .{time_leftovers});
        tick(ctx) catch unreachable;
    }

    // Iterate through all 'Controllable's.
    var move_iter = ecs.data_iter(.{ .controls = controls.Controls }).init(world);
    while (move_iter.next()) |slice| {
        controls.update_controls(playdate, slice.controls);
    }

    // Drawing
    ctx.*.playdate.graphics.clear(@intFromEnum(pdapi.LCDSolidColor.ColorWhite));

    ctx.*.map.draw();
    // Iterate through all images and draw them
    var image_iter = ecs.data_iter(.{ .image = image.Image, .transform = transform.Transform }).init(&ctx.*.world);
    while (image_iter.next()) |slice| {
        std.debug.assert(slice.entity != null);
        slice.image.draw(ctx, .{ .x = slice.transform.*.x, .y = slice.transform.*.y });
    }

    // returning 1 signals to the OS to draw the frame.
    // we always want this frame drawn
    return 1;
}

fn tick(ctx: *context.Context) !void {
    // const to_draw = "Hello from Zig!";


    var move_iter = ecs.data_iter(.{ .controls = controls.Controls, .brain = brain.Brain }).init(&ctx.*.world);
    while (move_iter.next()) |slice| {
        controls.update_movement(&ctx.*.world, ctx, slice.controls, slice.brain);
    }


}
