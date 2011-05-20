# A module system for POSIX-Compatible AWK processes.
# -----------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 43) borrowed from FreeBSD's jail.c:
# <tag@cpan.org> wrote this file.  As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return.   Scott S. McCoy
# -----------------------------------------------------------------------------

function kernel_send (component, operation, a1,a2,a3,a4,a5,a6,a7,a8,a9,o,f) {
    print component, operation, a1,a2,a3,a4,a5,a6,a7,a8,a9,o,f >> _k_pipename
    fflush(_k_pipename)
}

function kernel_load (source, name) {
    kernel_send("kernel", "load", source, name)
}

function kernel_listen (component, event, handler) {
    if ("" == handler) {
        handler = event
    }

    kernel_send("kernel", "listen", component, event, this, handler)
}

function kernel_clear (component, event, handler) {
    kernel_send("kernel", "clear", component, event, this, handler)
}

function kernel_shutdown () {
    kernel_send("kernel", "shutdown", this)
}

function kernel_publish (event, a1,a2,a3,a4,a5,a6,a7,a8,a9) {
    kernel_send("kernel", "publish", this, event, a1,a2,a3,a4,a5,a6,a7,a8,a9)
}

BEGIN {
    if (ARGC != 3) {
        this = ARGV[--ARGC]
    }
    else {
        print "initlization error: expected pipe and component name" >> \
            "/dev/stderr"

        exit 1
    }

    # Make the field separators SUBSEP so spaces don't blow up in message
    # arguments.  This means modules have to be coherent of that fact...
    FS = OFS = SUBSEP
}

"init" == $1 {
    _k_pipename = $2
}
