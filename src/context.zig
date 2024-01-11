const std = @import("std");
const pdapi = @import("playdate.zig");

const ecs = @import("ecs");
const map = @import("map.zig");
const cursor = @import("cursor.zig");

pub const Context = struct {
    playdate: *pdapi.PlaydateAPI,
    allocator: std.mem.Allocator,

    world: ecs.ECS,
    map: map.Map,
    tileset: *pdapi.LCDBitmapTable,
    cursor: cursor.Cursor,
    inv_img: *pdapi.LCDBitmap,

    game_paused: bool = false, // Is *everything* paused?
    tick_paused: bool = false, // Is time paused (not your cursor for aiming).
    //       Is paused when game_paused is true

    world_frame: *pdapi.LCDBitmap,

    player_entity: ecs.Entity = null,
};
