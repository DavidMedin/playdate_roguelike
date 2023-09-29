// Handy entities are those who can be picked up and manipulated. Like a stick, potion, or sword.
const std = @import("std");
const ecs = @import("ecs");
const context = @import("context.zig");

const controls = @import("controls.zig");

pub fn hit(ctx : *context.Context,ctrls : *controls.Controls , user : ecs.Entity, item : ecs.Entity, item_handy : *Handy) anyerror!bool {
    _ = item_handy;
    _ = item;
    _ = user;
    const direction = controls.input_direction(ctrls.*.movement);
    ctx.*.cursor.position = ctx.*.cursor.position.plus(direction);
    ctrls.*.dpad_pressed_this_frame = false;
}

pub const Handy = struct {
    const Self = @This();
    // sharpness : u32,
    // length : u32,
    damage : u64, // how bad does this hurt?
    // mass : u32,

    //                                                          user         item                     done?
    use_fn : *const fn (*context.Context,*controls.Controls, ecs.Entity, ecs.Entity, *Handy) anyerror!bool
};