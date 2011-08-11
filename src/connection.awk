# A module which manages an IKC client connection
# -----------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 43) borrowed from FreeBSD's jail.c:
# <tag@cpan.org> wrote this file.  As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return.   Scott S. McCoy
# -----------------------------------------------------------------------------
# This module is started for each client connection.  It recieves read events
# for every message written to the connection, and redispatches them over
# the wire.  It also *sends* messages over the wire for each event recieved
# from the kernel.  All subscriptions by the client will be listed as this
# module.

#use log.awk

BEGIN {
    initialized = 0
}

# Enable event relaying (default)
{
    relay = 1
}

# XXX 2011-08-10T23:28:13Z-0700 None of the below makes sense right this
# minute.  connection should be a module which represents a foreign module, and
# dispatches each event recieved to that foreign module.  It should simply
# write, and never really *dispatch* anything locally.
#
# This is clearly too complicated.

# The special "__connect" event is fired.  Once this module recieves this event
# it will initialize a selector, after that all events which are not read
# events from the selector are written to the file
!initialized && $1 == "__connect" {
    file     = $2
    selector = file "-selector"

    debug("got connect event on %s", file)

    kernel_load("selector.awk", selector)
    kernel_send(selector, "select", this, file)

    relay       = 0
    initialized = 1
}


# Each read event that happens, gets sent to this file.
# We validate that the read event came for this file, otherwise other modules
# couldn't send "read" events, not that this is a typical use-case.
#
# TODO 2011-05-30T20:03:25Z-0700
# * Pass the calling module in the API
# * Create constants "CALLER", "EVENT", etc.
$1 == "read" && $2 == file {
    split($3, args)

    debug("dispatching %s:%s", args[1], args[2])

    kernel_send(args[1], args[2], args[3], args[4], args[5], args[6], args[7],
                args[8], args[9])

    relay = 0
}

relay {
    debug("relaying input: %s", $0)

    print $0 >> file
    
    # The close is for two reasons — first is, it creates an fflush(), which is
    # neccessary to ensure events are delivered in a timely fashion.  Second is
    # it ensures there are no hanging references on the fifo, so that if the
    # client closes the connection, it will create an EOF.
    close(file)
}
