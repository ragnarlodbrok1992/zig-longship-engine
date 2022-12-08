const std = @import("std");
const SDL = @import("sdl2"); // Add this package by using sdl.getNativePackage

const TITLE_BAR = "Longship Engine - pre-alpha version";
const VERSION = 0;

const RES_WIDTH = 800;
const RES_HEIGHT = 600;

const SDL_SCANCODE_ESCAPE: c_int = 41;

const Point = struct {
    x: i32,
    y: i32,

    pub fn init(x: i32, y: i32) Point {
        return Point{
            .x = x,
            .y = y,
        };
    }
};

const Line = struct {
    a: Point,
    b: Point,

    pub fn init(ax: i32, ay: i32, bx: i32, by: i32) Line {
        return Line{
            .a = Point.init(ax, ay),
            .b = Point.init(bx, by),
        };
    }
};

pub fn mouseClick() void {}

pub fn renderLine(renderer: *SDL.SDL_Renderer, line: Line, color: SDL.SDL_Color) void {
    _ = SDL.SDL_SetRenderDrawColor(renderer, color.r, color.g, color.b, color.a);
    _ = SDL.SDL_RenderDrawLine(renderer, line.a.x, line.a.y, line.b.x, line.b.y);
}

pub fn main() !void {
    std.debug.print("{s}: {}\n", .{ TITLE_BAR, VERSION });

    // SDL enabling code
    if (SDL.SDL_Init(SDL.SDL_INIT_VIDEO | SDL.SDL_INIT_EVENTS | SDL.SDL_INIT_AUDIO) < 0)
        sdlPanic();
    defer SDL.SDL_Quit();

    // SDL TTF enabling code
    if (SDL.TTF_Init() < 0)
        sdlPanic();
    defer SDL.TTF_Quit();

    // DEBUG lines to render
    const test_line = Line.init(100, 100, 200, 200);
    const test_color = SDL.SDL_Color{ .r = 255, .g = 255, .b = 0, .a = 0 };

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

                    // Debug - checking SDL state - timestamp
                    // std.debug.print("Event timestamp: {}\n", .{ev.user.timestamp});
                    // SDL_GetTicks64 is a better function
                    // TODO ragnar: check if this value can be bound to system time
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

        // Render clear screen
        _ = SDL.SDL_SetRenderDrawColor(main_renderer, 0xF7, 0xA4, 0x1D, 0xFF);
        _ = SDL.SDL_RenderClear(main_renderer);

        // Render lines
        renderLine(main_renderer, test_line, test_color);

        SDL.SDL_RenderPresent(main_renderer);
    }
}

fn sdlPanic() noreturn {
    const str = @as(?[*:0]const u8, SDL.SDL_GetError()) orelse "unknown error in sdlPanic";
    @panic(std.mem.sliceTo(str, 0));
}
