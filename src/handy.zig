// Handy entities are those who can be picked up and manipulated. Like a stick, potion, or sword.
const std = @import("std");
const ecs = @import("ecs");

const context = @import("context.zig");
const map = @import("map.zig");

const breakable = @import("breakable.zig");

pub fn hit(ctx: *context.Context, user: ecs.Entity, item: ecs.Entity, item_handy: *Handy) anyerror!void {
    _ = item;
    // const world = &ctx.*.world;
    // _ = world;
    // Is there an entity chillin' at this spot?

    if (try map.get_entities_here(ctx, ctx.*.cursor.position)) |entities_there| {
        defer entities_there.deinit(); // Delete the allocated stuff there.
        // There can be multiple entities in one place. So, pick up the first valid item. Not me though. No self-picking-up.
        for (entities_there.items) |entity| {
            if (std.meta.eql(user, entity)) {
                // Don't pick up yourself.
                continue;
            }
            // This garbage attacks. If it errors, ignore it if the entity simple doesn't have the component. Halt and Catch Fire otherwise.
        breakable.take_damage(ctx, entity, item_handy.*.damage) catch |err| switch (err) {
            ecs.ECSError.EntityDoesNotHaveComponent => {},
            else => return err,
        };
            break;
        }
    }
}

pub const Handy = struct {
    const Self = @This();
    // sharpness : u32,
    // length : u32,
    damage: u64, // how bad does this hurt?
    // mass : u32,

    //                                      user         item
    // use_fn: *const fn (*context.Context, ecs.Entity, ecs.Entity, *Handy) anyerror!void = hit, // Might be a hashmap of Action Name (string) -> func
};
