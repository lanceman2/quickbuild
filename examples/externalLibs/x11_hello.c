#include <stdio.h>
#include <X11/Xlib.h>

int main(void)
{
    Display *dsp;
    dsp = XOpenDisplay("");
    printf("XOpenDisplay=%p\n", dsp);
    return 0;
}
