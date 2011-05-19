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

"select" == $1 {
    module   = $2
    filename = $3

    # Disconnects itself from the kernel...
    kernel_shutdown()
}

# Now disconnected, spiral off into our own process (this is a very abusive way
# to use the fini message, but it should work perfectly).

"fini" == $1 {
    if (filename) {
	# Goes into local loop until stream ends
	while ((getline input < filename) > 0) {
	    kernel_send(module, "read", this, input)
	}

	# Once the stream ends, the selector will send a disconnect signal
	kernel_send(module, "disconnect", this)
    }
}
