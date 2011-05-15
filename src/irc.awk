#!/usr/bin/awk -f
# vim600:set ts=4 sw=4 expandtab cin nowrap:

# AWK irc library -> irc.pod for details
# -----------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 43) borrowed from FreeBSD's jail.c
# <tag@cpan.org> wrote this file.  As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return.   Scott S. McCoy
# -----------------------------------------------------------------------------

# This library implements the IRC protocol only.  An example of how to make it
# work with gawk's /inet/tcp is provided below.

#import <socket.awk>

# -----------------------------------------------------------------------------
# Event traps

$0 == "INIT"    { irc_parse_init()      }
$2 == "001"     { irc_parse_connect()   }
$2 == "PRIVMSG" { irc_parse_privmsg()   }
$1 == "ERROR"   { irc_parse_error()     }
$2 == "INVITE"  { irc_parse_invite()    }
$1 == "PING"    { irc_parse_ping()      }

# -----------------------------------------------------------------------------
# Event handlers
function irc_parse_init() {
    if (irc["register", "initialize"]) irc_handler_initialize()
}
function irc_parse_connect () {
    if (irc["register", "connect"]) irc_handler_connect()
}

# :tag!~tag@c-67-183-29-168.client.comcast.net PRIVMSG #awk :OK
function irc_parse_privmsg (    argc,arg,i,t,s,nick,host,recipient,msg) {
    if ($0 ~ /\x01.*\x01\r/) {
        if (irc["register", "ctcp"]) {
            # This is the real biatch!
#           match($0, ":([^!]*)!([^ ]*) PRIVMSG ([^ ]*) :([^\r]*)", t)
            split($0, t, /(:|!|\r| PRIVMSG )/)

            match(t[5], ":\x01([A-Z][A-Z]*)")

            # Snag the first word and save it in arg[1
            arg[1] = substr(t[5], RSTART + 2, RLENGTH - 3)

            # Save the end of it's index
            i = (RSTART + 2) + (RLENGTH - 3)

            # Now match the whole string until the \x01
            match($0, ":\x01([^\x01]*)\x01")

            # Copy from the end-index of the first word until the last \x01,
            # giving the second half of the string (plus a whitespace)
            arg[2] = substr(t[5], i + 1, RLENGTH - (i + 3))

            irc_handler_ctcp(t[2], t[3], t[4], arg[1], arg[2])
        }
    }
    else {
        if (irc["register", "privmsg"]) {
            i = index($0, "!")

            nick = substr($0, 2, i - 2)

            t = index($0, " ")

            host = substr($0, i + 1, t - i - 1)

            # Chomp all the parsed bits off the string
            s = substr($0, t + 9)

            recipient = substr(s, 1, index(s, " ") - 1)

            msg = substr(s, index(s, ":") + 1)

            argc = split(msg, arg)
            irc_handler_privmsg(nick, host, recipient, msg, argc, arg)
        }
    }
}

function irc_parse_invite () { return }
function irc_parse_ping () { 
    if (irc["register", "ping"]) irc_handler_ping($2)

    irc_sockwrite("PONG " $2 "\r\n") 
}
function irc_parse_error (  message) {
    if (irc["register", "error"]) irc_handler_error()

    irc_sockclose()
}

# -----------------------------------------------------------------------------
# Runtime Control API
function irc_register   (event)     { irc["register", event] = 1 }
function irc_unregister (event)     { irc["register", event] = 0 }
function irc_error      (message)   { print message; exit(1);    }

# -----------------------------------------------------------------------------
# Connection API
function irc_privmsg (target, message) {
    irc_sockwrite(sprintf("PRIVMSG %s :%s", target, message))
}

function irc_ctcp (target, type, arg) {
    irc_sockwrite(sprintf("PRIVMSG %s :\x01%s %s\x01", target, type, arg))
}

function irc_ctcp_reply (target, type, arg) {
    irc_sockwrite(sprintf("NOTICE %s :\x01%s %s\x01", target, type, arg))
}

function irc_join (channel) {
    irc_sockwrite(sprintf("JOIN %s", channel))
}

function irc_part (channel, message) {
    irc_sockwrite(sprintf("PART %s :%s", channel, message))
}

function irc_quit (message) {
    irc_sockwrite(sprintf("QUIT :%s", message))
}

function irc_connect (server    ,t,host,port) { 
    # Pull host and port from host:port string
    split(server, t, /:/)

    host = t[1]
    port = t[2] ? t[2] : 6667

    socket_init(irc_socket, irc["tempfile"], !irc["tailpipe"])
    socket_connect(irc_socket, host, port)

    irc_sockwrite("NICK " irc["nickname"])
    irc_sockwrite("USER " irc["username"] " a a :" irc["realname"])
}

function irc_set (key, value) { irc[key] = value }

# -----------------------------------------------------------------------------
# Raw internals

# Now just wraps socket_write
function irc_sockwrite (data) {
    socket_write(irc_socket, data "\r\n")
}

# Just wraps socket_close
function irc_sockclose () {
    socket_close(irc_socket)
}

# -----------------------------------------------------------------------------
# This is an example main loop, awkbot used to use it.  I keep it in this
# source file only as an example, and will some day soon move it out into a
# test suite or some other bit of code.  This code is well tested, and works
# like a charm, without flooding the filesystem with too much data.
#
# # Initialization
#
# BEGIN {
#     if (!irc["tempfile"]) irc["tempfile"] = irc_allocate_tempfile()
# 
#     print "INIT" > irc["tempfile"]
#     close(irc["tempfile"])
# 
#     ARGV[ARGC++] = irc["tempfile"] 
# }
# 
# # Cleanup
#
# END {
#     system(sprintf("rm %s", irc["tempfile"]))
# }
# 
# # Main loop
# 
# { 
#
#     if (irc["using_inet_tcp"] && irc["socket"]) {
#         # Get next line from socket and put in file for parsing
#         irc["socket"] |& getline
#     
#         # Cycle Tempfile every 1000th line.
#         if (FNR == 1000) {
#             print > irc["tempfile"]
#             ARGV[ARGC++] = FILENAME
#             delete ARGV[ARGC - 2]
#         } 
#         
#         # Write to tempfile for next iteration
#         else print >> irc["tempfile"] 
#         close(irc["tempfile"])
# 
#         if (irc["debug"]) print
#     }
# }

END { if (irc["socket"]) close(irc["socket"]) }

