package main

import "core:fmt"
import sdl "vendor:sdl2"
import img "vendor:sdl2/image"

// todo: define your own error


Game :: struct {
	window:          ^sdl.Window,
	// win_surface:     ^sdl.Surface,
	renderer:        ^sdl.Renderer,
	central_texture: ^sdl.Texture,
	width:           i32,
	height:          i32,
}

initialize_game :: proc() -> ^Game {
	game := new(Game)
	game^ = Game {
		width  = 640,
		height = 480,
	}
	if sdl.Init(sdl.INIT_VIDEO) != 0 {
		fmt.println(sdl.GetError())
		return nil
	}

	img_flags := img.InitFlags{.PNG, .JPG}
	if accepted_flags := img.Init(img_flags); accepted_flags != img_flags {
		fmt.printf("not supported format: %s\n", img.GetError())
		return nil
	}

	game.window = sdl.CreateWindow(
		"hello-sdl",
		sdl.WINDOWPOS_UNDEFINED,
		sdl.WINDOWPOS_UNDEFINED,
		game.width,
		game.height,
		sdl.WINDOW_SHOWN,
	)
	if game.window == nil {
		fmt.printf("failed to create window: %s\n", sdl.GetError())
		return nil
	}

	// game.win_surface = sdl.GetWindowSurface(game.window)
	// if game.win_surface == nil {
	// 	fmt.printf("failed to get surface: %s\n", sdl.GetError())
	// 	return nil
	// }

	game.renderer = setup_gpu_rendering(game)
	if game.renderer == nil {
		fmt.printf("failed to create render context: %s\n", sdl.GetError())
		return nil
	}

	return game
}


quit_and_clear :: proc(game: ^Game) {
	defer free(game)
	defer sdl.Quit()
	defer img.Quit()
	defer sdl.DestroyWindow(game.window)
	defer sdl.DestroyTexture(game.central_texture)
}


setup_gpu_rendering :: proc(game: ^Game) -> ^sdl.Renderer {
	renderer := sdl.CreateRenderer(game.window, -1, sdl.RENDERER_ACCELERATED)
	if renderer == nil {
		fmt.printf("failed to create renderer: %s\n", img.GetError())
		// todo: add errors
		return nil
	}
	if sdl.SetRenderDrawColor(renderer, 255, 255, 255, 255) != 0 {
		fmt.printf("failed to set color: %s\n", img.GetError())
		return nil
	}
	return renderer
}

load_texture :: proc(path: cstring, game: ^Game) {
	game.central_texture = img.LoadTexture(game.renderer, path)
	if game.central_texture == nil {
		fmt.printf("failed to load texture: %s\n", img.GetError())
		return
	}
}

load_optimized_surface :: proc(path: cstring, window_surf: ^sdl.Surface) -> ^sdl.Surface {
	raw_surface := img.Load(path)
	if raw_surface == nil {
		fmt.println(img.GetError())
		return nil
	}
	defer sdl.FreeSurface(raw_surface)

	// fit to the standards of screen
	optimized_surf := sdl.ConvertSurface(raw_surface, window_surf.format, 0)
	if optimized_surf == nil {
		fmt.println(sdl.GetError())
		return nil
	}

	return optimized_surf
}


main :: proc() {
	game := initialize_game()
	if game == nil {
		return
	}
	defer quit_and_clear(game)

	// sdl.FillRect(game.win_surface, nil, sdl.MapRGB(game.win_surface.format, 200, 200, 100))


	// surf := load_optimized_surface("res/daughter.jpg", game.win_surface)
	// if surf == nil {
	// 	fmt.println(sdl.GetError())
	// 	return
	// }
	// defer sdl.FreeSurface(surf)

	load_texture("res/tes.jpg", game)
	if game.central_texture == nil {
		fmt.println(sdl.GetError())
		return
	}

	game_loop: for {
		event: sdl.Event
		for sdl.PollEvent(&event) {
			if event.type == sdl.EventType.QUIT || event.key.keysym.sym == sdl.Keycode.ESCAPE {
				break game_loop
			}
		}

		// fill with color
		sdl.RenderClear(game.renderer)

		sdl.RenderCopy(game.renderer, game.central_texture, nil, nil)

		// swap buffers, with images stored in GPU/VRAM
		sdl.RenderPresent(game.renderer)

		// write to the back buffer
		// sdl.BlitScaled(surf, nil, game.win_surface, &{20, 20, 240, 100})


		// swap buffers with CPU loaded images
		// sdl.UpdateWindowSurface(game.window)

	}

}
