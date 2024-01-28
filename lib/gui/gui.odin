package lib_gui
import "../alloc"
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
	if volumeSliderNew := gui.slider(&guiState, "Volume", &input); volumeSliderNew != volumeSlider {
		volumeSlider = volumeSliderNew
	}
	if usernameNew := gui.text_box(&guiState, "Username"); usernameNew != username {
		username = usernameNew
	}
}
*/
GuiState :: struct {
	allocator: mem.Allocator,
	inputs:    ^input.Inputs,
	placeAt:   alloc.FixedBuffer(GuiPlacement, 16),
	nodes:     [dynamic]GuiNode, // NOTE: context.allocator.resize() must not move .nodes
	hovered:   ^GuiNode,
	dragging:  ^GuiNode,
	focused:   ^GuiNode,
	// TODO!: notion of z order??
}
GuiPlacement :: struct {
	pos:           math.v2i,
	rect:          math.Rect,
	is_horizontal: bool,
}
GuiNode :: struct {
	rect: math.Rect,
	node: union {
		TextNode,
		ButtonNode,
		ImageNode,
	},
}
TextNode :: struct {
	text: string,
}
ButtonNode :: struct {
	text: string,
}
ImageNode :: struct {
	image: ^file.Image,
}
getTextSize :: proc(str: string) -> math.v2i {
	return math.v2i{50, 12} // TODO!: fonts?
}

placeRect :: proc(state: ^GuiState, size: math.v2i) -> (rect: math.Rect) {
	placeAt := alloc.fixedBufferLast(&state.placeAt)
	pos := placeAt.pos
	rect = {pos.x, pos.y, pos.x + size.x, pos.y + size.y}
	if placeAt.is_horizontal {
		pos.x += size.x
	} else {
		pos.y += size.y
	}
	placeAt.rect.right = math.max(placeAt.rect.right, rect.right)
	placeAt.rect.bottom = math.max(placeAt.rect.bottom, rect.bottom)
	return
}
isHovered :: proc(state: ^GuiState, rect: math.Rect) -> bool {
	lastMousePos := input.lastMousePos(state.inputs)
	return (state.dragging == nil) && math.inBounds(lastMousePos, rect)
}
wasClicked :: proc(state: ^GuiState, rect: math.Rect) -> bool {
	return(
		input.wentDown(state.inputs.mouse.LMB) & math.inBounds(state.inputs.mouse.clickPos, rect)
	)
}

// TODO?: begin(row/column), end()
// TODO!: margin(), indent()?
// TODO!: wrap, ellipses, color, ...
text :: proc(state: ^GuiState, str: string) {
	text_size := getTextSize(str)
	rect := placeRect(state, text_size)
	append(&state.nodes, GuiNode{rect, TextNode{text = str}})
}
button :: proc(state: ^GuiState, str: string) -> bool {
	text_size := getTextSize(str)
	rect := placeRect(state, text_size)
	append(&state.nodes, GuiNode{rect, ButtonNode{text = str}})
	was_clicked := wasClicked(state, rect)
	if was_clicked {
		state.dragging = &state.nodes[len(state.nodes) - 1]
	}
	if isHovered(state, rect) {
		state.hovered = &state.nodes[len(state.nodes) - 1]
	}
	return was_clicked
}
image :: proc(state: ^GuiState, image: ^file.Image, rect: math.Rect) {
	rect := placeRect(state, {image.width, image.height})
	append(&state.nodes, GuiNode{rect, ImageNode{image = image}})
}
