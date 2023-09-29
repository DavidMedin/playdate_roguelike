const std = @import("std");
const ecs = @import("ecs");
const pdapi = @import("playdate.zig");
const context = @import("context.zig");

const transform = @import("transform.zig");
const brain = @import("brain.zig");
const breakable = @import("breakable.zig");
const body = @import("body.zig");
const handy = @import("handy.zig");


pub const Controls = struct {
    const Self = @This();
    dpad_pressed_this_frame : bool = false,
    movement: pdapi.PDButtons = 0,
    button_pressed : pdapi.PDButtons = 0,
    is_item_ready : bool = false, // Whether the uesr pressed 'A' and is waiting for more input.
};

// TODO:
// maybe remove diagonals
// left+right in one tick should maybe cancel out

pub fn input_direction(direction : pdapi.PDButtons) transform.Vector(i32) {
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

fn get_entities_here(ctx : *context.Context, position : transform.Vector(i32) ) !?std.ArrayList(ecs.Entity) {
    const world = &ctx.*.world;
    var list = std.ArrayList(ecs.Entity).init(ctx.*.allocator);
    var iter = ecs.data_iter(.{.transform = transform.Transform}).init(world);
    while(iter.next()) |slice| {
        if(slice.transform.*.eql(position)) {
            // return slice.entity;
            try list.append(slice.entity);
        }
    }
    if(list.items.len == 0){
        list.deinit();
        return null;
    }
    return list;
}

pub fn update_movement(ctx : *context.Context, me : ecs.Entity, entity_controls: *Controls, entity_brain: *brain.Brain) !void {
    var world: *ecs.ECS = &ctx.*.world;
    if(entity_brain.*.time_till_react != 0) {
        // Too slow!
        return;
    }

    const entity_body: ecs.Entity = entity_brain.*.body;
    var entity_transform: *transform.Transform = (try world.get_component(entity_body, "transform", transform.Transform)).?;

    const direction = input_direction(entity_controls.*.movement);
    
    if(direction.x != 0 or direction.y != 0) {
        const move_to = entity_transform.*.plus(direction);
        if(!ctx.*.map.collides( move_to )){
            // Doesn't collide!

            // Is there an entity chillin' at this spot?
            // const entity_there = get_entity_here(world, move_to);
            // if(entity_there != null) { // If so, attack it I suppose

            //     const damage : u64 = try body.get_item_damage(ctx, entity_body);

            //     // This garbage attacks. If it errors, ignore it if the entity simple doesn't have the component. Halt and Catch Fire otherwise.
            //     breakable.take_damage(ctx, entity_there, damage) catch |err| switch (err) {ecs.ECSError.EntityDoesNotHaveComponent => {}, else => return err};
            // }else{// If not, move there.
                entity_transform.* = move_to;
            // }
        }
    }else
    if(entity_controls.*.button_pressed & pdapi.BUTTON_B != 0) {
        std.log.info("B has been pressed!",.{});
        // Is there an entity chillin' at this spot?
        if(try get_entities_here(ctx, entity_transform.*.plus(direction))) |entities_there| {
            defer entities_there.deinit(); // Delete the allocated stuff there.
            // There can be multiple entities in one place. So, pick up the first valid item. Not me though. No self-picking-up.
            for(entities_there.items) |entity| {
                if(std.meta.eql(me, entity)){
                    // Don't pick up yourself.
                    continue;
                }
                if(try world.get_component(entity, "handy", handy.Handy) != null) {
                    if(try world.get_component(entity_body, "body", body.Body)) |entity_body_body| {
                        entity_body_body.*.holding_item = entity;
                        try world.queue_remove_component(entity, "transform");
                        try world.queue_remove_component(entity, "image");
                        break;
                    }// Otherwise, your body can't pick up things. L rip bozo
                } // otherwise, don't pick up the item; you can't pick it up.
            }
        }
    }else if(entity_controls.*.button_pressed & pdapi.BUTTON_A != 0) {
        // use item.
        entity_controls.*.is_item_ready = true;
    }

    entity_controls.*.dpad_pressed_this_frame = false;
    entity_controls.*.button_pressed = 0;
}

pub fn update_controls(playdate: *pdapi.PlaydateAPI, entity_controls: *Controls) void {
    var pressed: pdapi.PDButtons = 0;
    var released: pdapi.PDButtons = 0;
    var current: pdapi.PDButtons = 0;
    playdate.system.getButtonState(&current, &pressed, &released);

    const ANY_DPAD : pdapi.PDButtons = pdapi.BUTTON_DOWN | pdapi.BUTTON_LEFT | pdapi.BUTTON_RIGHT | pdapi.BUTTON_UP;
    const BUTTONS : pdapi.PDButtons = ~ANY_DPAD;

    // Movement 'feel'
    if(pressed & ANY_DPAD != 0) {
        entity_controls.*.dpad_pressed_this_frame = true;
    }
    if(current & ANY_DPAD != 0) {
        entity_controls.*.movement = current & ANY_DPAD;
    }else if( entity_controls.*.dpad_pressed_this_frame == false ) {
        entity_controls.*.movement = 0;
    }

    // Single press buttons
    if(pressed & BUTTONS != 0 ) {
        entity_controls.*.button_pressed |= pressed & BUTTONS;
    }
}
