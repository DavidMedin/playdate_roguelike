const std = @import("std");
const ecs = @import("ecs");
const pdapi = @import("playdate.zig");

pub const VectorErr = error {
    NaN
};
pub fn Vector(comptime grid_type : type) type{
    return struct {
        const Self = @This();
        x: grid_type, y: grid_type,
        pub fn plus(self: Self, other : Self) Self {
            return .{.x = self.x + other.x, .y = self.y + other.y};
        }
        pub fn sub(self: Self, other : Self) Self {
            return .{.x = self.x - other.x, .y = self.y - other.y};
        }
        pub fn divide(self : Self, other : anytype) Self {
            if(@TypeOf(other) == Self) {
                return .{.x = self.x / other.x, .y = self.y / other.y};
            }
            if(@TypeOf(other) == f32) {
                return .{.x = @as(f32, self.x) / other, .y = @as(f32,self.y) / other};
            }
            @panic("Vector.divide can only take a Vector or f32!");
        }
        pub fn eql(self : Self, other : Self) bool {
            return self.x == other.x and self.y == other.y;
        }

        pub fn cast(self : Self, comptime to : type) Vector(to) {
            switch(@typeInfo(grid_type)) {
                .Int => {
                    switch(@typeInfo(to)) {
                    .Int => {
                        return Vector(to){.x = @as(to,@intCast( self.x)), .y= @as(to, @intCast(self.y))};
                    },
                    .Float => {
                        return Vector(to){.x = @as(to,@floatFromInt( self.x)), .y= @as(to, @floatFromInt(self.y))};
                    },
                    else => {@panic("Not implemented");}

                    }
                },
                .Float => {
                    switch(@typeInfo(to)) {
                    .Int => {
                        return Vector(to){.x = @as(to,@intFromFloat( self.x)), .y= @as(to, @intFromFloat(self.y))};
                    },
                    .Float => {
                        return Vector(to){.x = @as(to,@floatCast( self.x)), .y= @as(to, @floatCast(self.y))};
                    },
                    else => {@panic("Not implemented");}
                    }
                    
                },
                else => {@panic("Not implemented, also why are you doing this.");}
            }
        }

        pub fn mag(self : Self) f32 {
            return std.math.sqrt( std.math.pow(f32, @as(f32, self.x), 2) + std.math.pow(f32,@as(f32,self.y), 2));
        }
        pub fn normalize(self : Self) !Self {
            
            const magnitude = self.cast(f32).mag();
            if(magnitude == 0){
                return VectorErr.NaN;
            }
            const inter : Vector(f32) = self.cast(f32).divide(magnitude);
            if(grid_type == f32) {
                return inter;
            }else if(grid_type == i32 or grid_type == i64) {
                return (Self{
                    .x = @as(grid_type,
                        @intFromFloat(
                    std.math.round(inter.x))),
                    .y = @as(grid_type,
                    @intFromFloat(
                    std.math.round(inter.y)))
                    }).cast(grid_type);
            }
            @panic("I don't know how to convert!");
        }
    };
}
pub const Transform = Vector(i32);
