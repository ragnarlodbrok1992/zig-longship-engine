const std = @import("std");
const SDL = @import("sdl2"); // Add this package by using sdl.getNativePackage
// const fmt = std.fmt;

const TITLE_BAR: [*:0]const u8 = "Longship Engine - pre-alpha version. ";
const VERSION = 0;

const RES_WIDTH = 800;
const RES_HEIGHT = 600;

const TILE_CAR_WIDTH = 20;
const TILE_CAR_HEIGHT = 20;
const TILES_NORTH = 50;
const TILES_WEST = 50;
const TILES_COLUMNS = 40;
const TILES_ROWS = 40;

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
    var MAX_INDEX: u32 = @floatToInt(u32, @log10(@intToFloat(f32, value))) + 1;
    var output = [_]u8{0} ** 16;
    var index: u32 = MAX_INDEX - 1;
    while (temp_value != 0) {
        var rest = temp_value % 10;
        temp_value /= 10;
        output[index] = START_OF_ASCII_NUM + @intCast(u8, rest); // Is this bugging out if rest is zero?
        if (index != 0) index -= 1;
    }
    return &output;
}

pub fn updateTitleBarFPS(ticks_start_frame: u64, ticks_end_frame: u64, title_bar_i: usize, title_bar_memory: []u8, main_window: *SDL.SDL_Window) void {
    var ticks_diff: u64 = ticks_end_frame - ticks_start_frame;
    var ticks_diff_div_1000: f64 = @intToFloat(f64, ticks_diff);
    var FPS: u64 = @floatToInt(u64, 1 / (ticks_diff_div_1000 / 1000));
    var FPS_string = u64ToString(FPS);
    var char: u8 = 'A';
    // TODO ragnar: this concatenation can be moved to another function
    var i: usize = 0;
    while (char != 0) : (i += 1) {
        char = FPS_string[i];
    }
    var FPS_string_slice = FPS_string[0..i];
    var k: usize = 0;
    var j: usize = title_bar_i;
    while (j < title_bar_i + i) : (j += 1) {
        title_bar_memory[j] = FPS_string_slice[k];
        k += 1;
    }
    const title_bar_memory_slice = title_bar_memory[0..128];
    SDL.SDL_SetWindowTitle(main_window, title_bar_memory_slice);
}

pub fn initRotateGrid(angle: f64, grid: *[TILES_ROWS][TILES_COLUMNS]IsoTile) [TILES_ROWS][TILES_COLUMNS]IsoTile {
    // 1 --> 2 --> N --> x axis
    // v y axis

    // var grid_mut = grid;
    var return_grid: [TILES_ROWS][TILES_COLUMNS]IsoTile = undefined;
    var sin = @sin(angle);
    var cos = @cos(angle);

    for (grid) |row, row_index| {
        for (row) |iso_tile, column_index| {
            var iso_tile_mut = iso_tile;

            var old_nw_x = iso_tile.nw.x;
            var old_ne_x = iso_tile.ne.x;
            var old_se_x = iso_tile.se.x;
            var old_sw_x = iso_tile.sw.x;

            // TODO ragnar: fix bug - cannot assign to a constant
            iso_tile_mut.nw.x = @floatToInt(i32, cos * @intToFloat(f64, old_nw_x) - sin * @intToFloat(f64, iso_tile_mut.nw.y));
            iso_tile_mut.nw.y = @floatToInt(i32, cos * @intToFloat(f64, iso_tile_mut.nw.y) + sin * @intToFloat(f64, old_nw_x));

            iso_tile_mut.ne.x = @floatToInt(i32, cos * @intToFloat(f64, old_ne_x) - sin * @intToFloat(f64, iso_tile_mut.ne.y));
            iso_tile_mut.ne.y = @floatToInt(i32, cos * @intToFloat(f64, iso_tile_mut.ne.y) + sin * @intToFloat(f64, old_ne_x));

            iso_tile_mut.se.x = @floatToInt(i32, cos * @intToFloat(f64, old_se_x) - sin * @intToFloat(f64, iso_tile_mut.se.y));
            iso_tile_mut.se.y = @floatToInt(i32, cos * @intToFloat(f64, iso_tile_mut.se.y) + sin * @intToFloat(f64, old_se_x));

            iso_tile_mut.sw.x = @floatToInt(i32, cos * @intToFloat(f64, old_sw_x) - sin * @intToFloat(f64, iso_tile_mut.sw.y));
            iso_tile_mut.sw.y = @floatToInt(i32, cos * @intToFloat(f64, iso_tile_mut.sw.y) + sin * @intToFloat(f64, old_sw_x));

            // TODO FIXME ragnar: changing points doesn't change created line
            // TODO ragnar: add function to modify lines with new points

            iso_tile_mut.line_w = Line.init(iso_tile_mut.nw.x, iso_tile_mut.nw.y, iso_tile_mut.sw.x, iso_tile_mut.sw.y);
            iso_tile_mut.line_n = Line.init(iso_tile_mut.nw.x, iso_tile_mut.nw.y, iso_tile_mut.ne.x, iso_tile_mut.ne.y);
            iso_tile_mut.line_e = Line.init(iso_tile_mut.ne.x, iso_tile_mut.ne.y, iso_tile_mut.se.x, iso_tile_mut.se.y);
            iso_tile_mut.line_s = Line.init(iso_tile_mut.se.x, iso_tile_mut.se.y, iso_tile_mut.sw.x, iso_tile_mut.sw.y);

            return_grid[row_index][column_index] = iso_tile_mut;
        }
    }
    return return_grid;
}

// TODO ragnar: tilt the grid to look isometric
pub fn initTiltGrid(grid: *[TILES_ROWS][TILES_COLUMNS]IsoTile) [TILES_ROWS][TILES_COLUMNS]IsoTile {
    var return_grid: [TILES_ROWS][TILES_COLUMNS]IsoTile = undefined;

    for (grid) |row, row_index| {
        for (row) |iso_tile, column_index| {
            // TODO ragnar: do some stuff here
            // std.debug.print("Tilting grid", .{});
            // std.debug.print("Iso_tile: {any}, row_index: {any}, column_index: {any}\n\n", .{ iso_tile, row_index, column_index });
            _ = iso_tile;
            _ = row_index;
            _ = column_index;
        }
    }
    return return_grid;
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
    id: u64,

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
        var nw_point = Point.init(n, w);
        var ne_point = Point.init(n, e);
        var sw_point = Point.init(s, w);
        var se_point = Point.init(s, e);

        return IsoTile{
            .id = undefined,

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
        var nw_point = Point.init(n, w);
        var ne_point = Point.init(n, w + width);
        var sw_point = Point.init(n + height, w);
        var se_point = Point.init(n + height, w + width);

        return IsoTile{
            .id = undefined,

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

    // Allocate memory for a title bar string and other dynamic one
    // Title bar string is compose of static const value from comptime
    // And a calculate frame FPS value from runtime
    var main_loop_arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer main_loop_arena.deinit();
    const main_loop_arena_allocator = main_loop_arena.allocator();

    // Allocate stuff here
    const title_bar_memory = try main_loop_arena_allocator.alloc(u8, 128);
    var title_bar_i: usize = 0;
    while (TITLE_BAR[title_bar_i] != 0) : (title_bar_i += 1) {
        title_bar_memory[title_bar_i] = TITLE_BAR[title_bar_i];
    }
    title_bar_memory[title_bar_i] = 0; // TODO ragnar: fix this. Null terminating the TITLE BAR string for now.
    defer main_loop_arena_allocator.free(title_bar_memory);

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
    var iso_tiles_matrix: [TILES_ROWS][TILES_COLUMNS]IsoTile = undefined;
    var id: usize = 0;
    var row: usize = 0;

    while (row < TILES_ROWS) : (row += 1) {
        var column: usize = 0;
        while (column < TILES_COLUMNS) : (column += 1) {
            iso_tiles_matrix[row][column] = IsoTile.init_with_sizes(TILES_NORTH + TILE_CAR_HEIGHT * @intCast(i32, column + 1), TILES_WEST + TILE_CAR_WIDTH * @intCast(i32, row + 1), TILE_CAR_WIDTH, TILE_CAR_HEIGHT, MAROON);
            iso_tiles_matrix[row][column].id = id;
            id += 1;
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

    // TTF stuff
    // Font stuff here
    // TODO moliwa: something has to be done with this, this might be an option
    std.debug.print("CWD: {s}\n", .{
        try std.fs.cwd().realpathAlloc(main_loop_arena_allocator, "."),
    });
    const Arial: *SDL.TTF_Font = SDL.TTF_OpenFont("Roboto-Regular.ttf", 12) orelse @panic("Cannot find font!");
    defer SDL.TTF_CloseFont(Arial);
    var test_text_surface: *SDL.SDL_Surface = SDL.TTF_RenderText_Solid(Arial, "Test text 1234567890 :)", WHITE) orelse @panic("Cannot create test_text_surface!");

    // Converting text surface to texture
    var test_text_texture = SDL.SDL_CreateTextureFromSurface(main_renderer, test_text_surface);

    // Rotate grid
    var rotate_angle: f64 = 3.14 / 4.0;
    var new_iso_tiles_rot = initRotateGrid(rotate_angle, &iso_tiles_matrix);
    var new_iso_tiles_tilted = initTiltGrid(&new_iso_tiles_rot);
    _ = new_iso_tiles_tilted;

    // Define mouse state values before loop
    _ = SDL.SDL_GetMouseState(&currFrameMouseX, &currFrameMouseY);
    _ = SDL.SDL_GetMouseState(&prevFrameMouseX, &prevFrameMouseY);

    // Control frames for poor man's callback
    var update_title_bar_ticks: u64 = 0;

    // Render text
    var text_rect: SDL.SDL_Rect = undefined;
    text_rect.x = 120;
    text_rect.y = 120;
    text_rect.w = 100;
    text_rect.h = 20;

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
        // for (new_iso_tiles_tilted) |iso_tile_row| {
        for (new_iso_tiles_rot) |iso_tile_row| {
            for (iso_tile_row) |iso_tile| {
                render_iso_tile(main_renderer, &camera, iso_tile);
            }
        }

        _ = SDL.SDL_RenderCopy(main_renderer, test_text_texture, null, &text_rect);

        SDL.SDL_RenderPresent(main_renderer);

        // End of a frame
        var ticks_end_of_frame: u64 = SDL.SDL_GetTicks64();
        var ticks_diff: u64 = ticks_end_of_frame - ticks_start_of_frame;
        update_title_bar_ticks += ticks_diff;

        // std.debug.print("{}\n", .{ticks_end_of_frame});
        // Moved to function
        // TODO ragnar: make SDL call this function every half of second or something
        if (update_title_bar_ticks > 500) {
            updateTitleBarFPS(ticks_start_of_frame, ticks_end_of_frame, title_bar_i, title_bar_memory, main_window);
            update_title_bar_ticks = 0;
        }
    }
}

fn sdlPanic() noreturn {
    const str = @as(?[*:0]const u8, SDL.SDL_GetError()) orelse "unknown error in sdlPanic";
    @panic(std.mem.sliceTo(str, 0));
}
