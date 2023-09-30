const std = @import("std");
const ecs = @import("ecs");
const context = @import("context.zig");
const map = @import("map.zig");

const brain = @import("brain.zig");
const transform = @import("transform.zig");
const breakable = @import("breakable.zig");
const body = @import("body.zig");

// This defines what others percieve you as. Not who you actually are, I think.
// This component should only accompany a body, not a brain!
pub const Relation = struct {
    in: i32, // What group this entity is in. (bit map)
    hates: i32, // What groups this entity hates.
    loves: i32, // What group this entity loves.

    pub const HUMAN = 1 << 0;
    pub const GOBLIN = 1 << 2;
};

// This defines how an AI will behave.
// This component goes on brains.
// Will attempt to attack entities it hates, for now.
pub const AI = struct {
    attack_target: ecs.Entity = null,
};

pub fn move(ctx: *context.Context, me: ecs.Entity, ai: *AI, ent_brain: *brain.Brain) !void {
    if (ent_brain.*.time_till_react != 0) {
        // Too slow!
        return;
    }

    const my_body_entity: ecs.Entity = ent_brain.*.body;
    const relation: *Relation = (ctx.*.world.get_component(my_body_entity, "relation", Relation) catch |err| {
        if (err == ecs.ECSError.OldEntity) {
            try ctx.*.world.queue_kill_entity(me);
            return;
        } else {
            return err;
        }
    }).?;

    // If I don't hate anyone arround, try to find one.
    if (ai.*.attack_target == null) {
        // Find a entity with Relation who I hate.
        var relation_iter = ecs.data_iter(.{ .relation = Relation }).init(&ctx.*.world);
        while (relation_iter.next()) |slice| {
            if (slice.relation.*.in & relation.*.hates != 0) {
                // Wow, I hate this entity.
                ai.*.attack_target = slice.entity;
                break; // out of this while loop.
            }
        }
    }

    if (ai.*.attack_target == null) {
        // I tried to find someone I hate, and I didn't.
        return;
    }

    // I really hate someone around. So much that I want to kill them!
    // Get my position, their position, and find the direction to go to.
    // TODO: Pathfinding.
    var my_body_trans: *transform.Transform = (try ctx.*.world.get_component(my_body_entity, "transform", transform.Transform)).?;
    var your_body_trans: *transform.Transform = (try ctx.*.world.get_component(ai.*.attack_target, "transform", transform.Transform)).?;
    const diff = your_body_trans.*.sub(my_body_trans.*);

    // if the ENEMY is adjacent to me
    if (try std.math.absInt(diff.x) <= 1 and try std.math.absInt(diff.y) <= 1) {
        const damage: u64 = try body.get_item_damage(ctx, my_body_entity);
        try breakable.take_damage(ctx, ai.*.attack_target, damage);
    } else {
        // The ENEMY is not adjacent, I must move in.

        const dir = diff.normalize() catch return; // If normalize errs (vector magnitude was zero) then don't move.
        const new_trans = dir.plus(my_body_trans.*);

        const world_map: *map.Map = &ctx.*.map;
        if (!world_map.*.collides(new_trans)) {
            my_body_trans.* = new_trans;
        }
    }
}
