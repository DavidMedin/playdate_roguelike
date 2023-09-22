const std = @import("std");
const pdapi = @import("playdate.zig");

const BLOCK_SIZE = 16;
const Rect = struct {
    x : i32,
    y : i32,
    w : i32 = BLOCK_SIZE,
    h : i32 = BLOCK_SIZE
};

pub const Map = struct {
    const Self = @This();
    const id_map = [_]u32{
1,2,2,2,2,2,2,3, 0,0,0,0,0,0, 1,2,3,
4,0,0,0,0,0,0,5, 0,0,0,0,0,0, 4,0,5,
4,0,0,0,0,0,0,9, 2,2,2,2,2,11,4,0,5,
4,0,0,0,0,0,0,0, 0,0,0,0,0,0, 0,0,5,
4,0,0,0,0,0,0,10,7,7,7,7,7,12,4,0,5,
6,7,7,7,7,7,7,8 ,0,0,0,0,0,0, 6,7,8 
};
    spritesheet_image : *pdapi.LCDBitmap,
    block_locations : []Rect,

    pub fn init(playdate : *pdapi.PlaydateAPI) Self {
        const locations = [_]Rect {
            .{.x = 16, .y = 16},
            .{.x = 0,.y=0},
            .{.x = 16, .y = 0},
            .{.x = 32, .y = 0},
            .{.x = 0, .y = 16},
            .{.x = 32, .y = 16},
            .{.x = 0, .y = 32},
            .{.x = 16, .y = 32},
            .{.x = 32, .y = 32},
            .{.x = 48, .y = 32},
            .{.x = 48, .y = 16},
            .{.x = 64, .y = 32},
            .{.x = 64, .y = 16},
            .{.x = 48, .y = 0} // Full block
        };
        _ = locations;
        return .{
            .spritesheet_image = playdate.graphics.loadBitmap("tilemap", null).?,
            
         };
    }
    
    pub fn draw(self : *Self) void {
        _ = self;
        
    }
};
