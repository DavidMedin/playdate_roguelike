// Handy entities are those who can be picked up and manipulated. Like a stick, potion, or sword.
const std = @import("std");
const ecs = @import("ecs");
const context = @import("context.zig");

pub fn hit(ctx : *context.Context, user : ecs.Entity, item : ecs.Entity, item_handy : *Handy) anyerror!bool {
    _ = item_handy;
    _ = item;
    _ = user;
    _ = ctx;
    
}

pub const Handy = struct {
    const Self = @This();
    // sharpness : u32,
    // length : u32,
    damage : u64, // how bad does this hurt?
    // mass : u32,

    //                                     user         item                        done?
    use_fn : *const fn (*context.Context, ecs.Entity, ecs.Entity, *Handy) anyerror!bool
};