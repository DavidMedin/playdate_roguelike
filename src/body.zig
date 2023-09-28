const ecs = @import("ecs");
const context = @import("context.zig");
const handy = @import("handy.zig");

pub const Body = struct { brain: ecs.Entity, holding_item : ecs.Entity = null };

// Gets the body of an entity, if it has a holding item and it is 'handy', return its damage. else returns 1.
pub fn get_item_damage(ctx : *context.Context, me : ecs.Entity) !u64 {
    const world = &ctx.*.world;
    // This is a big statement. Here is what it says:
    // If the entity the brain is posessing has a body, try to get its holding item.
    // If it doesn't have one, damage is 1. If it has one, get its damage.
    // If the brain is posessing an entity that isn't a Body, deal 1 damage.
    return if(try world.get_component(me, "body", Body)) |player_body_comp| block: {
        if(player_body_comp.*.holding_item == null){
            break :block 1; // DEFAULT : 1 damage.
        }
        if((try world.get_component(player_body_comp.*.holding_item, "handy", handy.Handy))) |handy_comp| {
            break :block handy_comp.*.damage;
        }
        break :block 1;
    }else block: {
        break :block 1;
    };
}

// // Non-system function
// pub fn pickup_items(ctx: *context.Context, )