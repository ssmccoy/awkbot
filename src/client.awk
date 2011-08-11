# An inter-kernel/module client.
# -----------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 43) borrowed from FreeBSD's jail.c:
# <tag@cpan.org> wrote this file.  As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return.   Scott S. McCoy
# -----------------------------------------------------------------------------

#use mkfifo.awk
#use tempfile

BEGIN {
    connection = ""
    # TODO We obviously need an mkfifo
    tempfile_command = "mktemp client.XXXXX"
}

# Send, because we have to know we're supposed to send, each event is truncated
# by one argument.  Sorry.
function client_send (component, message, a1,a2,a3,a4,a5,a6,a7,a8) {
    print component, message, a1,a2,a3,a4,a5,a6,a7,a8 >> connection
    fflush(connection)
}

function remove (filename) {
    system("exec rm " filename)
}

# Message the kernel that we need to send them a message
function client_connect (listener) {
    connection = stream

    fifo = tempfile("client")

    remove(fifo)

    mkfifo(fifo)

    print "connect", fifo >> listener

    # Cause the selector to start reading from our special fifo the other
    # kernel has been made aware of
    kernel_load("selector.awk", fifo)
    kernel_send(fifo, "select", this, fifo)
}

## Register the client module to listen for an event on the other server.
function client_listen (component, event, handler) {
    # fifo is the special module name we hold on the other kernel.
    client_send("kernel", "listen", component, event, fifo, handler)
}

## Read a message our component recieved, and publish it as an event.
function client_read (file, message	,a) {
    split(message, a)

    kernel_publish(a[1],a[2],a[3],a[4],a[5],a[6],a[7],a[8],a[9])
}

function client_disconnect (source) {
    if (source == fifo) {
	# The selector sent us this disconnect, so assume it's shut itself
	# down.
	kernel_shutdown()
    }
    else {
	# Oherwise it was a user telling us to disconnect, in which case we ask
	# the other kernel to close our pipe (hopefully causing the fifo to
	# send us a disconnect, and thus allowing us to fully shutdown)
	client_send("kernel", "shutdown", fifo)
    }
}

function client_fini () {
    if (connection) {
	close(connection)
    }
}

# -----------------------------------------------------------------------------
# Dispatch table.
# When used as a module, the client module effectively becomes a special type
# of selector.

"connect"    == $1 { client_connect($2)                       }
"read"       == $1 { client_read($2,$3,$4,$5,$6,$7,$8,$9,$10) }
"send"       == $1 { client_send($2,$3,$4,$5,$6,$7,$8,$9)     }
"listen"     == $1 { client_listen($2,$3,$4,$5)               }
"shutdown"   == $1 { client_shutdown()                        }
"disconnect" == $1 { client_disconnect($2)                    }
"fini"       == $1 { client_fini()                            }

## Usage
# kernel_load("client.awk", "client")
# kernel_send("client", "connect", "other_kernel_stream")
# kernel_send("client", "listen", "component", "event", "handler")
#
# kernel_listen("client", "handler", "module_handler")
#
# When "component" publishes "event" on the remote kernel, it will send this
# the client a "handler" message which will be republished as an event.
