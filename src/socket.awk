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

#import <tempfile.awk>

# Determine whether netcat or telnet are appropriate.  Favor netcat, and do
# nothing if the user specified one instead.
BEGIN {
    socket_catalyst = "telnet"
    if (!socket_catalyst) "which nc"     | getline socket_catalyst
    if (!socket_catalyst) "which telnet" | getline socket_catalyst

    if (!socket_use_fifo != 0) {
        # If no one has set "use_fifo", then test to see if it's there and
        # assume we'll use it if it is...

        __socket_test_fifo = "which mkfifo"
        __socket_test_fifo | getline __socket_test

        if (__socket_test) {
            socket_use_fifo = 1
        }
        else {
            socket_use_fifo
        }

        close(__socket_test_fifo)
    }
}

##
# @param socket empty (becomes socket structure as an array)
# @param tempfile string if not present then one will be created for you
# @param writeonly boolean when true no tail process will be allocated
func socket_init (socket, tempfile, writeonly) {
    if (!tempfile) {
        tempfile = tempfile("tcp_socket")
    }
    
    socket["tempfile"] = tempfile

    if (socket_use_fifo) {
        # If we're in fifo mode, unlink the file and make it a fifo.
        system("unlink " tempfile)
        system("mkfifo " tempfile)
    }

    if (!writeonly) {
        # Allocate tempfile and tail by starting it
        print >> tempfile
        socket["input"] = "tail -f " tempfile
        socket["input"] | getline < writeonly
    }
}

##
# @param socket array socket (after calling socket_init)
# @param host string hostname or ip
# @param port integer TCP port number
func socket_connect (socket,host,port) {
    socket["output"] = socket_catalyst " " host " " port " > " \
        socket["tempfile"] " 2>&1"
    print "DEBUG: using " socket["output"]
    
    # Send zero bytes - just kick it off.
    socket_write(socket)
}

##
# @param socket array socket (after calling socket_connect)
# @param buffer string data to be sent
func socket_write (socket,buffer) {
    printf buffer | socket["output"]
    fflush(socket["output"])
}

##
# @param socket array socket (after calling socket_connect)
# @param data to send
func socket_read (socket    ,buffer) {
    socket["input"] | getline buffer
    return buffer
}

##
# @param socket array socket (after calling socket_connect)
func socket_close (socket) {
    if (!socket["output"]) {
        print "socket_close() called in an invalid socket" > /dev/stderr
    }

    if (socket["input"]) close(socket["input"])
    close(socket["output"])
}
