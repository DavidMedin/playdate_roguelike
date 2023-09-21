const std = @import("std");
const pdapi = @import("playdate.zig");

const LDtk_root = struct {
    // bgColor: []u8,
    // iid: []u8,
    // jsonVersion: []u8,
    Hello: u32,
    thing: []std.json.Value,
};

pub fn test_json(playdate: *pdapi.PlaydateAPI, allocator: std.mem.Allocator) !void {
    const file_name = "test.json"; // /Disk
    var stats: pdapi.FileStat = undefined;
    if (playdate.file.stat(file_name, &stats) != 0) {
        unreachable;
    }
    var file: *pdapi.SDFile = playdate.file.open(file_name, pdapi.FILE_READ).?;
    defer if (playdate.file.close(file) != 0) {
        unreachable;
    };

    // Allocate enough space for the json text.
    var json_string: [*]u8 = @ptrCast(playdate.system.realloc(null, stats.size).?);
    // defer _ = playdate.system.realloc(json_string, 0);
    var json_slice: []u8 = json_string[0..stats.size];

    const bytes_read = playdate.file.read(file, json_string, stats.size);
    _ = bytes_read;

    std.log.debug("json: {s}", .{json_slice});
    // json.Parser.init()
    var parsed = try std.json.parseFromSlice(LDtk_root, allocator, json_slice, .{});
    defer parsed.deinit();
    std.log.debug("thing : {}", .{parsed.value});
}
