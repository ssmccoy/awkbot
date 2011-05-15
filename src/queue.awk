# queue.awk - Utilities to use an array as a queue
# ----------------------------------------------------------------------------- 
# "THE BEER-WARE LICENSE" (Revision 43) borrowed from FreeBSD's jail.c: 
# <tag@cpan.org> wrote this file.  As long as you retain this notice you 
# can do whatever you want with this stuff. If we meet some day, and you think 
# this stuff is worth it, you can buy me a beer in return.   Scott S. McCoy 
# -----------------------------------------------------------------------------

#import <assert.awk>

function push (array, value,i) {
    i = sizeof(array) + 1
    array[i] = value
    return value
}

function pop (array     ,value,i) {
    i = sizeof(array)

    if (! i) return

    value = array[i]
    delete array[i]

    return value
}

function shift (array   ,len,value,i) {
    if (! array[1]) return

    value = array[1]

    # This is a funky and slow loop...
    for (i = 2; len ? i < len : array[i]; i++)
        array[i - 1] = array[i]

    delete array[i - 1]
    return value
}

# These are all slow, but this one is exceptionally bad.  I have to iterate the
# entire length of the array twice, once forward to find the numerical end,
# once back to move the values.  To the best of my knowledge, this is the only
# way we're going to do this
function unshift (array,value   ,i) {
    for (i = sizeof(array); i > 0; i--) array[i + 1] = array[i]

    # Should be a safe assumption, this obviously has limitations
    array[1] = value
}

function sizeof (array    ,i) {
    i = 1
    while (array[i] || (array[i] == "0")) i++
    return (i - 1)
}

function merge  (from,to   ,lf,lt,i) {
    lf = sizeof(from);
    lt = sizeof(to);

    for (i = lt + 1; i < lf + lt; i++)
        to[i] = from[i - lt]
}

function splice (result,array,off,len,  ins     ,i) {
}
