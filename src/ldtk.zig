const std = @import("std");
const json = std.json;
const pdapi = @import("playdate.zig");



const Entity = struct {
    height : i32,
    width: i32,
    identifier : []u8,
    pivotX : f32,
    pivotY : f32,
    tileRect: ?TilesetRect,
    tilesetId: ?i32,
    uid : i32,
    // tileId : ?i32 Deprecated
};

const EnumValue = struct {
    id : []u8,
    tileRect : ?TilesetRect,
};
const Enum = struct {
    externalRelPath: ?[]u8,
    iconTilesetUid: ?i32,
    tags: [][]u8,
    uid: i32,
    values: []EnumValue
};

const GridValue = struct {
    identifier : ?[]u8,
    tile : ?TilesetRect,
    value : i32
};

const Layer = struct {
    __type : []u8,
    gridSize : i32,
    identifier : []u8,
    intGridValues : []GridValue,
    pxOffsetX : i32,
    pxOffsetY : i32,
    uid : i32,
};

//  const Field = struct {

//  };

const TilesetRect = struct {
    x:i32,y:i32,h:i32,w:i32,tilesetUid:i32
};
const Data =struct {
    data : []u8,
    tileId : i32
};
const EnumTags = struct {
    enumValueId : []u8,
    tileIds : []i32
};
const Tileset = struct {
    __cHei : i32, // grid based height
    __cWid : i32, // grid bashed width
    customData : []Data,
    embedAtlas : ?Enum,
    enumTags : []EnumTags,
    identifier : []u8,
    padding : i32,
    pxHei : i32,
    pxWid: i32,
    relPath : ?[]u8,
    spacing : i32,
    tags : [][]u8,
    tagsSourceEnumUid : ?i32,
    tileGridSize : i32,
    uid : i32
};

const Definitions = struct {
    entities: []Entity,
    enums : []Enum,
    externalEnums : []Enum,
    layers : []Layer,
    tilesets : []Tileset // Very important!
    // levelFields : []Field, // I think this is only used by the app, so I can ignore this.
};

const Neighbour = struct {
    dir : []u8,
    levelIid : []u8,
};
const FieldInstance = struct {
    __identifier : []u8,
    __tile : ?TilesetRect,
    __type : []u8,
    __value : json.Value,
    defUid : i32
};

// can be in an .ldtkl file (still json)
const Level = struct {
    __neighbours : []Neighbour,
    fieldInstances : []FieldInstance,
    identifier : []u8,
    iid: []u8,
    // layerInstances : ?[]
    pxHei : i32,
    pxWid : i32,
    uid : i32,
    worldX : i32,
    worldY : i32,

};

const World = struct {
    identifier : []u8,
    iid : []u8,
    level : []Level,
    worldGridHeight : i32,
    worldGridWidth : i32,
    // worldlayout : 
};

const LDtk_root = struct {
    __header__: json.Value,
    bgColor: []u8,
    defs: Definitions, //Definitions
    externalLevels: bool,
    iid: []u8,
    jsonVersion: []u8,
    levels: []Level, // Level
    // toc: []json.Value,
    worldGridHeight: ?i32,
    worldGridWidth: ?i32,
    worldLayout: ?json.Value,
    worlds: []World
};

pub fn test_json(playdate: *pdapi.PlaydateAPI, allocator: std.mem.Allocator) !void {
    const file_name = "map.ldtk"; // /Disk
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

    // std.log.debug("json: {s}", .{json_slice});
    // json.Parser.init()
    var parsed = try std.json.parseFromSlice(LDtk_root, allocator, json_slice, .{.ignore_unknown_fields = true });
    defer parsed.deinit();
    // std.log.debug("thing : {}", .{parsed.value});
}


test "aaah" {

    // std.debug.print("Hello",.{});
    const file = try std.fs.cwd().openFile("assets/map.ldtk", .{});
    const file_stats = try file.stat();
    var file_data : []u8 = try file.readToEndAlloc(std.testing.allocator, file_stats.size);
    file.close();

    // std.debug.print("{s}", .{file_data});
    // try do_json(std.testing.allocator, file_data);
    var parsed = try std.json.parseFromSlice(LDtk_root, std.testing.allocator, file_data, .{.ignore_unknown_fields = true });
    parsed.deinit();

    std.testing.allocator.free(file_data);
}