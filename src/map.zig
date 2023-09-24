const std = @import("std");
const pdapi = @import("playdate.zig");

const context = @import("context.zig");

const transform = @import("transform.zig");

const BLOCK_SIZE = 16;
const Rect = struct {
    x : i32,
    y : i32,
    w : i32 = BLOCK_SIZE,
    h : i32 = BLOCK_SIZE
};

pub const Map = struct {
    const Self = @This();
    const MAP_WIDTH = 17;
    const MAP_HEIGHT = 10;
    const id_map = [_]u32{
0 ,1 ,1 ,1 ,1 ,1 ,2 ,3 ,3 ,3 ,3 ,3 ,3, 3, 3 ,3, 3 ,
6 ,7 ,7 ,7 ,7 ,7 ,8 ,3 ,3 ,3 ,3 ,0 ,1, 1, 1 ,1, 2 ,
6 ,7 ,7 ,7 ,7 ,7 ,8 ,3 ,3 ,3 ,3 ,6 ,7, 7 ,7 ,7 ,8 ,
6 ,7 ,7 ,7 ,7 ,7 ,8 ,3 ,3 ,3 ,3 ,6 ,7, 7 ,7 ,7 ,8 ,
6 ,7 ,7 ,7 ,7 ,7 ,15,1 ,1 ,1 ,1 ,16,7, 7 ,7 ,7 ,8 ,
6 ,7 ,7 ,7 ,7 ,7 ,7 ,7 ,7 ,7 ,7 ,7 ,7, 7 ,7 ,7 ,8 ,
6 ,7 ,7 ,7 ,7 ,7 ,9 ,13,13,13,13,10,7, 7 ,7 ,7 ,8 ,
6 ,7 ,7 ,7 ,7 ,7 ,8 ,3 ,3 ,3 ,3 ,6 ,7, 7 ,7 ,7 ,8 ,
6 ,7 ,7 ,7 ,7 ,7 ,8 ,3 ,3 ,3 ,3 ,6 ,7, 7 ,7 ,7 ,8 ,
12,13,13,13,13,13,14,3 ,3 ,3 ,3 ,12,13,13,13,13,14,
};
    const NOT_COLLIDABLE = [_]i32{7};
    ctx : *context.Context,

    pub fn init(ctx : *context.Context) Self {
        // Warning! ctx is not gurenteed to be fully built by this point!
        return .{
            .ctx = ctx            
         };
    }

    pub fn collides(self : *Self, position : transform.Vector) bool {
        _ = self;
        // Get the ID being rendered by checking that huge array above.
        const block_idx : i32 = @intCast(Map.id_map[@intCast( position.x + position.y * Map.MAP_WIDTH) ]);
        for(Map.NOT_COLLIDABLE) |not_collidable| {
            if(block_idx == not_collidable) {
                return false;
            }
        }
        return true;
    }
    
    pub fn draw(self : *Self) void {
        const playdate : *pdapi.PlaydateAPI = self.*.ctx.*.playdate; // Because it is easier :)

        var x : i32 = 0;
        while(x < Map.MAP_WIDTH) {
            var y : i23 = 0;
            while(y < Map.MAP_HEIGHT){
                // Get the ID being rendered by checking that huge array above.
                const block_idx : i32 = @intCast(Map.id_map[@intCast( x + y * Map.MAP_WIDTH) ]);
                
                // Helper constant
                const map_offset : transform.Vector = .{.x = 0,.y = 0};
                
                // Query what image to render from the global tileset
                const bitmap : *pdapi.LCDBitmap = playdate.graphics.getTableBitmap(self.*.ctx.*.tileset, @intCast(block_idx)).?;
                
                // Calculate where the block goes
                const block_pos : transform.Vector = .{.x = map_offset.x + x * 16, .y = map_offset.y + y * 16};
                // Draw!
                playdate.graphics.drawBitmap(bitmap,block_pos.x, block_pos.y, pdapi.LCDBitmapFlip.BitmapUnflipped);
                y += 1;    
            }
            x += 1;
        }
    }
};
