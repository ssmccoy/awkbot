# crand.awk - return an integer between 0 and cieling
# ----------------------------------------------------------------------------- 
# "THE BEER-WARE LICENSE" (Revision 43) borrowed from FreeBSD's jail.c: 
# <tag@cpan.org> wrote this file.  As long as you retain this notice you 
# can do whatever you want with this stuff. If we meet some day, and you think 
# this stuff is worth it, you can buy me a beer in return.   Scott S. McCoy 
# -----------------------------------------------------------------------------

function crand (ceil) {
    return sprintf("%d", (rand() * ceil))
}

function rcrand (ceil) {
    return sprintf("%d", ((rand() * ceil) + 1))
}
