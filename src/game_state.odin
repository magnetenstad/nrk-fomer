#+vet unused shadowing using-stmt style semicolon
package main

Game_State :: struct {
	graphics: Graphics,
}

game_state_create :: proc() -> Game_State {
	game_state := Game_State{}

	return game_state
}
