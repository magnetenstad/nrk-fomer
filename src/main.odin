#+vet unused shadowing using-stmt style semicolon

package main

import rl "vendor:raylib"

@(private = "file")
_game_state: Game_State

get_game_state :: proc() -> ^Game_State {
	return &_game_state
}

main :: proc() {
	_game_state = game_state_create()

	count := branch_and_bound_search(&_game_state.grid.rows)

	print("Found", count)

	// _game_state = game_state_create()
	// graphics_create(&_game_state)

	// for !rl.WindowShouldClose() {
	// 	_main_step(&_game_state)
	// 	_main_draw(&_game_state)
	// }

	// rl.CloseWindow()
}


@(private = "file")
_main_step :: proc(game_state: ^Game_State) {
	grid_step(&game_state.grid)

	camera_step(&game_state.graphics.camera)
}

@(private = "file")
_main_draw :: proc(game_state: ^Game_State) {
	camera := &game_state.graphics.camera
	scale := camera_surface_scale(camera)

	// Draw onto texture
	rl.BeginTextureMode(game_state.graphics.surface)
	{
		rl.ClearBackground({0, 0, 0, 0})
		grid_draw(&game_state.grid)
	}
	rl.EndTextureMode()

	// Draw texture onto screen
	rl.BeginDrawing()
	{
		rl.ClearBackground(rl.BLACK)
		texture := game_state.graphics.surface.texture
		surface_origin := camera_surface_origin(camera)
		// Hack to make camera smooth
		subpixel := FVec2 {
			floor_to_multiple(camera.position.x, scale) - camera.position.x,
			floor_to_multiple(camera.position.y, scale) - camera.position.y,
		}

		rl.DrawTexturePro(
			texture,
			{0.0, 0.0, f32(texture.width), -f32(texture.height)},
			{
				surface_origin.x + subpixel.x,
				surface_origin.y + subpixel.y,
				f32(SURFACE_WIDTH) * scale,
				f32(SURFACE_HEIGHT) * scale,
			},
			{0, 0},
			0.0,
			rl.WHITE,
		)

		draw_text(format(rl.GetFPS()), {16, 16}, size = 16)

		// GUI
		grid_draw_gui(&game_state.grid)
	}
	rl.EndDrawing()
}
