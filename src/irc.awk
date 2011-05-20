# AMS IRC module
# -----------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 43) borrowed from FreeBSD's jail.c
# <tag@cpan.org> wrote this file.  As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return.   Scott S. McCoy
# -----------------------------------------------------------------------------

## Load the socket module, but do not connect to anything.
# This means one instance of the IRC module is required per IRC connection.
function irc_init () {
    socket = this "-sock"

    kernel_load("socket.awk", socket)
}

# Clean up by disconnecting the socket.  This doesn't happen elsewhere, so we
# assume the socket is still around.
function irc_fini () {
    kernel_send(socket, "disconnect")
}

## Connect to the IRC server
function irc_server (host, port, nickname, username, realname) {
    printf "irc->server(\"%s\",%s,\"%s\",\"%s\",\"%s\")\n", \
           host, port, nickname, username, realname >> "/dev/stderr"

    irc["nickname"] = nickname
    irc["username"] = username
    irc["realname"] = realname

    kernel_send(socket, "connect", host, port)

    kernel_send(socket, "write", "NICK " nickname)
    kernel_send(socket, "write", "USER " username " a a :" realname)
    kernel_listen(socket, "read", "input")
}

## Join the given channel
function irc_join (channel) {
    kernel_send(socket, sprintf("JOIN %s", channel))
}

## Private message the given target
function irc_msg (target, message) {
    kernel_send(socket, sprintf("PRIVMSG %s :%s", target, message))
}

## Send a notice
function irc_notice (target, message) {
    kernel_send(socket, sprintf("PRIVMSG %s :%s", target, message))
}

# -----------------------------------------------------------------------------
# Protocol parsing and event handling

## Return the multiword part of this string.
#
# The IRC Protocol prefixes multiword parameters with ":".  This will return
# the multiword segment from a raw message, with the ":" trimmed.
function string (payload) {
    return substr(payload, index(payload, ":") + 1)
}

## Wrap a message in ctcp characters
function ctcp (payload) {
    return sprintf("%c%s%c", 1, payload, 1)
}

## Parse a CTCP message.
#
# Parse a CTCP message and dispatch a corresponding event.  If the message was
# a NOTICE, which sent CTCP "PING", the "ctcp_ping_response" event is
# dispatched.
function irc_parse_ctcp (type, recipient, nick, host, message   \
                         ,action,param,event)
{
    # Trim the 0x01's
    message = substr(message, 2, length(message) - 2)

    # The first word is the action
    action = lower(substr(message, 1, index(message, " ") - 1))

    # The parameters are the rest...
    param = substr(message, length(action) + 2)

    # Respond to pings automatically
    if (action == "ping" && type == "PRIVMSG") {
        irc_notice(nick, ctcp(message))
    }

    event = sprintf("ctcp_%s%s", action, (type == "NOTICE" ? "_response" : ""))

    kernel_publish(event, param)
}

## Parse an IRC message (either PRIVMSG or NOTICE), and publish the event.
#
# Given a message, parse out the nickname, hostmask, message itself and
# recipient and dispatch a "privmsg" or "notice" event for them, assuming they
# are not CTCP.  If the message is a CTCP message, irc_parse_ctcp does the
# dispatching.
#
# payload: The raw payload from the socket.
# fields: Each word separated as an array
function irc_parse_message (payload, fields     ,b,nick,host,type,message) {
    # Payload itself is a multiword message.
    payload = string(payload)

    b    = index(payload, "!")
    nick = substr(payload, 1, b)
    host = substr(payload, b, length(fields[1]))

    type      = fields[2]
    recipient = fields[3]

    # Subsequent message body is multiword, too
    message = string(payload)

    if (substr(message, 1, 1) == sprintf("%c", 1)) {
        irc_parse_ctcp(type, recipient, nick, host, message)
    }
    else {
        kernel_publish(tolower(type), recipient, nick, host, message)
    }
}

## Parse a raw IRC protocol message
function irc_parse_input (payload ,fields) {
    split(payload, fields, / /)

    printf "irc->input(\"%s\")\n", fields[2] >> "/dev/stderr"

    if (fields[1] == "PING") {
        kernel_send(socket, "write", sprintf("PONG %s", fields[2]))
    }
    if (fields[1] == "ERROR") {
        kernel_publish("error", string(payload))
    }
    if (fields[2] == "001") {
        kernel_publish("connected")
    }
    if (fields[2] == "PRIVMSG") {
        irc_parse_message(payload, fields)
    }
    if (fields[2] == "NOTICE") {
        irc_parse_message(payload, fields)
    }
}

# -----------------------------------------------------------------------------
# Dispatch table

"init"   == $1 { irc_init()                 }
"server" == $1 { irc_server($2,$3,$4,$5,$6) }
"join"   == $1 { irc_join($2)               }
"msg"    == $1 { irc_msg($1,$2)             }
"input"  == $1 { irc_parse_input($2)        }
"quit"   == $1 { irc_quit($2)               }
"fini"   == $1 { irc_fini()                 }
