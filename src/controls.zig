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
    _ = entity_transform;
    // const pressed: pdapi.PDButtons = 0;
    // const released: pdapi.PDButtons = 0;
    const current: pdapi.PDButtons = 0;
    playdate.system.getButtonState(@constCast(&current), null, null);
    // if ((current & pdapi.BUTTON_LEFT) == 0) {
    //     // var entity_transform: *transform.Transform = try world.get_component(entity, "transform", transform.Transform);
    //     // entity_transform.*.x -= 1;
    // }
}
