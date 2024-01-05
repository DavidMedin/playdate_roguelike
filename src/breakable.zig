const std = @import("std");
const ecs = @import("ecs");
const context = @import("context.zig");

pub const Breakable = struct { max_health: u64, health: u64 };

pub fn take_damage(ctx: *context.Context, me: ecs.Entity, damage: u64) !void {
    const mes_breakable: *Breakable = (try ctx.*.world.get_component(me, "breakable", Breakable)).?;

    // if (mes_breakable.*.health >= damage) {
    //     mes_breakable.*.health -= damage;
    // }else {
    //     // clamp to 0; we don't have negative numbers!
    //     mes_breakable.*.health = 0;
    // }
    mes_breakable.*.health -|= damage;

    //									  v --- plot armor
    if (mes_breakable.*.health == 0 and !std.meta.eql(me, ctx.*.player_entity)) {
        try ctx.*.world.queue_kill_entity(me);
        // Queue deletion
    }
}

// pub fn take_damage(ctx : *context.Context, self : *Breakable, self_entity : ecs.Entity, damage : u32) void {
// 	_ = self_entity;
// 	_ = damage;
// 	_ = ctx;
// 	if(self.*.health != 0){
//         self.*.health -= 1;
//     }
// }
