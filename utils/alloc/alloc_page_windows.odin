package lib_alloc
import "../math"
import "../os"
import "core:mem"
import win "core:sys/windows"

MEM_EXTENDED_PARAMETER_TYPE_BITS :: 8
MEM_EXTENDED_PARAMETER_TYPE :: enum win.DWORD64 {
	MemExtendedParameterAddressRequirements = 1,
	MemExtendedParameterNumaNode            = 2,
	MemExtendedParameterAttributeFlags      = 5,
}
MemExtendedParameterAttributeFlagsEnum :: enum win.DWORD64 {
	MEM_EXTENDED_PARAMETER_NONPAGED       = 0x2,
	MEM_EXTENDED_PARAMETER_NONPAGED_LARGE = 0x8,
	MEM_EXTENDED_PARAMETER_NONPAGED_HUGE  = 0x10,
	MEM_EXTENDED_PARAMETER_EC_CODE        = 0x40,
}
MEM_EXTENDED_PARAMETER :: struct {
	using _: bit_field win.DWORD64 {
		Type:     MEM_EXTENDED_PARAMETER_TYPE | MEM_EXTENDED_PARAMETER_TYPE_BITS,
		Reserved: win.DWORD64                 | 64 - MEM_EXTENDED_PARAMETER_TYPE_BITS,
	},
	using _: struct #raw_union {
		ULong64: win.DWORD64,
		Pointer: win.PVOID,
		Size:    win.SIZE_T,
		Handle:  win.HANDLE,
		ULong:   win.DWORD,
	},
}
MEM_ADDRESS_REQUIREMENTS :: struct {
	LowestStartingAddress: win.PVOID,
	HighestEndingAddress:  win.PVOID,
	Alignment:             win.SIZE_T,
}
foreign import onecorelib "system:onecore.lib"
@(default_calling_convention = "std")
foreign onecorelib {
	VirtualAlloc2 :: proc(Process: win.HANDLE, BaseAddress: win.PVOID, Size: win.SIZE_T, AllocationType: win.ULONG, PageProtection: win.ULONG, ExtendedParameters: ^MEM_EXTENDED_PARAMETER, ParameterCount: win.ULONG) -> win.LPVOID ---
}
page_alloc :: proc(size: math.Size) -> []u8 {
	ptr := VirtualAlloc2(
		nil,
		nil,
		win.SIZE_T(size),
		win.MEM_RESERVE | win.MEM_COMMIT,
		win.PAGE_READWRITE,
		nil,
		0,
	)
	return (cast([^]u8)ptr)[:size]
}
page_alloc_aligned :: proc(size: math.Size) -> []u8 {
	address_requirement := MEM_ADDRESS_REQUIREMENTS {
		Alignment = win.SIZE_T(size),
	}
	alloc_params: []MEM_EXTENDED_PARAMETER = {
		MEM_EXTENDED_PARAMETER {
			Type = .MemExtendedParameterAddressRequirements,
			Pointer = &address_requirement,
		},
	}
	ptr := VirtualAlloc2(
		nil,
		nil,
		win.SIZE_T(size),
		win.MEM_RESERVE | win.MEM_COMMIT,
		win.PAGE_READWRITE,
		&alloc_params[0],
		u32(len(alloc_params)),
	)
	return (cast([^]u8)ptr)[:size]
}
page_free :: proc(ptr: rawptr) -> b32 {
	return b32(win.VirtualFree(ptr, 0, win.MEM_RELEASE))
}

/*
@(private)
pageAllocatorProc :: proc(
	allocator_data: rawptr,
	mode: mem.Allocator_Mode,
	size, _alignment: int,
	old_ptr: rawptr,
	old_size: int,
	loc := #caller_location,
) -> (
	data: []byte,
	err: mem.Allocator_Error,
) {
	#partial switch mode {
	case .Alloc, .Alloc_Non_Zeroed:
		data, err = alloc_page(math.Size(size)), nil
	case .Free:
		free_error := page_free(old_ptr)
		data, err = nil, free_error ? .Invalid_Argument : .None
	case .Resize, .Resize_Non_Zeroed:
		data = alloc_page(math.Size(size))
		mem.copy(&data[0], old_ptr, min(size, old_size))
		free_error := page_free(old_ptr)
		err = free_error ? .Invalid_Argument : .None
	case .Query_Features:
		set := (^mem.Allocator_Mode_Set)(old_ptr)
		if set != nil {
			set^ = {.Alloc, .Alloc_Non_Zeroed, .Free, .Resize, .Resize_Non_Zeroed, .Query_Features}
		}
	case:
		data, err = nil, .Mode_Not_Implemented
	}
	return
}
pageAllocator :: proc() -> mem.Allocator {
	return mem.Allocator{procedure = pageAllocatorProc, data = nil}
}
*/
