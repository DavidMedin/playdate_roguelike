const std = @import("std");
const pdapi = @import("playdate.zig");
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
    spritesheet_image : *pdapi.LCDBitmapTable,

    pub fn init(playdate : *pdapi.PlaydateAPI) Self {
        return .{
            .spritesheet_image = playdate.graphics.loadBitmapTable("tilemap", null).?,
            
         };
    }
    
    pub fn draw(self : *Self, playdate : *pdapi.PlaydateAPI) void {
        var x : i32 = 0;
        while(x < Map.MAP_WIDTH) {
            var y : i23 = 0;
            while(y < Map.MAP_HEIGHT){
                const block_idx : i32 = @intCast(Map.id_map[@intCast( x + y * Map.MAP_WIDTH) ]);
                const map_offset : transform.Vector = .{.x = 40,.y = 40};
                const bitmap : *pdapi.LCDBitmap = playdate.graphics.getTableBitmap(self.*.spritesheet_image, @intCast(block_idx)).?;
                const block_pos : transform.Vector = .{.x = map_offset.x + x * 16, .y = map_offset.y + y * 16};
                playdate.graphics.drawBitmap(bitmap,block_pos.x, block_pos.y, pdapi.LCDBitmapFlip.BitmapUnflipped);
                y += 1;    
            }
            x += 1;
        }
    }
};
