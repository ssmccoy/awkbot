# A module system for POSIX-Compatible AWK processes.
# -----------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 43) borrowed from FreeBSD's jail.c:
# <tag@cpan.org> wrote this file.  As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return.   Scott S. McCoy
# -----------------------------------------------------------------------------

function kernel_send (component, operation, message) {
    print component, operation, message >> _k_pipename
}

function kernel_register (operation) {
    kernel_send("kernel", "register", operation)
}

function kernel_unregister (component, operation) {
    kernel_send("kernel", "unregister", \
                sprintf("%s %s", component, operation))
}

function kernel_shutdown () {
    kernel_send("kernel", "shutdown", this)
}

BEGIN {
    if (ARGC != 3) {
        this        = ARGV[--ARGC]
    }
    else {
        print "initlization error: expected pipe and component name" >> \
            "/dev/stderr"

        exit 1
    }

    # Make the field separators SUBSEP so spaces don't blow up in message
    # arguments.  This means modules have to be coherent of that fact...
    FS = OFS = SUBSEP

    getline

    if ($1 == "init") {
        _k_pipename = $2
    }
    else {
        kernel_send("logger", "error", "module not poperly initialized")
    }

    printf "module %s loaded\n", this >> "/dev/stderr"
}
