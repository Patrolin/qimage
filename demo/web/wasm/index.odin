// odin build demo/web/wasm -out:demo/web/wasm/index.wasm -target:js_wasm32 -no-entry-point
package wasm
import "core:fmt"

foo :: proc() {
	fmt.print("Hello world.")
}
