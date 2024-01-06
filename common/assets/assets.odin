package assets
import "../../lib/file"
import "core:fmt"

assets: map[string]file.Image

loadImage :: proc(fileName: string) -> file.Image {
	return file.loadBmp(fmt.tprintf("common/assets/data/%v", fileName))
}
