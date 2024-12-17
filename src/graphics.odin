#+vet unused shadowing using-stmt style semicolon
package main

import "core:strings"
import rl "vendor:raylib"

Graphics :: struct {
	sprites: map[Sprite_Id]rl.Texture,
	fonts:   map[Font_Id]rl.Font,
	surface: rl.RenderTexture2D,
	camera:  Camera,
}

Sprite_Id :: enum {
	player,
	skeleton,
}

Font_Id :: enum {
	lilita_one_regular,
	nova_square_regular,
}
Font_Paths := [Font_Id]string {
	.lilita_one_regular  = "LilitaOne-Regular.ttf",
	.nova_square_regular = "NovaSquare-Regular.ttf",
}

@(private = "file")
_load_fonts :: proc() -> map[Font_Id]rl.Font {
	m := make(map[Font_Id]rl.Font)

	for font_id in Font_Id {
		font_path := Font_Paths[font_id]
		full_path := strings.concatenate({ASSETS_PATH, font_path})
		m[font_id] = rl.LoadFontEx(cstr(full_path), 128, {}, 0)
		rl.SetTextureFilter(m[font_id].texture, rl.TextureFilter.BILINEAR)
	}
	return m
}


graphics_create :: proc(game_state: ^Game_State) {

	rl.InitWindow(SURFACE_WIDTH, SURFACE_HEIGHT, WINDOW_TITLE)
	rl.SetWindowState({.WINDOW_RESIZABLE})
	rl.SetTargetFPS(60)

	game_state.graphics.fonts = _load_fonts()
	rl.GuiSetFont(game_state.graphics.fonts[Font_Id.lilita_one_regular])

	game_state.graphics.surface = rl.LoadRenderTexture(
		SURFACE_WIDTH,
		SURFACE_HEIGHT,
	)
	rl.SetTextureFilter(
		game_state.graphics.surface.texture,
		rl.TextureFilter.POINT,
	)

	game_state.graphics.camera.view_size = {
		SURFACE_WIDTH / GRID_SIZE,
		SURFACE_HEIGHT / GRID_SIZE,
	}
	game_state.graphics.camera.target_pos = {
		GRID_ROWS / 2.0,
		GRID_COLUMNS / 2.0,
	}
}
