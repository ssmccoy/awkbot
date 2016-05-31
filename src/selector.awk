# -----------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 43) borrowed from FreeBSD's jail.c:
# <tag@cpan.org> wrote this file.  As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return.   Scott S. McCoy
# -----------------------------------------------------------------------------
# Simple selector module, it stops recieving events once it accepts a "select"
# message, to keep that safe, disconnects itself from the kernel but stays
# alive in a local loop.  It should terminate cleanly once an EOF is seen from
# the stream it's selecting.

#use module.awk

BEGIN { running = 0 }

# Once this message is recieved, the selector will recieve no more messages.
# It's important that no one messages this module since such messages will
# deadlock the kernel.  I've tried numerous paths, but there is no way around
# this behavior while maintaining proper cleanup routines (calling close() on a
# pipe seems to invoke a waitpid) so it must be known.
"select" == $1 {
    module   = $2
    filename = $3

    kernel_send("log", "debug", this, "select routine started")

    while ((getline input < filename) > 0) {
        sub(/\r$/, "", input)
        kernel_send(module, "read", this, input)
    }

    close(filename)

    # Once the stream ends, the selector will send a disconnect signal
    kernel_send(module, "disconnect", this)

    # After sending the disconnect event, request the shutdown, closing our
    # resources in the kernel and etc.
    kernel_shutdown()
}
