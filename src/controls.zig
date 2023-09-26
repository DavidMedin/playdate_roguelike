const std = @import("std");
const ecs = @import("ecs");
const pdapi = @import("playdate.zig");
const context = @import("context.zig");

const transform = @import("transform.zig");
const brain = @import("brain.zig");
const breakable = @import("breakable.zig");

pub const Controls = struct {
    const Self = @This();
    pressed_this_frame : bool = false,
    movement: pdapi.PDButtons,
};

// TODO:
// maybe remove diagonals
// left+right in one tick should maybe cancel out

fn input_direction(direction : pdapi.PDButtons) transform.Vector(i32) {
    var new_vector = transform.Vector(i32){.x = 0, .y = 0};
    if (direction & pdapi.BUTTON_LEFT != 0) {
    new_vector.x -= 1;
    }
    if (direction & pdapi.BUTTON_RIGHT != 0) {
        new_vector.x += 1;
    }
    if (direction & pdapi.BUTTON_UP != 0) {
        new_vector.y -= 1;
    }
    if (direction & pdapi.BUTTON_DOWN != 0) {
        new_vector.y += 1;
    }
    return new_vector;
}

fn get_entity_here(world : *ecs.ECS, position : transform.Vector(i32) ) ecs.Entity {
    var iter = ecs.data_iter(.{.transform = transform.Transform}).init(world);
    while(iter.next()) |slice| {
        if(slice.transform.*.eql(position)) {
            return slice.entity;
        }
    }
    return null;
}

pub fn update_movement(ctx : *context.Context, entity_controls: *Controls, entity_brain: *brain.Brain) !void {
    var world: *ecs.ECS = &ctx.*.world;
    if(entity_brain.*.time_till_react != 0) {
        // Too slow!
        return;
    }

    const entity_body: ecs.Entity = entity_brain.*.body;
    var entity_transform: *transform.Transform = (try world.get_component(entity_body, "transform", transform.Transform)).?;

    const direction = input_direction(entity_controls.*.movement);
    const move_to = entity_transform.*.plus(direction);
    if(!ctx.*.map.collides( move_to )){
        // Doesn't collide!

        // Is there an entity chillin' at this spot?
        const entity_there = get_entity_here(world, move_to);
        if(entity_there != null) { // If so, attack it I suppose
            // This garbage attacks. If it errors, ignore it if the entity simple doesn't have the component. Halt and Catch Fire otherwise.
            breakable.take_damage(ctx, entity_there) catch |err| switch (err) {ecs.ECSError.EntityDoesNotHaveComponent => {}, else => return err};
        }else{// If not, move there.
            entity_transform.* = move_to;
        }
    }

    // entity_controls.*.movement = 0;
    entity_controls.*.pressed_this_frame = false;
}

pub fn update_controls(playdate: *pdapi.PlaydateAPI, entity_controls: *Controls) void {
    var pressed: pdapi.PDButtons = 0;
    var released: pdapi.PDButtons = 0;
    var current: pdapi.PDButtons = 0;
    playdate.system.getButtonState(&current, &pressed, &released);
    if(pressed != 0) {
        entity_controls.*.pressed_this_frame = true;
    }
    if(current != 0) {
        entity_controls.*.movement = current;
    }else if( entity_controls.*.pressed_this_frame == false ) {
        entity_controls.*.movement = 0;
    }
}
