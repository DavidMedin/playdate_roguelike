const ecs = @import("ecs");

pub const Brain = struct { reaction_time: u64, time_till_react : u64 = 0, body: ecs.Entity };
pub fn react(self : *Brain) void {
    if(self.*.time_till_react == 0) {
        self.*.time_till_react = self.*.reaction_time;
    }else {
        self.*.time_till_react -= 1;
    }
}