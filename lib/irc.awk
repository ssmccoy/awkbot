#!/usr/bin/awk -f
# vim600:set ts=4 sw=4 expandtab cin nowrap:

# AWK irc library -> irc.pod for details
# -----------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 43) borrowed from FreeBSD's jail.c
# <tag@cpan.org> wrote this file.  As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return.   Scott S. McCoy
# -----------------------------------------------------------------------------

# Init

BEGIN {
    if (!irc["tempfile"]) irc["tempfile"] = irc_allocate_tempfile()

    print "INIT" > irc["tempfile"]
    close(irc["tempfile"])

    ARGV[ARGC++] = irc["tempfile"] 
}

END {
    system(sprintf("rm %s", irc["tempfile"]))
}


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
function irc_parse_privmsg (    arg,i,t) {
    if ($0 ~ /\x01.*\x01\r/) {
        if (irc["register", "ctcp"]) {
            match($0, ":([^!]*)!([^ ]*) PRIVMSG ([^ ]*) :([^\r]*)", t)
            match($0, ":\x01([A-Z][A-Z]*) ?([^\x01]*)\x01", arg)
            irc_handler_ctcp(t[1], t[2], t[3], arg[1], arg[2])
        }
    }
    else {
        if (irc["register", "privmsg"]) {
            match($0, ":([^!]*)!([^ ]*) PRIVMSG ([^ ]*) :([^\r]*)", t)
            split(t[4], arg)
            irc_handler_privmsg(t[1], t[2], t[3], t[4], arg)
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
    irc_sockwrite(sprintf("PRIVMSG %s :%s\r\n", target, message))
}

function irc_ctcp (target, type, arg) {
    irc_sockwrite(sprintf("PRIVMSG %s :\x01%s %s\x01\r\n", target, type, arg))
}

function irc_ctcp_reply (target, type, arg) {
    irc_sockwrite(sprintf("NOTICE %s :\x01%s %s\x01\r\n", target, type, arg))
}

function irc_join (channel) {
    irc_sockwrite(sprintf("JOIN %s\r\n", channel))
}

function irc_part (channel, message) {
    irc_sockwrite(sprintf("PART %s :%s\r\n", channel, message))
}

function irc_quit (message) {
    irc_sockwrite(sprintf("QUIT :%s\r\n", message))
}

function irc_connect (host, port) { 
    irc_sockopen(host, port) 
    irc_sockwrite("NICK " irc["nickname"] "\n")
    irc_sockwrite("USER " irc["username"] " a a :" irc["realname"] "\r\n")
}

function irc_set (key, value) { irc[key] = value }

# -----------------------------------------------------------------------------
# Raw internals

function irc_allocate_tempfile (    mktemp,tempfile) {
    if (! irc["command", "mktemp"]) mktemp = "mktemp /tmp/irc.awk.XXXXXX"
    else mktemp = irc["command", "mktemp"]

    mktemp | getline tempfile
    close(mktemp)

    return tempfile
}

function irc_sockwrite (data) {
    if (irc["socket"]) printf data |& irc["socket"]
    else irc_error("Attempt to write" data " to closed socket")

    if (irc["debug"]) printf "> %s\n", data
}

function irc_sockopen (host,port    ,t) {
    if (! irc["socket"]) {
        if (! port) {
            if (host !~ /:/) {
                irc_error("irc_sockopen called without port number")
            }

            split(host,t,/:/)
            host = t[1]
            port = t[2]
        }

        irc["socket"] = "/inet/tcp/0/" host "/" port
    }
}

function irc_sockclose () {
    if (irc["socket"]) {
        close(irc["socket"])
        delete irc["socket"]
    }
    else irc_error("irc_sockclose called with no open socket")
}

# -----------------------------------------------------------------------------
# Main loop

{ 
    if (irc["socket"]) {
        # Get next line from socket and put in file for parsing
        irc["socket"] |& getline
    
        # Cycle Tempfile every 1000th line.
        if (FNR == 1000) {
            print > irc["tempfile"]
            ARGV[ARGC++] = FILENAME
            delete ARGV[ARGC - 2]
        } 
        
        # Write to tempfile for next iteration
        else print >> irc["tempfile"] 
        close(irc["tempfile"])

        if (irc["debug"]) print
    }
}

END { if (irc["socket"]) close(irc["socket"]) }

