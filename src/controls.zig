const std = @import("std");
const ecs = @import("ecs");
const pdapi = @import("playdate.zig");

const transform = @import("transform.zig");
const brain = @import("brain.zig");

pub const Controls = struct {
    const Self = @This();
    movement: pdapi.PDButtons,
};

pub fn update_movement(world: *ecs.ECS, entity_controls: *Controls, entity_brain: *brain.Brain) void {
    const entity_body: ecs.Entity = entity_brain.*.body;
    var entity_transform: *transform.Transform = (world.get_component(entity_body, "transform", transform.Transform) catch unreachable).?;
    var move_when = entity_controls.*.movement;

    if (move_when & pdapi.BUTTON_LEFT != 0) {
        entity_transform.*.x -= 1;
    }
    if (move_when & pdapi.BUTTON_RIGHT != 0) {
        entity_transform.*.x += 1;
    }
    if (move_when & pdapi.BUTTON_UP != 0) {
        entity_transform.*.y -= 1;
    }
    if (move_when & pdapi.BUTTON_DOWN != 0) {
        entity_transform.*.y += 1;
    }
    entity_controls.*.movement = 0;
}

pub fn update_controls(playdate: *pdapi.PlaydateAPI, entity_controls: *Controls) void {
    var pressed: pdapi.PDButtons = 0;
    var released: pdapi.PDButtons = 0;
    var current: pdapi.PDButtons = 0;
    playdate.system.getButtonState(&current, &pressed, &released);
    entity_controls.*.movement = current;
}
