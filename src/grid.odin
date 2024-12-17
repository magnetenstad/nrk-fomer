#+vet unused shadowing using-stmt style semicolon
package main
import "core:math/rand"
import "core:strings"
import rl "vendor:raylib"

Grid :: struct {
	rows:     [GRID_ROWS][GRID_COLUMNS]CellKind,
	hover:    IVec2,
	clicks:   int,
	best:     int,
	attempts: int,
}

CellKind :: enum {
	Empty = '-',
	Gree  = 'G',
	Blue  = 'B',
	Oran  = 'O',
	Pink  = 'P',
}

cell_color := map[CellKind]rl.Color {
	.Empty = {24, 5, 46, 255},
	.Gree  = {93, 196, 121, 255},
	.Blue  = {53, 177, 231, 255},
	.Oran  = {255, 156, 84, 255},
	.Pink  = {249, 88, 171, 255},
}

grid_init :: proc(grid: ^Grid) {
	grid.clicks = 0
	for &row in grid.rows {
		for &cell in row {
			cell = rand.choice_enum(CellKind)
		}
	}
	grid_apply_gravity(grid)
}

grid_set :: proc(grid: ^Grid) {
	grid_init(grid)

	grid.rows = {
		{.Pink, .Pink, .Oran, .Blue, .Blue, .Pink, .Pink},
		{.Oran, .Blue, .Oran, .Oran, .Pink, .Pink, .Blue},
		{.Pink, .Pink, .Pink, .Gree, .Pink, .Gree, .Gree},
		{.Pink, .Gree, .Pink, .Gree, .Gree, .Blue, .Oran},
		{.Oran, .Pink, .Oran, .Gree, .Blue, .Gree, .Blue},
		{.Blue, .Gree, .Oran, .Gree, .Gree, .Gree, .Oran},
		{.Oran, .Pink, .Pink, .Pink, .Blue, .Gree, .Blue},
		{.Pink, .Blue, .Blue, .Blue, .Gree, .Blue, .Oran},
		{.Pink, .Oran, .Pink, .Oran, .Gree, .Blue, .Blue},
	}
}

grid_apply_gravity :: proc(grid: ^Grid) {
	for y := GRID_ROWS - 1; y >= 1; y -= 1 {
		for x in 0 ..< GRID_COLUMNS {
			if grid.rows[y][x] == CellKind.Empty {
				for _y := y - 1; _y >= 0; _y -= 1 {
					if grid.rows[_y][x] != CellKind.Empty {
						grid.rows[y][x] = grid.rows[_y][x]
						grid.rows[_y][x] = CellKind.Empty
						break
					}
				}
			}
		}
	}
}

grid_to_hash :: proc(grid: ^Grid) -> string {
	hash := strings.Builder{}

	for y in 0 ..< GRID_ROWS {
		for x in 0 ..< GRID_COLUMNS {
			cell := grid.rows[y][x]
			strings.write_byte(&hash, u8(cell))
		}
		strings.write_byte(&hash, ' ')
	}

	return strings.to_string(hash)
}

grid_step :: proc(grid: ^Grid) {
	if rl.IsMouseButtonPressed(.LEFT) {
		if grid.rows[grid.hover.y][grid.hover.x] == CellKind.Empty {
			return
		}
		grid.clicks += 1
		grid_flood_empty(grid, grid.hover)
		grid_apply_gravity(grid)

		hash := grid_to_hash(grid)
		print(hash)
	}

	// position := IVec2 {
	// 	int(rand.int31_max(GRID_COLUMNS)),
	// 	int(rand.int31_max(GRID_ROWS)),
	// }
	// for grid.rows[position.y][position.x] == CellKind.Empty {
	// 	position = IVec2 {
	// 		int(rand.int31_max(GRID_COLUMNS)),
	// 		int(rand.int31_max(GRID_ROWS)),
	// 	}
	// }
	// grid.clicks += 1
	// grid_flood_empty(grid, position)
	// grid_apply_gravity(grid)

	// blocks := 0
	// for row in grid.rows {
	// 	for cell in row {
	// 		if cell != CellKind.Empty {
	// 			blocks += 1
	// 		}
	// 	}
	// }
	// if blocks == 0 {
	// 	grid.attempts += 1
	// 	if grid.best == 0 || grid.clicks < grid.best {
	// 		grid.best = grid.clicks
	// 		print("Found", grid.best, "in", grid.attempts, "tries.")
	// 	}
	// 	grid_set(grid)
	// }
}

grid_flood_empty :: proc(grid: ^Grid, position: IVec2) {
	kind := grid.rows[position.y][position.x]
	if kind == CellKind.Empty {return}

	grid.rows[position.y][position.x] = CellKind.Empty

	if position.x > 0 && grid.rows[position.y][position.x - 1] == kind {
		grid_flood_empty(grid, position + {-1, 0})
	}
	if position.x < GRID_COLUMNS - 1 &&
	   grid.rows[position.y][position.x + 1] == kind {
		grid_flood_empty(grid, position + {1, 0})
	}
	if position.y > 0 && grid.rows[position.y - 1][position.x] == kind {
		grid_flood_empty(grid, position + {0, -1})
	}
	if position.y < GRID_ROWS - 1 &&
	   grid.rows[position.y + 1][position.x] == kind {
		grid_flood_empty(grid, position + {0, 1})
	}
}

grid_draw :: proc(grid: ^Grid) {
	for y in 0 ..< GRID_ROWS {
		for x in 0 ..< GRID_COLUMNS {
			graphics := &get_game_state().graphics
			surface_position := camera_world_to_surface(
				&graphics.camera,
				IVec2{x, y},
			)

			rl.DrawRectangle(
				i32(surface_position.x),
				i32(surface_position.y),
				GRID_SIZE,
				GRID_SIZE,
				cell_color[grid.rows[y][x]],
			)
			mouse_position := camera_world_mouse_position(
				&get_game_state().graphics.camera,
			)

			if mouse_position == {x, y} {
				grid.hover = mouse_position
			}
		}
	}
}

grid_draw_gui :: proc(grid: ^Grid) {
	draw_text(format(grid.clicks), {32, 64})
	draw_text(format(grid.best), {32, 128})
}
