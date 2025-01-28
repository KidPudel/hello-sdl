package main

import "core:fmt"
import sdl "vendor:sdl2"


// todo: define your own error

main :: proc() {
	// before calling any other api
	if sdl.Init(sdl.INIT_VIDEO) != 0 {
		fmt.println(sdl.GetError())
		return
	}
	defer sdl.Quit()

	window := sdl.CreateWindow(
		"hello-sdl",
		sdl.WINDOWPOS_UNDEFINED,
		sdl.WINDOWPOS_UNDEFINED,
		640,
		480,
		sdl.WINDOW_SHOWN,
	)
	if window == nil {
		fmt.println(sdl.GetError())
		return
	}
	defer sdl.DestroyWindow(window)

	winSurface := sdl.GetWindowSurface(window)

	sdl.FillRect(winSurface, nil, sdl.MapRGB(winSurface.format, 200, 200, 100))


	daughterSurf := sdl.LoadBMP("res/daughter.bmp")
	if daughterSurf == nil {
		fmt.printf("failed to load image: %s", sdl.GetError())
		return
	}
	defer sdl.FreeSurface(daughterSurf)

	// write to the back buffer
	sdl.BlitSurface(daughterSurf, nil, winSurface, &{20, 20, 240, 100})


	// swap buffers
	sdl.UpdateWindowSurface(window)

	game_loop: for {
		event: sdl.Event
		for sdl.PollEvent(&event) {
			if event.type == sdl.EventType.QUIT || event.key.keysym.sym == sdl.Keycode.q {
				break game_loop
			}
		}


	}

}
