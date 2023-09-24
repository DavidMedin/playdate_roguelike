const ecs = @import("ecs");
const pdapi = @import("playdate.zig");

pub const Vector = struct { 
    x: i32, y: i32,
    pub fn plus(self: Vector, other : Vector) Vector {
        return .{.x = self.x + other.x, .y = self.y + other.y};
    }
};
pub const Transform = Vector;
