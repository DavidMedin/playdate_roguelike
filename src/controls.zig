const std = @import("std");
const ecs = @import("ecs");
const pdapi = @import("playdate.zig");

const context = @import("context.zig");
const map = @import("map.zig");

const transform = @import("transform.zig");
const brain = @import("brain.zig");
const breakable = @import("breakable.zig");
const body = @import("body.zig");
const handy = @import("handy.zig");

const b_hold_click_ms = 150;
// const b_hold_inv_ms = 750;
pub const Controls = struct {
    const Self = @This();
    dpad_pressed_this_frame: bool = false,
    movement: pdapi.PDButtons = 0,
    buttons_pressed: pdapi.PDButtons = 0,
    buttons_released: pdapi.PDButtons = 0,
    b_holding_timer: u32 = 0, // B is down right now, for how long?
    b_held_length: u32 = 0, // B was released, how long was it pressed?
    display_b_hold: bool = false,
};

// TODO:
// maybe remove diagonals
// left+right in one tick should maybe cancel out

pub fn input_direction(direction: pdapi.PDButtons) transform.Vector(i32) {
    var new_vector = transform.Vector(i32){ .x = 0, .y = 0 };
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

pub fn hit_init(ctx: *context.Context, users_pos: *transform.Transform) void {
    ctx.*.cursor.active = true;
    ctx.*.tick_paused = true;
    ctx.*.cursor.position = users_pos.*;
}
pub fn hit_deinit(ctx: *context.Context) void {
    ctx.*.tick_paused = false;
    ctx.*.cursor.active = false;
}

pub fn item_update(ctx: *context.Context, me: ecs.Entity, entity_controls: *Controls, entity_brain: *brain.Brain) !void {
    _ = me;
    const world = &ctx.*.world;
    const body_entity = entity_brain.*.body orelse {
        hit_deinit(ctx);
        return;
    };
    const body_body: *body.Body = (world.get_component(body_entity, "body", body.Body) catch |err| {
        // If the body is dead...
        if (err == ecs.ECSError.OldEntity) {
            std.log.warn("item_update: ecs.get \"Body\" from entity : {}, entity : {} is dead.", .{ body_entity, body_entity });
            entity_brain.*.body = null; // Updating the fact that the body doesn't exist.
            hit_deinit(ctx);

            return;
        }
        return err;
    }) orelse {
        // if the 'body' doesn't have the Body component (like if we posessed a chair)
        hit_deinit(ctx);
        return;
    };
    // Now we know that the brain is posessing a body that contains the Body component.

    const item_entity = body_body.*.holding_item orelse {
        hit_deinit(ctx);
        return;
    }; // Get the item the body is holding, or return if we aren't.
    const item_handy: *handy.Handy = (world.get_component(item_entity, "handy", handy.Handy) catch |err| {
        if (err == ecs.ECSError.OldEntity) {
            std.log.warn("item_update: ecs.get \"Handy\" from entity : {}, entity : {} is dead.", .{ item_entity, item_entity });
            body_body.*.holding_item = null;
            hit_deinit(ctx);
            return;
        }
        return err;
    }) orelse {
        std.log.warn("item_update: ecs.get \"Handy\" from entity : {}, entity {} does not have component. Player shouldn't be able to pick up entities that don't have the \"Handy\" component!", .{ item_entity, item_entity });
        hit_deinit(ctx);
        return;
    };
    // Now we have the actual item that is being used right now.

    const direction = input_direction(entity_controls.*.movement); // Resolve input
    const would_go_to = ctx.*.cursor.position.plus(direction); // Where would the cursor go?
    const body_transform: *transform.Transform = (try world.get_component(body_entity, "transform", transform.Transform)).?;

    if (body_transform.*.is_adjacent(would_go_to)) { // If the cursor would stay within 1 tile from the caster
        ctx.*.cursor.position = would_go_to;
    }

    if (entity_controls.*.buttons_pressed & pdapi.BUTTON_A != 0) {
        // Pressed 'A'
        try handy.hit(ctx, body_entity, item_entity, item_handy);
        // Done hitting, resume!
        hit_deinit(ctx);
    } else if (entity_controls.*.buttons_pressed & pdapi.BUTTON_B != 0) {
        // Pressed 'B"
        hit_deinit(ctx);
    }

    entity_controls.*.dpad_pressed_this_frame = false;
    entity_controls.*.buttons_pressed = 0;
}

pub inline fn pickup_item(ctx: *context.Context, me: ecs.Entity, entity_body: ecs.Entity, entity_transform: *transform.Transform, direction: transform.Vector(i32)) !void {
    const world = &ctx.*.world;
    // Is there an entity chillin' at this spot?
    if (try map.get_entities_here(ctx, entity_transform.*.plus(direction))) |entities_there| {
        defer entities_there.deinit(); // Delete the allocated stuff there.
        // There can be multiple entities in one place. So, pick up the first valid item. Not me though. No self-picking-up.
        for (entities_there.items) |entity| {
            if (std.meta.eql(me, entity)) {
                // Don't pick up yourself.
                continue;
            }
            if (try world.get_component(entity, "handy", handy.Handy) != null) {
                if (try world.get_component(entity_body, "body", body.Body)) |entity_body_body| {
                    entity_body_body.*.holding_item = entity;
                    try world.queue_remove_component(entity, "transform");
                    try world.queue_remove_component(entity, "image");
                    break;
                } // Otherwise, your body can't pick up things. L rip bozo
            } // otherwise, don't pick up the item; you can't pick it up.
        }
    }
}

/// A Tick Function for moving the character.
pub fn update_movement(ctx: *context.Context, me: ecs.Entity, entity_controls: *Controls, entity_brain: *brain.Brain) !void {
    var world: *ecs.ECS = &ctx.*.world; // Helper misdirection
    if (entity_brain.*.time_till_react != 0) {
        // Too slow!
        return;
    }

    const entity_body: ecs.Entity = entity_brain.*.body;
    const entity_transform: *transform.Transform = (try world.get_component(entity_body, "transform", transform.Transform)).?;

    const direction = input_direction(entity_controls.*.movement);

    if (direction.x != 0 or direction.y != 0) {
        const move_to = entity_transform.*.plus(direction);
        if (!ctx.*.map.collides(move_to)) {
            // Doesn't collide!
            entity_transform.* = move_to;
        }
    } else if (entity_controls.*.buttons_released & pdapi.BUTTON_B != 0) {

        // const hold_to_inv_ms = 300;
        std.log.info("B has been released after {} milliseconds!", .{entity_controls.*.b_held_length});
        if (entity_controls.*.b_held_length < b_hold_click_ms) {
            std.log.info("Try picking up item.", .{});
            try pickup_item(ctx, me, entity_body, entity_transform, direction); // The player held the 'B' button short enough to pick up an item.
        } else {
            // Open the inventory! The player held 'B' for long enough.
        }
    } else if (entity_controls.*.buttons_pressed & pdapi.BUTTON_A != 0) {
        // use item.
        hit_init(ctx, entity_transform); // If we are hitting...
    }

    entity_controls.*.dpad_pressed_this_frame = false;
    entity_controls.*.buttons_pressed = 0;
    entity_controls.*.buttons_released = 0;
}

// pub fn init_control(entity_controls: *Controls) {
//     entity_controls.*. playdate.system.getCurrentTimeMilliseconds()
// }

pub fn update_controls(playdate: *pdapi.PlaydateAPI, entity_controls: *Controls) void {
    var pressed: pdapi.PDButtons = 0;
    var released: pdapi.PDButtons = 0;
    var current: pdapi.PDButtons = 0;
    playdate.system.getButtonState(&current, &pressed, &released);

    const ANY_DPAD: pdapi.PDButtons = pdapi.BUTTON_DOWN | pdapi.BUTTON_LEFT | pdapi.BUTTON_RIGHT | pdapi.BUTTON_UP;
    const BUTTONS: pdapi.PDButtons = ~ANY_DPAD;

    // Movement 'feel'
    if (pressed & ANY_DPAD != 0) {
        entity_controls.*.dpad_pressed_this_frame = true;
    }
    if (current & ANY_DPAD != 0) {
        entity_controls.*.movement = current & ANY_DPAD;
    } else if (entity_controls.*.dpad_pressed_this_frame == false) {
        entity_controls.*.movement = 0;
    }

    // Single press buttons
    if (pressed & BUTTONS != 0) {
        entity_controls.*.buttons_pressed |= pressed & BUTTONS;
    }
    if (released & BUTTONS != 0) {
        entity_controls.*.buttons_released |= released & BUTTONS;
    }

    if (pressed & pdapi.BUTTON_B != 0) {
        entity_controls.*.b_holding_timer = playdate.system.getCurrentTimeMilliseconds();
    } else if (released & pdapi.BUTTON_B != 0) {
        entity_controls.*.b_held_length = playdate.system.getCurrentTimeMilliseconds() - entity_controls.*.b_holding_timer;
        entity_controls.*.b_holding_timer = 0;
    }
    const current_held_ms = playdate.system.getCurrentTimeMilliseconds() - entity_controls.*.b_holding_timer;

    if (current & pdapi.BUTTON_B != 0 and current_held_ms > b_hold_click_ms) { // and current_held_ms < b_hold_inv_ms
        entity_controls.*.display_b_hold = true;
    } else {
        entity_controls.*.display_b_hold = false;
    }
}

pub fn display_controls(playdate: *pdapi.PlaydateAPI, entity_controls: *Controls) void {
    if (entity_controls.*.display_b_hold) {
        _ = playdate.graphics.drawText("B", 1, pdapi.PDStringEncoding.ASCIIEncoding, 400 - 10, 240 - 20);
    }
}
