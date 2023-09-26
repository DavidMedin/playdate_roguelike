const context = @import("context.zig");
const ecs = @import("ecs");

pub const Breakable = struct {
	max_health : u64,
	health : u64
};

pub fn take_damage(ctx : *context.Context, me : ecs.Entity) !void {
    var mes_breakable : *Breakable = (try ctx.*.world.get_component(me, "breakable", Breakable)).?;
	
	if(mes_breakable.*.health != 0) {
		mes_breakable.*.health -= 1;
	}

	if(mes_breakable.*.health == 0){
		// ctx.*.world.
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