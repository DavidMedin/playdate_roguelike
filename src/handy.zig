// Handy entities are those who can be picked up and manipulated. Like a stick, potion, or sword.
const std = @import("std");
const ecs = @import("ecs");

pub const Handy = struct {
    const Self = @This();
    // sharpness : u32,
    // length : u32,
    damage : u64, // how bad does this hurt?
    // mass : u32,

};