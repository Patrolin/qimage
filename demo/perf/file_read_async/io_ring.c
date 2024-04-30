// cl -TC -c demo/perf/file_read_async/io_ring.c /Fo:demo/perf/file_read_async/io_ring.obj
// lib -nologo demo/perf/file_read_async/io_ring.obj -out:demo/perf/file_read_async/io_ring.lib
#define NTDDI_VERSION 0x0A00000B
#define WINAPI_FAMILY 2
#include <windows.h>
#include <ioringapi.h>

/*int main(
) {
  HIORING handle = 0;
  IORING_CREATE_FLAGS flags = {0};
  printf("hello\n");
  CreateIoRing(IORING_VERSION_1, flags, 8, 8, &handle); // NOTE: this works
  printf("world, %lx", handle);
  return 0;
};*/

int foo_add_int(int a, int b) {
    return a + b;
}

void* MyCreateIoRing() {
  HIORING handle = 0;
  IORING_CREATE_FLAGS flags = {0};
  CreateIoRing(IORING_VERSION_1, flags, 8, 8, &handle);
  return handle;
}

#if !(NTDDI_VERSION >= NTDDI_WIN10_CO)
  "NT version is too low";
#endif
#if !(WINAPI_FAMILY_PARTITION(WINAPI_PARTITION_APP))
  "whatever this means";
#endif
