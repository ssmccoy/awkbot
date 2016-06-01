# An awkbot module for calculating uptime in a POSIX environment.
# -----------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 43) borrowed from FreeBSD's jail.c:
# <tag@cpan.org> wrote this file.  As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return.   Scott S. McCoy
# -----------------------------------------------------------------------------

#use module.awk
#use assert.awk
#use time.awk

function uptime_init () {
    start_time = time()
}

function format_duration (duration  ,offsets,labels,i,r,l,s) {
    r = split("1,60,60,24,7,4", offsets, /,/)
    l = split("seconds,minutes,hours,days,weeks,months", labels, /,/)

    assert( l == r, "Illegal state: number of errors and offsets differ" )

    # Accumulate the offsets to toward the right
    for (i = 3; i <= l; i++) {
        offsets[i] = offsets[i] * offsets[i-1]
    }

    r = ""

    for (i = l; i >= 1; i--) {
        if (duration >= offsets[i]) {
            s = sprintf("%d", duration / offsets[i])
            
            duration = duration % offsets[i]

            r = r (r ? " " : "") s " " labels[i]
        }
    }

    return r
}

function uptime () {
    return time() - start_time
}

 "init"   == $1 { uptime_init()                                               }
 "uptime" == $1 { kernel_publish("uptime", $2, $3, format_duration(uptime())) }
