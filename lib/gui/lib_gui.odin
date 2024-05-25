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
	placeAt:   ^GuiPlacement,
	nodes:     ^GuiNode,
	hovered:   ^GuiNode,
	dragging:  ^GuiNode,
	focused:   ^GuiNode,
}
GuiPlacement :: struct {
	// TODO: sizes
	prev:          ^GuiPlacement,
	pos:           math.v2i,
	rect:          math.Rect,
	is_horizontal: bool,
}
GuiNode :: struct {
	prev: ^GuiNode,
	next: ^GuiNode,
	rect: math.Rect,
	// TODO: z order
	node: union {
		TextNode,
		ButtonNode,
		ImageNode,
	},
}
TextNode :: struct {
	text: string, // ? B
}
ButtonNode :: struct {
	text: string, // ? B
}
ImageNode :: struct {
	image: ^file.Image, // 8 B
}
getTextSize :: proc(str: string) -> math.v2i {
	return math.v2i{50, 12} // TODO!: fonts?
}

placeRect :: proc(state: ^GuiState, size: math.v2i) -> (rect: math.Rect) {
	placeAt := state.placeAt
	pos := placeAt.pos
	rect = {pos.x, pos.y, pos.x + size.x, pos.y + size.y}
	if placeAt.is_horizontal {
		pos.x += size.x
	} else {
		pos.y += size.y
	}
	placeAt.rect.right = max(placeAt.rect.right, rect.right)
	placeAt.rect.bottom = max(placeAt.rect.bottom, rect.bottom)
	return
}
isHovered :: proc(state: ^GuiState, rect: math.Rect) -> bool {
	lastMousePos := input.lastMousePos(state.inputs)
	return (state.dragging == nil) && math.inBounds(lastMousePos, rect)
}
wasClicked :: proc(state: ^GuiState, rect: math.Rect) -> bool {
	return(
		input.wentDown(state.inputs.mouse.LMB) &&
		math.inBounds(state.inputs.mouse.clickPos, rect) \
	)
}

// TODO?: begin(row/column), end()
// TODO!: margin(), indent()?
// TODO!: wrap, ellipses, color, ...
addNode :: proc(state: ^GuiState, node: ^GuiNode) {
	node.prev = state.nodes.next
	state.nodes.next = node
}
text :: proc(state: ^GuiState, str: string) {
	gui_node := new(GuiNode)
	gui_node^ = {
		rect = placeRect(state, getTextSize(str)),
		node = TextNode{text = str},
	}
	addNode(state, gui_node)
}
button :: proc(state: ^GuiState, str: string) -> bool {
	gui_node := new(GuiNode)
	gui_node^ = {
		rect = placeRect(state, getTextSize(str)),
		node = ButtonNode{text = str},
	}
	addNode(state, gui_node)

	was_clicked := wasClicked(state, gui_node.rect)
	if was_clicked {
		state.dragging = gui_node
	}
	if isHovered(state, gui_node.rect) {
		state.hovered = gui_node
	}
	return was_clicked
}
image :: proc(state: ^GuiState, image: ^file.Image, rect: math.Rect) {
	gui_node := new(GuiNode)
	gui_node^ = {
		rect = placeRect(state, {image.width, image.height}),
		node = ImageNode{image = image},
	}
	addNode(state, gui_node)
}
