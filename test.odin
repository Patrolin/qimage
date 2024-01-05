package main

import "core:fmt"

main :: proc() {
	switch (0) {
	case 1:
		fmt.println("case 1a")
	//fmt.println("case 1b")
	case:
		fmt.println("default a")
	//fmt.println("default b")
	}
}
