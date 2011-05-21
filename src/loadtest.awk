# Test how the kernel handles a million messages in a row (sequental)
# -----------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 43) borrowed from FreeBSD's jail.c:
# <tag@cpan.org> wrote this file.  As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return.   Scott S. McCoy
# -----------------------------------------------------------------------------

BEGIN { target = 1000000 }

"init" == $1 {
    kernel_send(this, "test", i)
}

"test" == $1 {
    if ($2 == target) {
        kernel_shutdown()
    }
    else {
        kernel_send(this, "test", $2 + 1)
    }
}

"fini" == $1 {
    kernel_send("testload.awk", "completed")
}
