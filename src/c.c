#include <sys/types.h> # Needed on macOS to get FILE definition early
#include <stdio.h>

void sl_flush_stdout(void) {
    // Flush the standard output stream using standard C library function
    fflush(stdout);
}