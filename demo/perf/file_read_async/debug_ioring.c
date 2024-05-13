// cl demo/perf/file_read_async/debug_ioring.c -L onecore.lib
//#define NTDDI_VERSION 0x0A00000B
//#define WINAPI_FAMILY 2
#include <windows.h>
#include <ioringapi.h>
#include <stdio.h>

#if !(NTDDI_VERSION >= NTDDI_WIN10_CO)
  "NT version is too low";
#endif
#if !(WINAPI_FAMILY_PARTITION(WINAPI_PARTITION_APP))
  "not compiling for desktop/phone";
#endif

const s1 = sizeof(HIORING);
const s2 = sizeof(IORING_VERSION);
const s3 = sizeof(IORING_CREATE_REQUIRED_FLAGS);
const s4 = sizeof(IORING_CREATE_FLAGS);
const s5 = sizeof(IORING_INFO);
const s6 = sizeof(UINT32);
const s7 = sizeof(SYSTEM_LOGICAL_PROCESSOR_INFORMATION);

int main() {
  HIORING ioring = 0;
  IORING_CREATE_FLAGS flags = {0};
  CreateIoRing(IORING_VERSION_1, flags, 8, 8, &ioring);
  printf("ioring: %llx", (UINT64)ioring);
  return 0;
}
