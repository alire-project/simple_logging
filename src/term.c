#include <stdbool.h>
#include <sys/ioctl.h>
#include <termios.h>

bool ioctl_failure = false;

int simple_logging_term_width(void)
{
	struct winsize x;
	int r;

	if (ioctl_failure) return -1;
	r = ioctl(2, TIOCGWINSZ, &x);

	if (r != 0) {
		ioctl_failure = true;
		return -1;
	} else {
		return x.ws_col;
	}
}
