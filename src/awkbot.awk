# awkbot
# ----------------------------------------------------------------------------- 
# "THE BEER-WARE LICENSE" (Revision 43) borrowed from FreeBSD's jail.c: 
# <tag@cpan.org> wrote this file.  As long as you retain this notice you 
# can do whatever you want with this stuff. If we meet some day, and you think 
# this stuff is worth it, you can buy me a beer in return.   Scott S. McCoy 
# -----------------------------------------------------------------------------

#use module.awk
#use assert.awk
#use config.awk
#use trim.awk
#use log.awk
#use calc.awk

BEGIN {
    config_load("etc/awkbot.conf")

    assert(config("irc.username"), "username not specified in config")
    assert(config("irc.nickname"), "nickname not specified in config")
    assert(config("irc.altnick"), "altnick not specified in config")
    assert(config("irc.server"), "server not specified in config")
    assert(config("irc.port"), "port not specified in config")
}

function awkbot_init (stream,	logfile,loglevel,sockname) {
    # Set up the logger first, since everything else will try and write to it.
    kernel_load("logger.awk", "log")
    kernel_load("status.awk", "status")

    logfile  = config("logfile")
    loglevel = config("loglevel")

    if ("" != logfile) {
        kernel_send("log", "logfile", logfile)
    }

    if ("" != loglevel) {
        kernel_send("log", "level", "default", loglevel)
    }

    kernel_load(config("database"), "database")

    kernel_listen("database", "info",   "send_response")
    kernel_listen("database", "karma",  "send_response")
    kernel_listen("database", "answer", "send_response")

    kernel_load("uptime.awk", "uptime")
    kernel_listen("uptime",   "uptime", "send_response")

    kernel_send("database", "running", 1)
    kernel_send("database", "livefeed", stream)

    sockname = config("sockname")

    if ("" != sockname) {
	kernel_load("listener.awk", "listener")
	kernel_send("listener", "listen", sockname)
    }

    awkbot_connect()
}

function awkbot_connect (   server,port,nick,user,name) {
    kernel_load("irc.awk", "irc")

    server = config("irc.server")
    port   = config("irc.port")

    nick   = config("irc.nickname")
    user   = config("irc.username")
    name   = config("irc.realname")

    kernel_listen("irc", "connected")
    kernel_listen("irc", "privmsg")
    kernel_listen("irc", "ctcp_version")
    kernel_listen("irc", "error")

    kernel_send("irc", "server", server, port, nick, user, name)

    awkbot = nick
}

function awkbot_connected ( channel) {
    channel = config("irc.channel")

    if (channel) {
        kernel_send("irc", "join", config("irc.channel"))
    }

    kernel_send("database", "connected", 1)
}

# Handler for privmsg...
# This *should* be scriptable with some kind of rudementary meta-pattern
# matching, but it's inanely complex instead.  Making it scriptable would (or
# should) include having some expressions in a file, mappings of elements to
# those expressions to parameters and event names to publish when the action
# occurs, so that modules can simply register themselves to listen and react.
#
# These expressions could even be in a hash table, and modules could send them
# to us.
function awkbot_privmsg (recipient, nick, host, message \
			 ,target,prefix,m,address,action,terms)
{
    # If the user wasn't speaking to awkbot directly (private message) then
    # determine who they were addressing in a channel (potentially awkbot)
    if (recipient == awkbot) {
        address = awkbot
	target  = nick
	prefix  = ""
    }
    else {
        m       = match(message, /[[:punct:]]|[[:space:]]/)
        address = substr(message, 1, m - 1)
        message = trim(substr(message, m + 1))
	target  = recipient
	prefix  = sprintf("%s: ", nick)
    }

    # TODO All of the below should be scriptable... it makes no sense to have
    # one big fat routine doing all of this...
    split(message, terms, / */)

    # Modify karma (if it was for karma)
    if (match(terms[1], /^(.*)(\+\+|--)$/)) {
        m = substr(terms[1], 1, length(terms[1]) - 2)
	action = (substr(terms[1], length(terms[1]) - 1) == "++") ? \
	       "karma_inc" : "karma_dec"

        if (m == nick) {
	    kernel_send("irc", "msg", target, prefix "You can't do that")
        }
        else {
	    kernel_send("database", action, m)
        }

        # Karma must exit early because of the weird matching.
        return
    }

    # The user wasn't addressing us, ignored.
    if (address != awkbot) {
        return debug("message addressed to %s, not %s", address, awkbot) 
    }

    action = terms[1]

    # These first three should be generalized
    if (action == "uptime") {
        kernel_send("uptime", "uptime", target, prefix);
    }
    else if (action == "info") {
	kernel_send("database", "info", target, prefix, terms[2])
    }
    else if (action == "karma") {
	kernel_send("database", "karma", target, prefix, terms[2])
    }
    else if (action == "forget") {
	# length of "forget" + 2 (1 for space) 
	kernel_send("database", "forget", substr(message, 8))
    }
    else if (message ~ /^[0-9^.*+\/() -][0-9^.*+\/() -]*$/) {
	kernel_send("irc", "msg", target, prefix calc(message))
    }
    else if ((m = index(message, " is ")) > 0) {
	kernel_send("database", "answer", \
		    substr(message, 1, m - 1),
		    substr(message, m + 4))  # length of " is "
    }
    else {
	kernel_send("database", "question", target, prefix, message)
    }
}

# Respond to version requests as 'awkbot' with the github URL.
function awkbot_ctcp_version (recipient, nick, host) {
    debug("awkbot->ctcp_version(\"%s\", \"%s\", \"%s\")", \
          recipient, nick, host)

    kernel_send("irc", "reply", nick, "version", \
                "awkbot https://github.com/ssmccoy/awkbot")
}

## Send the result of a database query
# target: The recipient of the message
# prefix: The person to be addressed, if any
# result: The message to send.
function awkbot_send_result (target, prefix, result) {
    if ("" != result) {
	kernel_send("irc", "msg", target, prefix result)
    }
    else {
	kernel_send("irc", "msg", target, prefix "I don't know that")
    }
}

## We got an error from the IRC server.
# This means the connection was terminated.  Shut down the IRC module by
# sending it a disconnect (which should cause it to shut itself and it's socket
# down, which should shut down the selector) and then after a small delay,
# attempt to reconnect.
function awkbot_error () {
    kernel_send("database", "connected", 0)
    kernel_send("irc", "disconnect")

    # Wait 10 seconds before reconnecting, just to be polite
    system("exec sleep 10")
    awkbot_connect()
}

## Try an alternative nickname.
# Try the backup nickname, and create a new backup incase this doesn't work.
function awkbot_nickname (  altnick) {
    altnick = config("irc.altnick")

    kernel_send("irc", "nick", altnick)

    config("irc.altnick", altnick "-")
}

# -----------------------------------------------------------------------------
# The dispatch table

 "init"          == $1 { awkbot_init($2)               }
 "connected"     == $1 { awkbot_connected()            }
 "privmsg"       == $1 { awkbot_privmsg($2,$3,$4,$5)   }
 "ctcp_version"  == $1 { awkbot_ctcp_version($2,$3,$4) }
 "send_response" == $1 { awkbot_send_result($2,$3,$4)  }
 "error"         == $1 { awkbot_error()                }
 "nickname"      == $1 { awkbot_nickname()             }

