package lib_os

import "windows"

initInfo :: proc() {
	when ODIN_OS == .Windows {
		windows.initInfo()
	} else {
		assert(false, "Not implemented")
	}
}
