# Portable socket library
# -----------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 43) borrowed from FreeBSD's jail.c
# <tag@cpan.org> wrote this file.  As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return.   Scott S. McCoy
# -----------------------------------------------------------------------------

# I found I needed to use netcat for sockets even in gawk, so I would be able
# to have non-blocking input from the outside world by way of a tempfile.  So I
# realized I could actually have tcp sockets in all awks using the same method
# and decided to abstract it to a seperate library.

# Determine whether netcat or telnet are appropriate.  Favor netcat, and do
# nothing if the user specified one instead.
BEGIN {
    tempfile_command = "mktemp socket.XXXXX"

    if (!socket_catalyst) "which nc"     | getline socket_catalyst
    if (!socket_catalyst) "which telnet" | getline socket_catalyst
}

function socket_connect (host, port) {
    tempfile_command | getline fifo
    close(tempfile_command)

    system("rm " fifo)
    system("mkfifo " fifo)

    # Have the kernel load the selector module, under the generated name of the
    # fifo.
    kernel_load("selector.awk", fifo)

    # Start the socket process, or atleast create it's name.
    socket = sprintf("%s %s %s > %s", socket_catalyst, host, port, fifo)

    # Have the selector select all output from the fifo, and route it here
    # under the "read" event.
    kernel_send(fifo, "select", this, fifo)
}

function socket_read (sockname, input) {
    # Publish the input event to anyone listening...(?! should I be doing
    # this!?)  Maybe the listener should be a direct connection between the two
    # modules.  This will enter a for-loop in the kernel for each event.
    #
    # On the other hand, it's a way to test the pub-sub behavior.
    kernel_publish("read", input)
}

function socket_write (input) {
    print input | socket
}

# Close the socket by closing the input stream to the catalyst.  This should
# usually work without intervention, and a "disconnect" event will be received
# some time later as a result.
function socket_close () {
    close(socket)
    socket = ""
}

# Simply exit
function socket_disconnect () {
    kernel_shutdown()
}

"read"       == $1 { socket_read($2)       }
"write"      == $1 { socket_write($2)      }
"close"      == $1 { socket_close()        }
"connect"    == $1 { socket_connect($2,$4) }
"disconnect" == $1 { socket_disconnect()   }

# Shutdown handler, incase premature shutdown occurs, try not to leave any
# straggling processes about.
"fini" == $1 {
    if ("" != socket) {
        socket_close()
    }
}


## Usage
# kernel_load("socket.awk", "mysocket")
# kernel_send("mysocket", "connect", "irc.freenode.net", "6667")
# kernel_listen("mysocket", "read", "get_input")
#
# "get_input" == $1 { input = $2 }
