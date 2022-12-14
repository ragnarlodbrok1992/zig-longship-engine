const std = @import("std");
const SDL = @import("sdl2"); // Add this package by using sdl.getNativePackage

const TITLE_BAR = "Longship Engine - pre-alpha version";
const VERSION = 0;

const RES_WIDTH = 800;
const RES_HEIGHT = 600;

const TILE_CAR_WIDTH = 40;
const TILE_CAR_HEIGHT = 40;
const TILES_NORTH = 50;
const TILES_WEST = 50;
const TILES_COLUMNS = 10;
const TILES_ROWS = 10;

const BLACK = SDL.SDL_Color{ .r = 0x00, .g = 0x00, .b = 0x00, .a = 0xFF };
const WHITE = SDL.SDL_Color{ .r = 0xFF, .g = 0xFF, .b = 0xFF, .a = 0xFF };
const RED = SDL.SDL_Color{ .r = 0xFF, .g = 0x00, .b = 0x00, .a = 0xFF };
const LIME = SDL.SDL_Color{ .r = 0x00, .g = 0xFF, .b = 0x00, .a = 0xFF };
const BLUE = SDL.SDL_Color{ .r = 0x00, .g = 0x00, .b = 0xFF, .a = 0xFF };
const YELLOW = SDL.SDL_Color{ .r = 0xFF, .g = 0xFF, .b = 0x00, .a = 0xFF };
const CYAN = SDL.SDL_Color{ .r = 0x00, .g = 0xFF, .b = 0xFF, .a = 0xFF };
const MAGENTA = SDL.SDL_Color{ .r = 0xFF, .g = 0x00, .b = 0xFF, .a = 0xFF };
const SILVER = SDL.SDL_Color{ .r = 0xC0, .g = 0xC0, .b = 0xC0, .a = 0xFF };
const GRAY = SDL.SDL_Color{ .r = 0x80, .g = 0x80, .b = 0x80, .a = 0xFF };
const MAROON = SDL.SDL_Color{ .r = 0x80, .g = 0x00, .b = 0x00, .a = 0xFF };
const OLIVE = SDL.SDL_Color{ .r = 0x80, .g = 0x80, .b = 0x00, .a = 0xFF };
const GREEN = SDL.SDL_Color{ .r = 0x00, .g = 0x80, .b = 0x00, .a = 0xFF };
const PURPLE = SDL.SDL_Color{ .r = 0x80, .g = 0x00, .b = 0x80, .a = 0xFF };
const TEAL = SDL.SDL_Color{ .r = 0x00, .g = 0x80, .b = 0x80, .a = 0xFF };
const NAVY = SDL.SDL_Color{ .r = 0x00, .g = 0x00, .b = 0x80, .a = 0xFF };

const START_OF_ASCII_NUM = 48;

// Utility functions
pub fn u64ToString(value: u64) []u8 {
    var temp_value = value;

    // Test
    var MAX_INDEX: u32 = @floatToInt(u32, @log10(@intToFloat(f32, value))) + 1;
    // std.debug.print("MAX INDEX: {}\n", .{MAX_INDEX});

    var output = [_]u8{0} ** 16;
    var index: u32 = MAX_INDEX - 1;
    while (temp_value != 0) {
        // std.debug.panic("Before modulo division\n", .{});
        var rest = temp_value % 10;
        temp_value /= 10;
        output[index] = START_OF_ASCII_NUM + @intCast(u8, rest); // Is this bugging out if rest is zero?
        index -= 1;

        // std.debug.print("Casting: {}\n", .{@intCast(u8, rest)});
        // std.debug.print("Rest: {}\n", .{rest});
        // std.debug.print("Temp_value: {}\n", .{temp_value});
    }
    return &output;
}

const Camera = struct {
    offset_x: i32,
    offset_y: i32,
    speed: i32 = 10,
};

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

    pub fn init_points(a: Point, b: Point) Line {
        return Line{
            .a = a,
            .b = b,
        };
    }
};

const IsoTile = struct {
    nw: Point,
    ne: Point,
    sw: Point,
    se: Point,

    line_w: Line,
    line_n: Line,
    line_e: Line,
    line_s: Line,

    color: SDL.SDL_Color,

    pub fn init(n: i32, w: i32, s: i32, e: i32, color: SDL.SDL_Color) IsoTile {
        const nw_point = Point.init(n, w);
        const ne_point = Point.init(n, e);
        const sw_point = Point.init(s, w);
        const se_point = Point.init(s, e);

        return IsoTile{
            .nw = nw_point,
            .ne = ne_point,
            .sw = sw_point,
            .se = se_point,

            .line_w = Line.init_points(sw_point, nw_point),
            .line_n = Line.init_points(nw_point, ne_point),
            .line_e = Line.init_points(ne_point, se_point),
            .line_s = Line.init_points(se_point, sw_point),

            .color = color,
        };
    }

    pub fn init_with_sizes(n: i32, w: i32, width: i32, height: i32, color: SDL.SDL_Color) IsoTile {
        const nw_point = Point.init(n, w);
        const ne_point = Point.init(n, w + width);
        const sw_point = Point.init(n + height, w);
        const se_point = Point.init(n + height, w + width);

        return IsoTile{
            .nw = nw_point,
            .ne = ne_point,
            .sw = sw_point,
            .se = se_point,

            .line_w = Line.init_points(sw_point, nw_point),
            .line_n = Line.init_points(nw_point, ne_point),
            .line_e = Line.init_points(ne_point, se_point),
            .line_s = Line.init_points(se_point, sw_point),

            .color = color,
        };
    }
};

pub fn render_line(renderer: *SDL.SDL_Renderer, camera: *Camera, line: Line, color: SDL.SDL_Color) void {
    _ = SDL.SDL_SetRenderDrawColor(renderer, color.r, color.g, color.b, color.a);
    _ = SDL.SDL_RenderDrawLine(renderer, line.a.x - camera.offset_x, line.a.y - camera.offset_y, line.b.x - camera.offset_x, line.b.y - camera.offset_y);
}

pub fn render_iso_tile(renderer: *SDL.SDL_Renderer, camera: *Camera, iso_tile: IsoTile) void {
    render_line(renderer, camera, iso_tile.line_w, iso_tile.color);
    render_line(renderer, camera, iso_tile.line_n, iso_tile.color);
    render_line(renderer, camera, iso_tile.line_e, iso_tile.color);
    render_line(renderer, camera, iso_tile.line_s, iso_tile.color);
}

pub fn set_render_draw_color(renderer: *SDL.SDL_Renderer, color: SDL.SDL_Color) c_int {
    return SDL.SDL_SetRenderDrawColor(renderer, color.r, color.g, color.b, color.a);
}

pub fn mouseClick() void {}

pub fn main() !void {
    std.debug.print("{s}: {}\n", .{ TITLE_BAR, VERSION });

    // Engine variables for controls
    var mouseDraggingEnabled = false;
    var mouseHasDragged = false;
    var getFirstMouseClickEvent = false;
    var prevFrameMouseX: c_int = undefined;
    var prevFrameMouseY: c_int = undefined;
    var currFrameMouseX: c_int = undefined;
    var currFrameMouseY: c_int = undefined;

    // SDL enabling code
    if (SDL.SDL_Init(SDL.SDL_INIT_VIDEO | SDL.SDL_INIT_EVENTS | SDL.SDL_INIT_AUDIO) < 0)
        sdlPanic();
    defer SDL.SDL_Quit();

    // SDL TTF enabling code
    if (SDL.TTF_Init() < 0)
        sdlPanic();
    defer SDL.TTF_Quit();

    // DEBUG lines to render
    var iso_tiles_matrix: [10][10]IsoTile = undefined;
    var row: usize = 0;

    while (row < TILES_ROWS) : (row += 1) {
        var column: usize = 0;
        while (column < TILES_COLUMNS) : (column += 1) {
            iso_tiles_matrix[column][row] = IsoTile.init_with_sizes(TILES_NORTH + TILE_CAR_HEIGHT * @intCast(i32, row + 1), TILES_WEST + TILE_CAR_WIDTH * @intCast(i32, column + 1), TILE_CAR_WIDTH, TILE_CAR_HEIGHT, MAROON);
        }
    }

    var main_window = SDL.SDL_CreateWindow(
        TITLE_BAR,
        SDL.SDL_WINDOWPOS_CENTERED,
        SDL.SDL_WINDOWPOS_CENTERED,
        RES_WIDTH,
        RES_HEIGHT,
        SDL.SDL_WINDOW_SHOWN,
    ) orelse sdlPanic();
    defer _ = SDL.SDL_DestroyWindow(main_window);

    var main_renderer = SDL.SDL_CreateRenderer(main_window, -1, SDL.SDL_RENDERER_ACCELERATED | SDL.SDL_RENDERER_PRESENTVSYNC) orelse sdlPanic();
    defer _ = SDL.SDL_DestroyRenderer(main_renderer);

    // Create camera
    var camera = Camera{ .offset_x = 0, .offset_y = 0 };
    var old_camera_x: i32 = 0;
    var old_camera_y: i32 = 0;

    // Define mouse state values before loop
    _ = SDL.SDL_GetMouseState(&currFrameMouseX, &currFrameMouseY);
    _ = SDL.SDL_GetMouseState(&prevFrameMouseX, &prevFrameMouseY);

    mainLoop: while (true) {
        // Beggining of a frame
        var ticks_start_of_frame: u64 = SDL.SDL_GetTicks64();

        var ev: SDL.SDL_Event = undefined;
        while (SDL.SDL_PollEvent(&ev) != 0) {
            switch (ev.type) {
                SDL.SDL_QUIT => break :mainLoop,
                SDL.SDL_KEYDOWN => {
                    switch (ev.key.keysym.scancode) {
                        SDL.SDL_SCANCODE_ESCAPE => {
                            break :mainLoop;
                        },
                        SDL.SDL_SCANCODE_W => {
                            camera.offset_y += camera.speed;
                        },
                        SDL.SDL_SCANCODE_A => {
                            camera.offset_x += camera.speed;
                        },
                        SDL.SDL_SCANCODE_S => {
                            camera.offset_y -= camera.speed;
                        },
                        SDL.SDL_SCANCODE_D => {
                            camera.offset_x -= camera.speed;
                        },
                        else => {},
                    }
                },
                SDL.SDL_KEYUP => {},
                SDL.SDL_MOUSEMOTION => {
                    // TODO ragnar: this event is only when mouse is moving
                    _ = SDL.SDL_GetMouseState(&currFrameMouseX, &currFrameMouseY);
                    mouseHasDragged = true;
                },
                SDL.SDL_MOUSEBUTTONDOWN => {
                    mouseDraggingEnabled = true;
                    getFirstMouseClickEvent = true;
                },
                SDL.SDL_MOUSEBUTTONUP => {
                    mouseDraggingEnabled = false;
                },
                else => {
                    mouseHasDragged = false;
                },
            }
        }

        // After getting events - use engine controls
        // Mouse dragging
        if (getFirstMouseClickEvent) {
            prevFrameMouseX = currFrameMouseX;
            prevFrameMouseY = currFrameMouseY;

            old_camera_x = camera.offset_x;
            old_camera_y = camera.offset_y;

            getFirstMouseClickEvent = false;
        }
        if (mouseDraggingEnabled and mouseHasDragged) {
            var mouse_x_diff = old_camera_x + prevFrameMouseX - currFrameMouseX;
            var mouse_y_diff = old_camera_y + prevFrameMouseY - currFrameMouseY;

            camera.offset_x = mouse_x_diff;
            camera.offset_y = mouse_y_diff;
        }

        // Render clear screen
        _ = set_render_draw_color(main_renderer, BLACK);
        _ = SDL.SDL_RenderClear(main_renderer);

        // Render isotile
        for (iso_tiles_matrix) |iso_tile_row| {
            for (iso_tile_row) |iso_tile| {
                render_iso_tile(main_renderer, &camera, iso_tile);
            }
        }

        SDL.SDL_RenderPresent(main_renderer);

        // End of a frame
        var ticks_end_of_frame: u64 = SDL.SDL_GetTicks64();
        var ticks_diff: u64 = ticks_end_of_frame - ticks_start_of_frame;
        var ticks_diff_div_1000: f64 = @intToFloat(f64, ticks_diff);
        var FPS: u64 = @floatToInt(u64, 1 / (ticks_diff_div_1000 / 1000));

        // std.debug.print("Ticks of frame: {}\n", .{ticks_diff});
        // std.debug.print("FPS: {}\n", .{FPS});
        // @Fix: TODO this should be done better
        // var gowno = @intToPtr(u64, FPS);
        // std.debug.print("{}\n", .{gowno});
        // const title_bar_by_frame = TITLE_BAR ++ u64ToString(FPS); // ++ @intToPtr(u64, FPS);
        std.debug.print("stringified u64: {s}\n", .{u64ToString(FPS)});
        const title_bar_by_frame = TITLE_BAR;
        SDL.SDL_SetWindowTitle(main_window, title_bar_by_frame);
    }
}

fn sdlPanic() noreturn {
    const str = @as(?[*:0]const u8, SDL.SDL_GetError()) orelse "unknown error in sdlPanic";
    @panic(std.mem.sliceTo(str, 0));
}
