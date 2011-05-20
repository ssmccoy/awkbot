# Trim all whitespace from the beginning and end of a string.
# -----------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 43) borrowed from FreeBSD's jail.c:
# <tag@cpan.org> wrote this file.  As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return.   Scott S. McCoy
# -----------------------------------------------------------------------------

function trim (string	,l) {
    while (substr(string, 1, 1) ~ /[\t ]/) {
	string = substr(string, 2)
    }

    l = length(string)

    while (substr(string, l) ~ /[\t ]/) {
	string = substr(string, 1, --l)
    }

    return string
}
