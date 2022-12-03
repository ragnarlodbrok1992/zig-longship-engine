const std = @import("std");
const SDL = @import("sdl2"); // Add this package by using sdl.getNativePackage

const TITLE_BAR = "Longship Engine - pre-alpha version";
const VERSION = 0;

const RES_WIDTH = 800;
const RES_HEIGHT = 600;

const SDL_SCANCODE_ESCAPE: c_int = 41;

pub fn mouseClick() void {}

pub fn main() !void {
    std.debug.print("{s}: {}\n", .{ TITLE_BAR, VERSION });

    // SDL enabling code
    if (SDL.SDL_Init(SDL.SDL_INIT_VIDEO | SDL.SDL_INIT_EVENTS | SDL.SDL_INIT_AUDIO) < 0)
        sdlPanic();
    defer SDL.SDL_Quit();

    var main_window = SDL.SDL_CreateWindow(
        TITLE_BAR,
        SDL.SDL_WINDOWPOS_CENTERED,
        SDL.SDL_WINDOWPOS_CENTERED,
        RES_WIDTH,
        RES_HEIGHT,
        SDL.SDL_WINDOW_SHOWN,
    ) orelse sdlPanic();
    defer _ = SDL.SDL_DestroyWindow(main_window);

    var main_renderer = SDL.SDL_CreateRenderer(main_window, -1, SDL.SDL_RENDERER_ACCELERATED) orelse sdlPanic();
    defer _ = SDL.SDL_DestroyRenderer(main_renderer);

    mainLoop: while (true) {
        var ev: SDL.SDL_Event = undefined;
        while (SDL.SDL_PollEvent(&ev) != 0) {
            switch (ev.type) {
                SDL.SDL_QUIT => break :mainLoop,
                SDL.SDL_KEYDOWN => {
                    if (ev.key.keysym.scancode == SDL_SCANCODE_ESCAPE) break :mainLoop;
                },
                SDL.SDL_KEYUP => {},
                SDL.SDL_MOUSEBUTTONDOWN => {
                    var mouse_x: c_int = undefined;
                    var mouse_y: c_int = undefined;
                    var mouse_state_output: u32 = SDL.SDL_GetMouseState(&mouse_x, &mouse_y);
                    std.debug.print("Mouse clicked - state: {}, mouse_x: {}, mouse_y: {}\n", .{ mouse_state_output, mouse_x, mouse_y });
                },
                else => {},
            }
        }

        _ = SDL.SDL_SetRenderDrawColor(main_renderer, 0xF7, 0xA4, 0x1D, 0xFF);
        _ = SDL.SDL_RenderClear(main_renderer);

        SDL.SDL_RenderPresent(main_renderer);
    }
}

fn sdlPanic() noreturn {
    const str = @as(?[*:0]const u8, SDL.SDL_GetError()) orelse "unknown error in sdlPanic";
    @panic(std.mem.sliceTo(str, 0));
}
