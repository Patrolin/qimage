package ast
import "../math"
import "core:fmt"

Utf8Iterator :: struct {
	str: string,
	i:   int,
	j:   int,
}
eatUtf8Char :: proc(iterator: ^Utf8Iterator) -> rune {
	iterator.i = iterator.j
	first_byte := iterator.str[iterator.i]
	neg_bits := math.clz(~first_byte)
	neg_bits = neg_bits + u8(neg_bits == 0)
	byte_count := int(neg_bits)
	iterator.j = iterator.i + byte_count
	code_point := u32(first_byte) & (0xff >> neg_bits)
	for x := 1; x < byte_count; x += 1 {
		next_byte := iterator.str[iterator.i + x]
		code_point = (code_point << 6) | (u32(next_byte) & 0x3f)
	}
	return rune(code_point)
}

Token :: struct {
	type:  rune,
	start: int,
	end:   int,
}
in_ :: proc(char: rune, $set: string) -> bool {
	for set_char in set {
		if char == set_char {
			return true
		}
	}
	return false
}
not_in_ :: proc(char: rune, $set: string) -> bool {
	for set_char in set {
		z := set_char
		if char == set_char {
			return true
		}
	}
	return false
}
tokenize :: proc(
	input: string,
	$symbol_chars: string,
	$string_chars: string,
	$string_escape_chars: string,
	$variable_chars: string,
	$whitespace_chars: string,
) -> [dynamic]Token {
	acc_tokens: [dynamic]Token
	iterator := Utf8Iterator {
		str = input,
	}
	for iterator.j < len(input) {
		fmt.println("iterator:", iterator)
		char := eatUtf8Char(&iterator)
		if in_(char, whitespace_chars) {
			continue
		}
		if in_(char, symbol_chars) {
			append(&acc_tokens, Token{type = char, start = iterator.i, end = iterator.j})
		} else if in_(char, string_chars) {
			start_i := iterator.i
			char = eatUtf8Char(&iterator)
			for iterator.j < len(input) && not_in_(char, string_chars) {
				char = eatUtf8Char(&iterator)
			}
			append(&acc_tokens, Token{type = '"', start = start_i, end = iterator.j})
		} else if in_(char, variable_chars) {
			start_i := iterator.i
			for iterator.j < len(input) && in_(char, variable_chars) {
				char = eatUtf8Char(&iterator)
			}
			append(&acc_tokens, Token{type = '_', start = start_i, end = iterator.j})
		} else {
			assert(false, "Invalid token")
		}
	}
	return acc_tokens
}
