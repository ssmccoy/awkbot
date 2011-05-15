# awkbot
# ----------------------------------------------------------------------------- 
# "THE BEER-WARE LICENSE" (Revision 43) borrowed from FreeBSD's jail.c: 
# <tag@cpan.org> wrote this file.  As long as you retain this notice you 
# can do whatever you want with this stuff. If we meet some day, and you think 
# this stuff is worth it, you can buy me a beer in return.   Scott S. McCoy 
# -----------------------------------------------------------------------------

#import <assert.awk>
#import <config.awk>
#import <awkbot_db_mysql.awk>
#import <irc.awk>
#import <awkdoc.awk>
#import <join.awk>
#import <queue.awk>

#define TEST 1

#ifdef TEST
BEGIN {
    print "Awkbot is starting up..."
}
#else
BEGIN {
    print "This program needs to be loaded with awkpp"
    exit
}
#endif

BEGIN {
    VERSION = "awkbot $Revision: 412 $"

    config_load("etc/awkbot.conf")

    assert(config("irc.username"), "username not specified in config")
    assert(config("irc.nickname"), "nickname not specified in config")
    assert(config("irc.altnick"), "altnick not specified in config")
    assert(config("irc.server"), "server not specified in config")

    awkbot_db_init()

    irc_set("debug",    config("irc.debug"))

    irc_set("nickname", config("irc.nickname"))
    irc_set("username", config("irc.username"))
    irc_set("realname", config("irc.realname"))

    irc_register("connect")
    irc_register("privmsg")
    irc_register("ctcp")
    irc_register("error")

    awkbot_db_status_running(1)

    print "Using", awkbot_db_status_livefeed(), "as live feed from awkbot"

    # XXX Nasty hack, make this not need direct access to the irc array!
    irc["tempfile"] = awkbot_db_status_livefeed()
    irc_connect(config("irc.server"))
}

END {
    awkbot_db_status_connected(0)
    awkbot_db_status_running(0)
}

function reconnect () {
    # Close the socket before reconnecting, this ensures a new process will
    # be created...otherwise she'll just idle...
    irc_sockclose()
    awkbot_db_status_running(1)
    awkbot_db_status_connected(0)
    irc_connect(config("irc.server"))
}

# When the connection gets closed, restart the conversation...
/^Terminated/ || /^Connection closed/ {
    reconnect()
}

$1 == "quit" {
    _msg = $2

    for (i = 3; i <= NF; i++) {
        _msg = _msg " " $i
    }

    irc_quit(_msg)
}

$1 == "say" {
    _msg = $3

    for (i = 4; i <= NF; i++) {
        _msg = _msg " " $i
    }

    irc_privmsg($2, _msg)
}


function irc_handler_error () {
    reconnect()
}

function irc_handler_connect (  channel,key,msg) { 
    split(config("irc.channel"), channel)
    for (key in channel) irc_join("#" channel[key]) 

    msg = config("irc.startup")

    if (msg) irc_sockwrite(msg "\r\n")

    awkbot_db_status_connected(1)
}

function irc_handler_ctcp (nick, host, recipient, action, argument) {
    # Don't respond to channel ctcps
    if (recipient !~ /\#/) {
        if (tolower(action) == "version") {
            irc_ctcp_reply(nick, action, VERSION)
        }

        else if (tolower(action) == "ping") {
            irc_ctcp_reply(nick, action, argument)
        }
    }
}

func calc (expr ,result,bc) {
    bc = "bc -q"
    print "scale=10" |& bc
    print expr       |& bc
    print "quit"     |& bc
    bc |& getline result
    close(bc)

    # coerce to number
    return result + 0
}

function irc_handler_privmsg (nick, host, recipient, message, argc, arg  \
    ,direct,target,address,action,c_msg,larg,t,q,a,s)
{
    if (recipient ~ /^#/) target = recipient
    else                  target = nick

#    print "irc_handler_privmsg(", nick "," host "," recipient "," \
#        message "," argc ")" >> "debug.log"

    # A special case...
    if (substr(arg[1], 0, length(irc["nickname"])) == irc["nickname"] &&
            arg[1] !~ irc["nickname"] "\\+\\+")
    {
#        print "irc_handler_privmsg", "direct channel message" >> "debug.log"

        direct  = 1
        # Join the second word until the end as the cleaned message.
        c_msg   = join(arg, 2, argc + 1, OFS)

        # Remove the first item from the list of args...
        shift(arg, argc--)
    }
    else {
#        print "irc_handler_privmsg", "private message" >> "debug.log"

        direct  = (target != recipient)
        # It's either privmsg, or they're not talking to us, so the clean
        # message is the whole message.
        c_msg   = message
    }

    # Last arg is the arg count + 1
    larg = argc + 1

    # The "clean" message
#    print "irc_handler_privmsg", "cleaned message:", c_msg >> "debug.log"

    if (target == recipient) address = nick ": "
    else address = ""

    if (direct) {
#        print "The message was directed as me" >> "debug.log"

        if (arg[1] == "karma") {
#            print "irc_handler_privmsg", "command", "karma" >> "debug.log"
            awkbot_karma_get(target,arg[2])
        }
        else if (arg[1] == "forget") {
#            print "irc_handler_privmsg", "command", "forget" >> "debug.log"
            awkbot_db_forget(join(arg,2,argc,SUBSEP))
            irc_privmsg(target, address "what's a "join(arg,2,larg)"?")
        }
        else if (arg[2] == "is") {
#            print "irc_handler_privmsg", "command", "remember" >> "debug.log"
            awkbot_db_answer(arg[1], join(arg, 3, larg, " "))
            irc_privmsg(target, address "Okay")
        }
        # It's only numbers and stuff
        else if (c_msg ~ /^[0-9^.*+\/() -][0-9^.*+\/() -]*$/) {
#            print "irc_handler_privmsg", "command", "calc" >> "debug.log"
            irc_privmsg(target, address calc(c_msg)) 
        }
        else if (arg[1] == "uptime") {
#            print "irc_handler_privmsg", "command", "uptime" >> "debug.log"
            a = awkbot_db_uptime();
            irc_privmsg(target, address a)
        }
        else {
#            print "irc_handler_privmsg", "command", "QnA" >> "debug.log"

            # Portable equivilent of
            # q = gensub(/\?$/, "", "g", join(arg, 1, sizeof(arg), SUBSEP))
            q = join(arg, 1, larg, SUBSEP)
            gsub(/\?$/, "", q)

            if (a = awkbot_db_question(tolower(q))) {
                irc_privmsg(target, address a)
            }

#            print "irc_handler_privmsg", "QnA", "q:", q, "a:", a >> "debug.log"
        }
    }

    if (match(arg[1], /^(.*)\+\+$/)) {
        s = substr(arg[1], length(arg[1]) - 1)

        if (s == nick) {
            irc_privmsg(target, address "changing your own karma is bad karma")
            awkbot_db_karma_dec(nick)
        }
        else {
            awkbot_db_karma_inc(s)
        }
    }
    if (match(arg[1], /^(.*)--$/)) {
        s = substr(arg[1], length(arg[1]) - 1)

        if (s == nick) {
            irc_privmsg(target, address "don't be dumb")
            awkbot_db_karma_dec(nick)
        }
        else {
            awkbot_db_karma_dec(s)
        }
    }

    if (arg[1] == "awkdoc") {
        irc_privmsg(target, address "awkdoc is temporarily disabled")

#       if (arg[2]) {
#           irc_privmsg(target, address awkdoc(arg[2]))
#       }
#       else {
#           irc_privmsg(target, address "Usage is awkdoc < identifier >")
#       }
    }
    else if (arg[1] == "awkinfo") {
        if (arg[2]) {
            a = awkbot_db_info(arg[2])

            if (a) {
                irc_privmsg(target, address a)
            }
            else {
                irc_privmsg(target, address "I don't know anything about " \
                        arg[2])
            }
        }
        else {
            irc_privmsg(target, address "Usage is awkinfo < keyword >")
        }
    }
    else if (arg[1] == nick) {
        irc_privmsg(target, address "Talking about yourself, are we?")
    }
}

function awkbot_karma_get (reply_to,nickname     ,points)  {
    points = awkbot_db_karma(nickname)
    irc_privmsg(reply_to, sprintf("Karma for %s: %d points", nickname, points))
}
