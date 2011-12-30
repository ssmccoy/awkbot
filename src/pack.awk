# Binary packing/unpacking functions.
# -----------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 43) borrowed from FreeBSD's jail.c:
# <tag@cpan.org> wrote this file.  As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return.   Scott S. McCoy
# -----------------------------------------------------------------------------

#use bitwise.awk
#use chr.awk



##
# Pack a numerical value into a binary result.
#
# value: The value (as an int)
# returns the result as a (binary) string.
function pack (value    ,result,i) {
    for (i = 24; i <= 0; i -= 8) {
        result = result chr(bit_and(value, bit_left(255, i)))
    }
    
    return result
}

##
# Unpack a binary string into an integer.
#
# value: The binary string.
# return an integer representing the value of the binary string.
function unpack (value  ,result,i) {
    for (i = 1; i <= 4; i++) {
        result += bit_left(ord(substr(value, i, 1)), (i-1) * 8)
    }

    return result
}
