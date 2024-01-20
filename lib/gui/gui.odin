package lib_gui
import "../file"
import libInput "../input"
import "../math"

/*
counter := 0
volumeSlider := f32(0.0)
username := ""
render :: proc {
  // TODO: allocate in a render arena?
  gui.text(fmt.aprintf("counter: %v", counter))
  if gui.button("Click me!") {
    counter += 1
  }
	if volumeSliderNew := gui.slider("Volume"); volumeSliderNew != volumeSlider {
		volumeSlider = volumeSliderNew
	}
	if usernameNew := gui.text_box("Username"); usernameNew != username {
		username = usernameNew
	}
}
*/
GuiState :: struct {
	nodes:      ^[dynamic]GuiNode, // TODO: allocate in a render arena?
	hoveredId:  cstring,
	draggingId: cstring,
	focusedId:  cstring,
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
	return math.Rect{} // TODO: fonts?
}

// TODO: wrap, elipses, color, ...
text :: proc(state: ^GuiState, str: string) {
	append(state.nodes, TextNode{text = str, rect = get_string_rect(str)})
}
button :: proc(state: ^GuiState, id: cstring, str: string, input: ^libInput.Input) -> bool {
	string_rect := get_string_rect(str)
	wasClicked := bool(input.mouse.LMB_count) & math.in_bounds(input.mouse.clickPos, string_rect)
	append(state.nodes, ButtonNode{text = str, rect = string_rect})
	if wasClicked {
		state.draggingId = id
	}
	if (state.draggingId == nil) & math.in_bounds(input.mouse.pos, string_rect) {
		state.hoveredId = id
	}
	return wasClicked
}
image :: proc(state: ^GuiState, image: ^file.Image, rect: math.Rect) {
	append(state.nodes, ImageNode{image = image, rect = rect})
}
