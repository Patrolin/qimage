// zig cc demo/perf/file_read_async/io_ring.c -shared -o demo/perf/file_read_async/io_ring.dll
//#define NTDDI_VERSION 167772171
#include <ntstatus.h>
#define WIN32_NO_STATUS
#include <Windows.h>
#include <ioringapi.h>
#include <winternl.h>
#include <ntioring_x.h>
#include <assert.h>

HRESULT __stdcall MyCreateIoRing(
  IORING_VERSION      ioringVersion,
  IORING_CREATE_FLAGS flags,
  UINT32              submissionQueueSize,
  UINT32              completionQueueSize,
  HIORING             *h
) {
  return CreateIoRing(ioringVersion, flags, submissionQueueSize, completionQueueSize, h);
};

#if !(NTDDI_VERSION >= NTDDI_WIN10_CO)
  "NT version is too low";
#endif
#if !(WINAPI_FAMILY_PARTITION(WINAPI_PARTITION_APP))
  "whatever this means";
#endif
