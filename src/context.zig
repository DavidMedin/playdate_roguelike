const std = @import("std");
const pdapi = @import("playdate.zig");

const ecs = @import("ecs");
const map = @import("map.zig");

pub const Context = struct {
    playdate : *pdapi.PlaydateAPI,
    allocator : std.mem.Allocator,

    world : ecs.ECS,
    map : map.Map,
    tileset : *pdapi.LCDBitmapTable
};