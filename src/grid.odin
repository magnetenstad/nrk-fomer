#+vet unused shadowing using-stmt style semicolon
package main
import "core:math/rand"
import "core:strings"
import rl "vendor:raylib"

Grid :: [GRID_ROWS][GRID_COLUMNS]CellKind

Game :: struct {
	rows:     Grid,
	hover:    IVec2,
	clicks:   int,
	best:     int,
	attempts: int,
}

Node :: struct {
	h:    f32,
	hash: string,
	cost: int,
}

CellKind :: enum {
	Empty = '-',
	Gree  = 'G',
	Blue  = 'B',
	Oran  = 'O',
	Pink  = 'P',
}

cell_kind_color := map[CellKind]rl.Color {
	.Empty = {24, 5, 46, 255},
	.Gree  = {93, 196, 121, 255},
	.Blue  = {53, 177, 231, 255},
	.Oran  = {255, 156, 84, 255},
	.Pink  = {249, 88, 171, 255},
}

grid_init :: proc(grid: ^Game) {
	grid.clicks = 0
	for &row in grid.rows {
		for &cell in row {
			cell = rand.choice_enum(CellKind)
		}
	}
	grid_apply_gravity(&grid.rows)
}

grid_set :: proc(grid: ^Game) {
	grid_init(grid)

	grid.rows = {
		{.Empty, .Empty, .Empty, .Empty, .Empty, .Empty, .Empty},
		{.Empty, .Empty, .Empty, .Empty, .Empty, .Empty, .Empty},
		{.Empty, .Empty, .Empty, .Empty, .Empty, .Empty, .Empty},
		{.Empty, .Empty, .Empty, .Empty, .Empty, .Empty, .Empty},
		{.Empty, .Empty, .Empty, .Empty, .Empty, .Empty, .Empty},
		{.Empty, .Empty, .Empty, .Empty, .Empty, .Empty, .Empty},
		{.Pink, .Pink, .Oran, .Blue, .Blue, .Pink, .Pink},
		{.Oran, .Blue, .Oran, .Oran, .Pink, .Pink, .Blue},
		{.Pink, .Pink, .Pink, .Gree, .Pink, .Gree, .Gree},
		// {.Pink, .Gree, .Pink, .Gree, .Gree, .Blue, .Oran},
		// {.Oran, .Pink, .Oran, .Gree, .Blue, .Gree, .Blue},
		// {.Blue, .Gree, .Oran, .Gree, .Gree, .Gree, .Oran},
		// {.Oran, .Pink, .Pink, .Pink, .Blue, .Gree, .Blue},
		// {.Pink, .Blue, .Blue, .Blue, .Gree, .Blue, .Oran},
		// {.Pink, .Oran, .Pink, .Oran, .Gree, .Blue, .Blue},
	}
}

grid_apply_gravity :: proc(rows: ^Grid) {
	for y := GRID_ROWS - 1; y >= 1; y -= 1 {
		for x in 0 ..< GRID_COLUMNS {
			if rows[y][x] == CellKind.Empty {
				for _y := y - 1; _y >= 0; _y -= 1 {
					if rows[_y][x] != CellKind.Empty {
						rows[y][x] = rows[_y][x]
						rows[_y][x] = CellKind.Empty
						break
					}
				}
			}
		}
	}
}

grid_step :: proc(grid: ^Game) {
	if rl.IsMouseButtonPressed(.LEFT) {
		if grid.rows[grid.hover.y][grid.hover.x] == CellKind.Empty {
			return
		}
		grid.clicks += 1
		grid_flood_empty(&grid.rows, grid.hover)
		grid_apply_gravity(&grid.rows)
	}

	position := IVec2 {
		int(rand.int31_max(GRID_COLUMNS)),
		int(rand.int31_max(GRID_ROWS)),
	}
	for grid.rows[position.y][position.x] == CellKind.Empty {
		position = IVec2 {
			int(rand.int31_max(GRID_COLUMNS)),
			int(rand.int31_max(GRID_ROWS)),
		}
	}
	grid.clicks += 1
	grid_flood_empty(&grid.rows, position)
	grid_apply_gravity(&grid.rows)

	blocks := 0
	for row in grid.rows {
		for cell in row {
			if cell != CellKind.Empty {
				blocks += 1
			}
		}
	}
	if blocks == 0 {
		grid.attempts += 1
		if grid.best == 0 || grid.clicks < grid.best {
			grid.best = grid.clicks
			print("Found", grid.best, "in", grid.attempts, "tries.")
		}
		grid_set(grid)
	}
}

grid_flood_empty :: proc(rows: ^Grid, position: IVec2) {
	kind := rows[position.y][position.x]
	if kind == CellKind.Empty {return}

	rows[position.y][position.x] = CellKind.Empty

	if position.x > 0 && rows[position.y][position.x - 1] == kind {
		grid_flood_empty(rows, position + {-1, 0})
	}
	if position.x < GRID_COLUMNS - 1 &&
	   rows[position.y][position.x + 1] == kind {
		grid_flood_empty(rows, position + {1, 0})
	}
	if position.y > 0 && rows[position.y - 1][position.x] == kind {
		grid_flood_empty(rows, position + {0, -1})
	}
	if position.y < GRID_ROWS - 1 && rows[position.y + 1][position.x] == kind {
		grid_flood_empty(rows, position + {0, 1})
	}
}

grid_draw :: proc(grid: ^Game) {
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
				cell_kind_color[grid.rows[y][x]],
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

grid_draw_gui :: proc(grid: ^Game) {
	draw_text(format(grid.clicks), {32, 64})
	draw_text(format(grid.best), {32, 128})
}

heap_less :: proc(a: Node, b: Node) -> bool {
	return a.h < b.h
}

branch_and_bound_search :: proc(grid_0: ^Grid) -> int {

	hash_0 := grid_to_hash(grid_0)

	map_grids := map[string]Grid{}
	map_grids[hash_0] = grid_0^
	defer delete(map_grids)
	map_click_options := map[string][dynamic]IVec2{}
	map_click_options[hash_0] = grid_region_options(grid_0^)
	defer delete(map_click_options)
	map_rest_lower_bound := map[string]int{}
	map_rest_lower_bound[hash_0] = get_lower_bound(grid_0^)
	defer delete(map_rest_lower_bound)

	lower_bound := get_lower_bound(grid_0^)
	upper_bound := get_upper_bound(grid_0^)
	print(lower_bound, upper_bound)

	array := make([dynamic]Node, 1)
	array[0] = Node {
		cost = 0,
		hash = hash_0,
		h    = 0,
	}
	heap := build_min_heap(array, heap_less)
	defer delete(array)

	for len(heap.array) > 0 && lower_bound != upper_bound {

		node := pop(&heap)
		print(node.hash, node.cost, node.h)
		for n in heap.array {
			print(n)
		}

		grid := map_grids[node.hash]
		click_options := map_click_options[node.hash]
		rest_lower_bound := map_rest_lower_bound[node.hash]

		if node.cost + rest_lower_bound >= upper_bound {
			continue
		}

		for pos in click_options {
			grid_next := grid
			grid_flood_empty(&grid_next, pos)
			grid_apply_gravity(&grid_next)
			hash_next := grid_to_hash(&grid_next)
			if hash_next in map_grids {
				continue
			}
			map_grids[hash_next] = grid_next

			click_options_next := grid_region_options(grid_next)
			map_click_options[hash_next] = click_options_next

			cost_next := node.cost + 1

			if len(click_options_next) == 0 {
				if cost_next < upper_bound {
					print("Found", cost_next)
					upper_bound = cost_next
					return upper_bound
				}
				continue
			}

			rest_lower_bound_next := get_lower_bound(grid_next)
			map_rest_lower_bound[hash_next] = rest_lower_bound_next

			h: f32 = 0
			h += f32(rest_lower_bound_next)
			h += f32(len(click_options_next))
			h /= f32(upper_bound - cost_next)

			node_next := Node {
				hash = hash_next,
				cost = cost_next,
				h    = h,
			}

			if cost_next + rest_lower_bound_next >= upper_bound {
				continue
			}

			push(&heap, node_next)
		}
	}

	return upper_bound
}

grid_region_options :: proc(rows: Grid) -> [dynamic]IVec2 {
	options := make([dynamic]IVec2)
	rows := rows

	for y in 0 ..< GRID_ROWS {
		for x in 0 ..< GRID_COLUMNS {
			if rows[y][x] != CellKind.Empty {
				pos := IVec2{x, y}
				append(&options, pos)
				grid_flood_empty(&rows, pos)
			}
		}
	}
	return options
}

get_lower_bound :: proc(rows: Grid) -> int {
	lower_bound := 0

	for kind in CellKind {
		if kind == CellKind.Empty {continue}
		in_last_col := false

		for x in 0 ..< GRID_COLUMNS {
			in_this_col := false

			for y in 0 ..< GRID_ROWS {
				if rows[y][x] == kind {
					if !in_last_col && !in_this_col {
						lower_bound += 1
					}
					in_this_col = true
				}
			}

			in_last_col = in_this_col
		}
	}

	return lower_bound
}


get_upper_bound :: proc(grid: Grid) -> int {
	return len(grid_region_options(grid))
}

grid_to_hash :: proc(rows: ^Grid) -> string {
	hash := strings.Builder{}

	for y in 0 ..< GRID_ROWS {
		for x in 0 ..< GRID_COLUMNS {
			cell := rows[y][x]
			strings.write_byte(&hash, u8(cell))
		}
		strings.write_byte(&hash, ' ')
	}

	return strings.to_string(hash)
}

// grid_from_hash :: proc(hash: string) -> Grid {
// 	rows := [GRID_ROWS][GRID_COLUMNS]CellKind{}

// 	for y in 0 ..< GRID_ROWS {
// 		for x in 0 ..< GRID_COLUMNS {
// 			cell := hash[y * GRID_COLUMNS + x]
// 			rows[y][x] = CellKind(cell)
// 		}
// 	}

// 	return rows
// }
