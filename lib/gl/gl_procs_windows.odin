package libGl
import "../paint"
import coreWin "core:sys/windows"
import coreGl "vendor:OpenGL"

HDC :: coreWin.HDC
PIXELFORMATDESCRIPTOR :: coreWin.PIXELFORMATDESCRIPTOR
Window :: paint.Window
PAINTSTRUCT :: paint.PAINTSTRUCT

PFD_TYPE_RGBA :: coreWin.PFD_TYPE_RGBA
PFD_SUPPORT_OPENGL :: coreWin.PFD_SUPPORT_OPENGL
PFD_DRAW_TO_WINDOW :: coreWin.PFD_DRAW_TO_WINDOW
PFD_DOUBLEBUFFER :: coreWin.PFD_DOUBLEBUFFER
PFD_MAIN_PLANE :: coreWin.PFD_MAIN_PLANE
COLOR_BUFFER_BIT :: coreGl.COLOR_BUFFER_BIT

GetDC :: paint.GetDC
BeginPaint :: paint.BeginPaint
EndPaint :: paint.EndPaint
ChoosePixelFormat :: coreWin.ChoosePixelFormat
DescribePixelFormat :: coreWin.DescribePixelFormat
SetPixelFormat :: coreWin.SetPixelFormat
wglCreateContext :: coreWin.wglCreateContext
wglMakeCurrent :: coreWin.wglMakeCurrent
SwapBuffers :: coreWin.SwapBuffers
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
resizeImageBuffer :: proc(width, height: u16) {
	// TODO: stretch previous?
	glViewport(0, 0, u32(width), u32(height))
}
renderBufferToWindow :: proc(dc: HDC) {
	SwapBuffers(dc)
}
