# A simple time module
# -----------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 43) borrowed from FreeBSD's jail.c:
# <tag@cpan.org> wrote this file.  As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return.   Scott S. McCoy
# -----------------------------------------------------------------------------

BEGIN {
    TIMEPRG = "date '+%s'"
}

function time (   r) {
    TIMEPRG | getline r

    close(TIMEPRG)

    return r
}
