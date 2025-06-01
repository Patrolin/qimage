package gl_lib
import "../event"
import "../paint"
import win "core:sys/windows"
import gl "vendor:OpenGL"

HDC :: win.HDC
PIXELFORMATDESCRIPTOR :: win.PIXELFORMATDESCRIPTOR
PAINTSTRUCT :: paint.PAINTSTRUCT

PFD_TYPE_RGBA :: win.PFD_TYPE_RGBA
PFD_SUPPORT_OPENGL :: win.PFD_SUPPORT_OPENGL
PFD_DRAW_TO_WINDOW :: win.PFD_DRAW_TO_WINDOW
PFD_DOUBLEBUFFER :: win.PFD_DOUBLEBUFFER
PFD_MAIN_PLANE :: win.PFD_MAIN_PLANE
COLOR_BUFFER_BIT :: gl.COLOR_BUFFER_BIT

GetDC :: paint.GetDC
BeginPaint :: paint.BeginPaint
EndPaint :: paint.EndPaint
ChoosePixelFormat :: win.ChoosePixelFormat
DescribePixelFormat :: win.DescribePixelFormat
SetPixelFormat :: win.SetPixelFormat
wglCreateContext :: win.wglCreateContext
wglMakeCurrent :: win.wglMakeCurrent
SwapBuffers :: win.SwapBuffers
foreign import Opengl32 "system:Opengl32.lib"
@(default_calling_convention = "std")
foreign Opengl32 {
	glViewport :: proc(x, y: GLint, width, height: GLsizei) ---
	glClearColor :: proc(red, green, blue, alpha: GLclampf) ---
	glClear :: proc(mask: GLbitfield) ---
	glGetFloatv :: proc(name: GLenum, values: ^GLfloat) ---
}

initOpenGL :: proc(dc: HDC) {
	desiredPixelFormat := PIXELFORMATDESCRIPTOR {
		nSize      = size_of(PIXELFORMATDESCRIPTOR),
		nVersion   = 1,
		iPixelType = PFD_TYPE_RGBA,
		dwFlags    = PFD_SUPPORT_OPENGL | PFD_DRAW_TO_WINDOW | PFD_DOUBLEBUFFER,
		cRedBits   = 8,
		cGreenBits = 8,
		cBlueBits  = 8,
		cAlphaBits = 8,
		iLayerType = PFD_MAIN_PLANE,
	}
	pixelFormatIndex := ChoosePixelFormat(dc, &desiredPixelFormat)
	pixelFormat: PIXELFORMATDESCRIPTOR
	DescribePixelFormat(dc, pixelFormatIndex, size_of(PIXELFORMATDESCRIPTOR), &pixelFormat)
	SetPixelFormat(dc, pixelFormatIndex, &pixelFormat)
	glRc := wglCreateContext(dc)
	// NOTE: gl.wglCreateContextAttrib(...) for gl 3.0+
	assert(bool(wglMakeCurrent(dc, glRc)))
}
resizeImageBuffer :: proc(width, height: i32) {
	glViewport(0, 0, u32(width), u32(height))
}
renderImageBufferToWindow :: proc(window: event.Window) {
	SwapBuffers(window.dc)
}
/*
?TODO: compile .odin to gpu shaders
VSIn :: struct {
	vertex_id: u32,
	instance_id: u32,
}
vertexShader :: proc(input: VSIn) -> FSIn {
	// ...
}
FSIn :: struct {
	position: v2,
	color: v2 `nointerp`,
}
fragmentShader :: proc(input: FSIn) -> v4 {
	// ...
}
*/
