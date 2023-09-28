const ecs = @import("ecs");

pub const Body = struct { brain: ecs.Entity, holding_item : ecs.Entity = null };
