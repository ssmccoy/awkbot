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
    debug("listening on %s", sockname)

    fifo = sockname

    # If we try to read from the file and it's a fifo, we stall the module.  To
    # avoid this happening, we just remove the file under all conditions and
    # then make a new fifo.  This potentially creates a race condition, but
    # testing the file first caused even more problems.
    remove(fifo)
    mkfifo(fifo)

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
    print "init" >> fifo

    debug("init complete")
}

function listener_read (file, input   ,argc,args,filename,i) {
    debug("incoming message %s", input)

    argc = split(input, args, SUBSEP)

    if (input == "init") {
        debug("successfully listening")
    }
    # TODO Rename this to __connect, as it's a special "module" name.
    else if (args[1] == "connect") {
        filename = args[2]
        
        debug("new connection at %s", filename)

        kernel_load("connection.awk", filename)
        #
        # 2011-09-13T14:36:44Z-0700 TODO: Okay, this is all screwed up.  The
        # listener creates a "connection" out of a fifo.  The client and the
        # connection are listening on this connection — and then the connection
        # module is relaying messages to this connection.  It makes no sense.
        # What is needed is a very simple method where a client module can
        # subscribe to events which are ultimately sent to it's fifo.  The
        # client has a selector for the fifo, so nothing of this sort needs
        # done here.  A placeholder process for each fifo *does* need created
        # on the server side, but it needs to do nothing other than relay
        # messages to the fifo and shutdown when requested.
        # 
        # kernel_send(filename, "__connect", filename)
    }
    else if (args[1] == "disconnect") {
        # Simply force the kernel to send a fini 
        filename = args[2]

        kernel_send("kernel", "shutdown", filename)
    }
    else {
        # If it's a message intended for this kernel (i.e. not a connect
        # request), then simply fire that bad-boy off.
        kernel_send(args[1], args[2], args[3], args[4], args[5], args[6],
                    args[7], args[8], args[9]);
    }
}

# When we get the shutdown event, stop the fifo listener module by closing the
# open handle.  If any clients are hanging onto this fifo, it'll stay open, but
# an EOF will be emitted finally when all clients let go of it, causing the
# listener process to clean up.
function listener_fini () {
    close(fifo)
}

$1 == "listen" { listener_listen($2)  }
$1 == "read"   { listener_read($2,$3) }
$1 == "fini"   { listener_fini()      }
