package main

import "core:fmt"
import sdl "vendor:sdl2"
import img "vendor:sdl2/image"

Texture :: enum {
	Odin_Texture,
	SDL_Texture,
}

Program :: struct {
	window:   ^sdl.Window,
	renderer: ^sdl.Renderer,
	width:    i32,
	height:   i32,
	textures: [Texture]^sdl.Texture,
}


init :: proc() -> ^Program {
	program := new(Program)
	program^ = Program {
		width  = 640,
		height = 480,
	}

	// init libraries
	if sdl.Init(sdl.INIT_VIDEO) != 0 {
		fmt.println(sdl.GetError())
		return nil
	}

	supported_ext := img.InitFlags{.PNG, .JPG}
	if enabled_ext := img.Init(supported_ext); supported_ext != enabled_ext {
		fmt.println(img.GetError())
		return nil
	}

	program.window = sdl.CreateWindow(
		"odin-sdl",
		sdl.WINDOWPOS_UNDEFINED,
		sdl.WINDOWPOS_UNDEFINED,
		program.width,
		program.height,
		sdl.WINDOW_SHOWN,
	)
	if program.window == nil {
		fmt.println(sdl.GetError())
		return nil
	}

	program.renderer = sdl.CreateRenderer(program.window, -1, sdl.RENDERER_ACCELERATED)
	if program.renderer == nil {
		fmt.println(sdl.GetError())
		return nil
	}

	if sdl.SetRenderDrawColor(program.renderer, 100, 200, 200, 255) != 0 {
		fmt.println(sdl.GetError())
		return nil
	}


	odin_texture := img.LoadTexture(program.renderer, "res/odinlang.png")
	if odin_texture == nil {
		fmt.println(sdl.GetError())
		return nil
	}
	sdl_texture := img.LoadTexture(program.renderer, "res/sdl.png")
	if sdl_texture == nil {
		fmt.println(sdl.GetError())
		return nil
	}

	program.textures = [Texture]^sdl.Texture {
		.Odin_Texture = odin_texture,
		.SDL_Texture  = sdl_texture,
	}

	return program
}

quit_and_clear :: proc(program: ^Program) {
	defer free(program)
	defer sdl.Quit()
	defer sdl.DestroyWindow(program.window)
	defer sdl.DestroyRenderer(program.renderer)
}

draw_frame :: proc(program: ^Program) {
	sdl.RenderClear(program.renderer)

	sdl.RenderCopy(
		program.renderer,
		program.textures[.Odin_Texture],
		nil,
		&sdl.Rect{100, 100, 100, 100},
	)

	sdl.RenderPresent(program.renderer)
}

main :: proc() {
	program := init()
	if program == nil {
		return
	}
	defer quit_and_clear(program)

	running := true
	for running {
		e: sdl.Event
		for sdl.PollEvent(&e) {
			if e.key.keysym.sym == sdl.Keycode.ESCAPE || e.type == sdl.EventType.QUIT {
				running = false
			}
		}
		draw_frame(program)
	}

}
