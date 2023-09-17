const ecs = @import("ecs");
const pdapi = @import("playdate_api_definitions.zig");
// const image = @import("image.zig");
const transform = @import("transform.zig");

pub const Controls = struct {
    const Self = @This();
    // bitmap: *pdapi.LCDBitmap,
    dummy_data: i32,
};

pub fn update_controls(playdate: *pdapi.PlaydateAPI, entity_transform: *transform.Transform) void {
    var pressed: pdapi.PDButtons = 0;
    var released: pdapi.PDButtons = 0;
    var current: pdapi.PDButtons = 0;
    playdate.system.getButtonState(&current, &pressed, &released);
    if (current & pdapi.BUTTON_LEFT != 0) {
        entity_transform.*.x -= 1;
    }
    if (current & pdapi.BUTTON_RIGHT != 0) {
        entity_transform.*.x += 1;
    }
    if (current & pdapi.BUTTON_UP != 0) {
        entity_transform.*.y -= 1;
    }
    if (current & pdapi.BUTTON_DOWN != 0) {
        entity_transform.*.y += 1;
    }
}
