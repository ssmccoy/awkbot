# A simple fifo-based psuedo-socket listener.
# -----------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 43) borrowed from FreeBSD's jail.c:
# <tag@cpan.org> wrote this file.  As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return.   Scott S. McCoy
# -----------------------------------------------------------------------------
# This module creates a named fifo, and treats it as a psuedo-socket listener.

#use mkfifo.awk
#use exists.awk
#use remove.awk
#use log.awk

function listener_listen (sockname) {
    fifo = sockname

    # Ensure the given "file" both exists and is a fifo.
    if (!exists(fifo)) {
        mkfifo(fifo)
    }
    else {
        remove(fifo)
        mkfifo(fifo)
    }

    debug("created fifo %s", fifo)

    kernel_load("selector.awk", fifo)
    kernel_send(fifo, "select", this, fifo)

    # "open" the file, this prevents rogue EOFs from occurring, since we keep
    # it open for writing (but never write to it).  When we get the shutdown,
    # we'll close it causing an EOF.
    
    # This blocks until the selector reads it.  The block shouldn't last long,
    # because the selector should already be actively reading from the pipe.
    # As soon as that kicks off, this releases and the kernel should shortly
    # after pick up the read event from the selector.
#    print "init" >> fifo
}

function listener_read (file, input   ,args,filename) {
    debug("incoming message %s", input)

    split(input, args)

    if (input == "init") {
        # Noop.
    }
    else if (args[1] == "connect") {
        filename = args[2]
        
        debug("new connection at %s", filename)

        kernel_load("connection.awk", filename)
        kernel_send(filename, "__connect", filename)
    }
}

$1 == "listen" { listener_listen($2) }
$1 == "read"   { listener_read($2,$3)   }
