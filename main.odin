package main

import "core:fmt"
import sdl "vendor:sdl2"
import img "vendor:sdl2/image"
import mx "vendor:sdl2/mixer"

Tool_Type :: enum {
	Odin,
	SDL,
}


Tool :: struct {
	texture:   ^sdl.Texture,
	sound:     ^mx.Chunk,
	rect:      sdl.Rect,
	direction: i32,
}

Program :: struct {
	window:           ^sdl.Window,
	renderer:         ^sdl.Renderer,
	tools:            [Tool_Type]Tool,
	background_music: ^mx.Music,
	width:            i32,
	height:           i32,
	delta_time:       u32,
	running:          bool,
}


init :: proc() -> ^Program {
	program := new(Program)
	program^ = Program {
		width   = 640,
		height  = 480,
		running = true,
	}

	// init libraries
	if sdl.Init(sdl.INIT_VIDEO + sdl.INIT_AUDIO) != 0 {
		fmt.println(sdl.GetError())
		return nil
	}

	supported_ext := img.InitFlags{.PNG, .JPG}
	if enabled_ext := img.Init(supported_ext); supported_ext != enabled_ext {
		fmt.println(img.GetError())
		return nil
	}


	// if mx.Init() < 0 {
	// 	fmt.println(mx.GetError())
	// 	return nil
	// }

	// open device to generate noice
	if mx.OpenAudio(44100, mx.DEFAULT_FORMAT, 2, 2048) < 0 {
		fmt.printf("failed to open audio: %s\n", mx.GetError())
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


	odin_texture := img.LoadTexture(program.renderer, "res/odinlang.png")
	if odin_texture == nil {
		fmt.printf("failed to load texture: %s\n", img.GetError())
		return nil
	}
	sdl_texture := img.LoadTexture(program.renderer, "res/sdl.png")
	if sdl_texture == nil {
		fmt.printf("failed to load texture: %s\n", img.GetError())
		return nil
	}


	background_music := mx.LoadMUS("res/background.wav")
	if background_music == nil {
		fmt.printf("failed to load music: %s\n", mx.GetError())
		return nil
	}

	explosion_sound := mx.LoadWAV("res/explosion.wav")
	if explosion_sound == nil {
		fmt.println(mx.GetError())
		return nil
	}

	hit_sound := mx.LoadWAV("res/hit.wav")
	if hit_sound == nil {
		fmt.println(mx.GetError())
		return nil
	}

	odin_w, odin_h: i32
	if sdl.QueryTexture(odin_texture, nil, nil, &odin_w, &odin_h) != 0 {
		fmt.println(sdl.GetError())
		return nil

	}

	sdl_w, sdl_h: i32
	if sdl.QueryTexture(sdl_texture, nil, nil, &sdl_w, &sdl_h) != 0 {
		fmt.println(sdl.GetError())
		return nil
	}

	program.tools = [Tool_Type]Tool {
		.Odin = Tool {
			texture = odin_texture,
			sound = explosion_sound,
			rect = sdl.Rect{100, 100, odin_w / 2, odin_h / 2},
			direction = 1,
		},
		.SDL = Tool {
			texture = sdl_texture,
			sound = hit_sound,
			rect = sdl.Rect{100, program.height - 100, sdl_w / 2, sdl_h / 2},
			direction = 1,
		},
	}

	return program
}

quit_and_clear :: proc(program: ^Program) {
	for tool in program.tools {
		sdl.DestroyTexture(tool.texture)
		mx.FreeChunk(tool.sound)
	}

	mx.FreeMusic(program.background_music)


	sdl.DestroyRenderer(program.renderer)
	sdl.DestroyWindow(program.window)

	mx.Quit()
	img.Quit()
	sdl.Quit()
	free(program)
}

draw_frame :: proc(program: ^Program) {
	sdl.RenderClear(program.renderer)

	sdl.SetRenderDrawColor(program.renderer, 100, 200, 200, 255)

	sdl.SetRenderTarget(program.renderer, program.tools[.Odin].texture)
	sdl.RenderCopy(program.renderer, program.tools[.Odin].texture, nil, &program.tools[.Odin].rect)

	sdl.RenderCopy(program.renderer, program.tools[.SDL].texture, nil, &program.tools[.SDL].rect)

	sdl.RenderPresent(program.renderer)
}

calculate_fps :: proc(frames_passed: i32) -> i32 {
	fps := frames_passed / i32(sdl.GetTicks() / 1000)
	return fps
}

update_state :: proc(program: ^Program) {
	e: sdl.Event
	for sdl.PollEvent(&e) {
		if e.key.keysym.sym == sdl.Keycode.ESCAPE || e.type == sdl.EventType.QUIT {
			program.running = false
		}
	}


	if program.tools[.Odin].rect.x >= program.width ||
	   program.tools[.Odin].rect.y >= program.height ||
	   program.tools[.Odin].rect.x <= 0 ||
	   program.tools[.Odin].rect.y <= 0 {
		program.tools[.Odin].direction *= -1
		if mx.PlayChannel(-1, program.tools[.Odin].sound, 0) < 0 {
			fmt.printf("error while playing sound: %s\n", mx.GetError())
		}
	}

	program.tools[.Odin].rect.x += program.tools[.Odin].direction * i32(program.delta_time) / 3
	program.tools[.Odin].rect.y += program.tools[.Odin].direction * i32(program.delta_time) / 3


	if program.tools[.SDL].rect.x >= program.width ||
	   program.tools[.SDL].rect.y >= program.height ||
	   program.tools[.SDL].rect.x <= 0 ||
	   program.tools[.SDL].rect.y <= 0 {
		program.tools[.SDL].direction *= -1
		if mx.PlayChannel(-1, program.tools[.SDL].sound, 0) != 0 {
			// fmt.println(mx.GetError())
		}
	}
	program.tools[.SDL].rect.x += program.tools[.SDL].direction * i32(program.delta_time)
	program.tools[.SDL].rect.y -= program.tools[.SDL].direction * i32(program.delta_time)


}

main :: proc() {
	program := init()
	if program == nil {
		return
	}
	defer quit_and_clear(program)

	if mx.PlayMusic(program.background_music, -1) < 0 {
		fmt.printf("error while playing music: %s\n", mx.GetError())
	}

	frames_passed: i32 = 0

	frame_cap: u32 = 1000 / 60

	frame_ticks: u32 = 0

	for program.running {
		frame_ticks = sdl.GetTicks() - frame_ticks

		if frame_ticks < frame_cap {
			sdl.Delay(frame_cap - frame_ticks)
			program.delta_time = frame_cap
		} else {
			program.delta_time = frame_ticks
		}

		update_state(program)
		draw_frame(program)

		fps := calculate_fps(frames_passed)


		frame_ticks = sdl.GetTicks()
		frames_passed += 1
	}

}
