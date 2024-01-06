package windowsOpengl
import coreWin "core:sys/windows"
import coreGl "vendor:OpenGL"

GLboolean :: bool
GLbyte :: i8
GLubyte :: u8
GLshort :: i16
GLushort :: u16
GLint :: i32
GLuint :: u32
GLfixed :: distinct i32
GLint64 :: i64
GLuint64 :: u64
GLsizei :: u32
GLenum :: u32
GLintptr :: int
GLsizeiptr :: uint
GLsync :: int
GLbitfield :: i32
GLhalf :: f16
GLfloat :: f32
GLclampf :: f32
GLdouble :: f64
GLclampd :: f64

PIXELFORMATDESCRIPTOR :: coreWin.PIXELFORMATDESCRIPTOR

PFD_TYPE_RGBA :: coreWin.PFD_TYPE_RGBA
PFD_SUPPORT_OPENGL :: coreWin.PFD_SUPPORT_OPENGL
PFD_DRAW_TO_WINDOW :: coreWin.PFD_DRAW_TO_WINDOW
PFD_DOUBLEBUFFER :: coreWin.PFD_DOUBLEBUFFER
PFD_MAIN_PLANE :: coreWin.PFD_MAIN_PLANE
COLOR_BUFFER_BIT :: coreGl.COLOR_BUFFER_BIT

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
