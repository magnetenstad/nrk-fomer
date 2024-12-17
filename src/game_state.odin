#+vet unused shadowing using-stmt style semicolon
package main

Game_State :: struct {
	graphics: Graphics,
	grid:     Grid,
}

game_state_create :: proc() -> Game_State {
	game_state := Game_State{}

	grid_set(&game_state.grid)

	return game_state
}
