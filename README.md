# Playdate Roguelike



- Be Mindful Of The Stack
    - You only get 10KB of stack space. That's it. I have not tested much of Zig's std on the Playdate, but std was not designed for a stack this small. See how far you can get, but you might want to write a lightweight "toolbox" library, like I did for UPWARD.  `std.fmt.bufPrintZ` works well, though!.

##  <a name="Requirements"></a>Requirements
- Either macOS, Windows, or Linux.
- Zig compiler 0.12.0-dev.21+ac95cfe44 ish.
- [Playdate SDK](https://play.date/dev/) 2.0.0 or later installed.

## Contents
- `build.zig` -- Prepopulated with code that will generate the Playdate `.pdx` executable.
- `src/playdate.zig` -- Contains all of the Playdate API code.  This is 1-to-1 with [Playdate's C API](https://sdk.play.date/2.0.3/Inside%20Playdate%20with%20C.html)
- `main.zig` -- Entry point for your code!  Contains example code that prints "Hello from Zig!" and an draws an example image to the screen.
- `assets/` -- This folder will contain your assets and has an example image that is drawn to the screen in the example code in `main.zig`.

## Run Example Code
1. Make sure the Playdate SDK is installed, Zig is installed and in your PATH, and all other [requirements](#Requirements) are met.
1. Make sure the Playdate Simulator is closed.
1. Run `zig build run`.
    1. If there any errors, double check `PLAYDATE_SDK_PATH` is correctly set.
1. You should now see simulator come up and look the [screenshot here](#screenshot).
1. When you quit out to the home menu, change the home menu to view as list and you should see the "Hello World Zig" program with a custom icon [like here](#home-screen-list-view).
