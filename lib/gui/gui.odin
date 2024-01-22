package lib_gui
import "../file"
import "../input"
import "../math"
import "core:mem"

/*
counter := 0
volumeSlider := f32(0.0)
username := ""
render :: proc {
	guiState: gui.GuiState
  // TODO!: allocate strings in a render arena?
  gui.text(&guiState, fmt.aprintf("counter: %v", counter))
  if gui.button("Click me!") {
    counter += 1
  }
	if volumeSliderNew := gui.slider(&guiState, "volume_slider", "Volume", &input); volumeSliderNew != volumeSlider {
		volumeSlider = volumeSliderNew
	}
	if usernameNew := gui.text_box(&guiState, "Username"); usernameNew != username {
		username = usernameNew
	}
}
*/
GuiState :: struct {
	allocator: mem.Allocator,
	nodes:     [dynamic]GuiNode,
	hovered:   ^GuiNode, // NOTE: context.allocator.resize() must not move .nodes
	dragging:  ^GuiNode,
	focused:   ^GuiNode,
}
GuiNode :: union {
	TextNode,
	ButtonNode,
	ImageNode,
}
TextNode :: struct {
	text: string,
	rect: math.Rect,
}
ButtonNode :: struct {
	text: string,
	rect: math.Rect,
}
ImageNode :: struct {
	image: ^file.Image,
	rect:  math.Rect,
}
get_string_rect :: proc(str: string) -> math.Rect {
	return math.Rect{} // TODO!: fonts?
}

// TODO!: wrap, elipses, color, ...
text :: proc(state: ^GuiState, str: string) {
	append(&state.nodes, TextNode{text = str, rect = get_string_rect(str)})
}
button :: proc(state: ^GuiState, id: cstring, str: string, inputs: ^input.Inputs) -> bool {
	string_rect := get_string_rect(str)
	wasClicked :=
		input.went_down(inputs.mouse.LMB) & math.in_bounds(inputs.mouse.clickPos, string_rect)
	append(&state.nodes, ButtonNode{text = str, rect = string_rect})
	if wasClicked {
		state.dragging = &state.nodes[len(state.nodes) - 1]
	}
	if (state.dragging == nil) & math.in_bounds(inputs.mouse.pos, string_rect) {
		state.hovered = &state.nodes[len(state.nodes) - 1]
	}
	return wasClicked
}
image :: proc(state: ^GuiState, image: ^file.Image, rect: math.Rect) {
	append(&state.nodes, ImageNode{image = image, rect = rect})
}
