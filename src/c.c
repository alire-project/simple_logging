#include <stdio.h>

void sl_flush_stdout(void) {
    // Flush the standard output stream using standard C library function
    fflush(stdout);
}