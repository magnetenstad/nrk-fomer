#+vet unused shadowing using-stmt style semicolon
package main
import "core:math/rand"
import "core:slice"
import "core:strings"
import rl "vendor:raylib"

Grid :: [GRID_ROWS][GRID_COLUMNS]CellKind

Grid_Game :: struct {
	rows:     Grid,
	hover:    IVec2,
	clicks:   int,
	best:     int,
	attempts: int,
	solution: []IVec2,
}

Node :: struct {
	h:    f64,
	hash: string,
}

Node_Info :: struct {
	hash:             string,
	hash_prev:        string,
	grid:             Grid,
	cost:             int,
	options:          []IVec2,
	rest_lower_bound: int,
	pos:              IVec2,
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

grid_init :: proc(grid: ^Grid_Game) {
	grid.clicks = 0
	choices := []CellKind{.Gree, .Blue, .Oran, .Pink}
	for &row in grid.rows {
		for &cell in row {
			cell = rand.choice(choices)
		}
	}
	grid_apply_gravity(&grid.rows)
}

grid_set :: proc(grid: ^Grid_Game) {
	grid_init(grid)

	grid.rows = { 	// blue
		{.Blue, .Blue, .Blue, .Blue, .Blue, .Blue, .Blue},
		{.Blue, .Blue, .Blue, .Blue, .Blue, .Blue, .Blue},
		{.Blue, .Blue, .Blue, .Blue, .Blue, .Blue, .Blue},
		{.Blue, .Blue, .Blue, .Blue, .Blue, .Blue, .Blue},
		{.Blue, .Blue, .Blue, .Blue, .Blue, .Blue, .Blue},
		{.Blue, .Blue, .Blue, .Blue, .Blue, .Blue, .Blue},
		{.Blue, .Blue, .Blue, .Blue, .Blue, .Blue, .Blue},
		{.Blue, .Blue, .Blue, .Blue, .Blue, .Blue, .Blue},
		{.Blue, .Blue, .Blue, .Blue, .Blue, .Blue, .Blue},
	}

	grid.rows = { 	// 17.12.24
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

	grid.rows = { 	// 18.12.24
		{.Gree, .Pink, .Pink, .Gree, .Pink, .Gree, .Gree},
		{.Blue, .Oran, .Pink, .Gree, .Blue, .Pink, .Pink},
		{.Gree, .Blue, .Oran, .Gree, .Oran, .Gree, .Blue},
		{.Blue, .Blue, .Oran, .Oran, .Pink, .Oran, .Gree},
		{.Blue, .Oran, .Gree, .Pink, .Gree, .Oran, .Oran},
		{.Blue, .Gree, .Pink, .Blue, .Blue, .Oran, .Pink},
		{.Oran, .Blue, .Blue, .Oran, .Blue, .Oran, .Blue},
		{.Pink, .Pink, .Pink, .Gree, .Blue, .Blue, .Oran},
		{.Gree, .Gree, .Pink, .Oran, .Oran, .Blue, .Pink},
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

grid_step :: proc(grid: ^Grid_Game) {
	// if rl.IsMouseButtonPressed(.LEFT) {
	// 	if grid.rows[grid.hover.y][grid.hover.x] == CellKind.Empty {
	// 		return
	// 	}
	// 	grid.clicks += 1
	// 	grid_flood_empty(&grid.rows, grid.hover)
	// 	grid_apply_gravity(&grid.rows)
	// }

	if grid.solution == nil || len(grid.solution) == 0 {
		grid.solution = branch_and_bound_search(&grid.rows)
	}

	if grid.solution == nil || len(grid.solution) == 0 {
		return
	}

	if !rl.IsMouseButtonPressed(.LEFT) {
		return
	}

	position := grid.solution[0]
	grid.solution = grid.solution[1:]

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
		grid_init(grid)
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

grid_draw :: proc(grid: ^Grid_Game) {
	graphics := &get_game_state().graphics

	for y in 0 ..< GRID_ROWS {
		for x in 0 ..< GRID_COLUMNS {
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

	if grid.solution != nil && len(grid.solution) > 0 {
		surface_position := camera_world_to_surface(
			&graphics.camera,
			grid.solution[0],
		)
		rl.DrawRectangleLines(
			i32(surface_position.x),
			i32(surface_position.y),
			GRID_SIZE,
			GRID_SIZE,
			cell_kind_color[CellKind.Empty],
		)
	}
}

grid_draw_gui :: proc(grid: ^Grid_Game) {
	draw_text(format(grid.clicks), {32, 64})
	draw_text(format(grid.best), {32, 128})
}

heap_less :: proc(a: Node, b: Node) -> bool {
	return a.h < b.h
}

branch_and_bound_search :: proc(grid_0: ^Grid) -> []IVec2 {
	hash_0 := grid_to_hash(grid_0, 0)

	histogram := map[int]int{}
	defer delete(histogram)

	node_infos := map[string]Node_Info{}
	node_infos[hash_0] = Node_Info {
		hash      = hash_0,
		hash_prev = "",
		cost      = 0,
		grid      = grid_0^,
		options   = grid_region_options(grid_0^),
		// rest_lower_bound = get_lower_bound(grid_0^),
	}
	defer delete(node_infos)

	lower_bound := get_lower_bound(grid_0^)
	upper_bound := get_upper_bound(grid_0^)
	upper_bound_0 := upper_bound
	print(lower_bound, upper_bound)

	heap := build_min_heap(make([dynamic]Node, 1), heap_less)
	heap.array[0] = Node {
		h    = 0,
		hash = hash_0,
	}
	defer delete(heap.array)

	for len(heap.array) > 0 && lower_bound != upper_bound {

		node_hash := pop(&heap)
		node := node_infos[node_hash.hash]

		if node.cost not_in histogram {
			histogram[node.cost] = 0
		}
		histogram[node.cost] += 1

		// print(node.hash, node.cost, node_hash.h, node.click_prev)

		// if node.cost + node.rest_lower_bound >= upper_bound {
		// 	continue
		// }

		for pos in node.options {
			grid_next := node.grid
			grid_flood_empty(&grid_next, pos)
			grid_apply_gravity(&grid_next)
			hash_next := grid_to_hash(&grid_next, node.cost + 1)
			if hash_next in node_infos {
				continue
			}
			node_next := Node_Info {
				hash      = hash_next,
				hash_prev = node.hash,
				cost      = node.cost + 1,
				grid      = grid_next,
				options   = grid_region_options(grid_next),
				// rest_lower_bound = get_lower_bound(grid_next),
				pos       = pos,
			}
			node_infos[hash_next] = node_next

			if len(node_next.options) == 0 {
				if node_next.cost < upper_bound {
					print("Found", node_next.cost)
					print(len(heap.array))
					print(len(node_infos))
					upper_bound = node_next.cost
					for i in 0 ..< node_next.cost {
						print(i, histogram[i])
					}
					path := traverse(node_next, &node_infos)
					print(path)
					return path
				}
				continue
			}

			// if node_next.cost + node_next.rest_lower_bound >= upper_bound {
			// 	continue
			// }

			h :=
				-f64(upper_bound_0 - len(node_next.options)) /
				f64(node_next.cost)

			push(&heap, Node{h = h, hash = hash_next})
		}
	}

	return []IVec2{}
}

grid_region_options :: proc(rows: Grid) -> []IVec2 {
	rows := rows

	options := make([dynamic]IVec2)
	// defer delete(options) TODO

	for y in 0 ..< GRID_ROWS {
		for x in 0 ..< GRID_COLUMNS {
			if rows[y][x] != CellKind.Empty {
				pos := IVec2{x, y}
				append(&options, pos)
				grid_flood_empty(&rows, pos)
			}
		}
	}
	return options[:]
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
					in_this_col = true
					if !in_last_col {
						lower_bound += 1
					}
					break
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

grid_to_hash :: proc(rows: ^Grid, cost: int) -> string {
	hash := strings.Builder{}

	for y in 0 ..< GRID_ROWS {
		for x in 0 ..< GRID_COLUMNS {
			cell := rows[y][x]
			strings.write_byte(&hash, u8(cell))
		}
		strings.write_byte(&hash, ' ')
	}

	strings.write_int(&hash, cost)

	return strings.to_string(hash)
}

traverse :: proc(
	node_next: Node_Info,
	node_infos: ^map[string]Node_Info,
) -> []IVec2 {
	path := make([dynamic]IVec2)
	// defer delete(path) TODO

	append(&path, node_next.pos)

	hash := node_next.hash_prev
	for (hash in node_infos) { 	// this is a while
		node := node_infos[hash]
		if node.cost > 0 {
			append(&path, node.pos)
		}
		hash = node.hash_prev
	}
	slice.reverse(path[:])

	return path[:]
}
