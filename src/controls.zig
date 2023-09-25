const std = @import("std");
const ecs = @import("ecs");
const pdapi = @import("playdate.zig");
const context = @import("context.zig");

const transform = @import("transform.zig");
const brain = @import("brain.zig");

pub const Controls = struct {
    const Self = @This();
    pressed_this_frame : bool = false,
    movement: pdapi.PDButtons,
};

// TODO:
// maybe remove diagonals
// left+right in one tick should maybe cancel out

fn input_direction(direction : pdapi.PDButtons) transform.Vector {
    var new_vector = transform.Vector{.x = 0, .y = 0};
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

pub fn update_movement(world: *ecs.ECS, ctx : *context.Context, entity_controls: *Controls, entity_brain: *brain.Brain) void {
    _ = ctx;
    const entity_body: ecs.Entity = entity_brain.*.body;
    var entity_transform: *transform.Transform = (world.get_component(entity_body, "transform", transform.Transform) catch unreachable).?;

    const direction = input_direction(entity_controls.*.movement);
    const move_to = entity_transform.*.plus(direction);
    // if(!ctx.*.map.collides( move_to )){
        // Doesn't collide! move.
        entity_transform.* = move_to;
    // }

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
