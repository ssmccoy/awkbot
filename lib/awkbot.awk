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

    print "Using", awkbot_db_status_livefeed(), "as live feed from awkbot"

    # XXX Nasty hack, make this not need direct access to the irc array!
    irc["tempfile"] = awkbot_db_status_livefeed()
    irc_connect(config("irc.server"))
}

END {
    awkbot_db_status_connected(0)
}

# Nasty hack to clean up every few records
NR % 3 == 0 {
    print "DEBUG: Truncating file.."
    printf "" > irc["tempfile"] 
    fflush(irc["tempfile"])
    close(irc["tempfile"])
}
$1 == "say" { 
    _msg = $3
    for (i = 4; i < NF; i++) {
        _msg = _msg " " $i
    }
    print "Saying " _msg " to " $2
    irc_privmsg($2, _msg)
}

function irc_handler_error () {
    irc_connect(config("irc.server"))
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

function irc_handler_privmsg (nick, host, recipient, message, arg  \
    ,direct,target,address,action,c_msg,argc,t,q,a) {

    if (recipient ~ /^#/) target = recipient
    else                  target = nick

    # A special case...
    if (substr(arg[1], 0, length(irc["nickname"])) == irc["nickname"] &&
            arg[1] !~ irc["nickname"] "\\+\\+") {
        direct  = 1
        shift(arg)

        # Unfortunately, the API doesn't tell me how many arguments are
        # available...but I need the number of arguments to join.  I might want
        # to fix # this some day.
        argc = 0
        for (key in arg) argc++ 

        c_msg   = join(arg, 1, argc + 1, OFS)
    }
    else {
        direct  = (target != recipient)
        # It's either privmsg, or they're not talking to us, so the clean
        # message is the whole message.
        c_msg   = message
    }

    if (target == recipient) address = nick ": "
    else address = ""

    if (direct) {
        if (arg[1] == "karma") awkbot_karma_get(target,arg[2])
        else if (arg[1] == "forget") {
            awkbot_db_forget(join(arg,2,sizeof(arg),SUBSEP))
            irc_privmsg(target, address "what's a "join(arg,2,sizeof(arg))"?")
        }
        else if (arg[2] == "is") {
            awkbot_db_answer(arg[1], join(arg, 3, sizeof(arg), " "))
            irc_privmsg(target, address "Okay")
        }
        # It's only numbers and stuff
        else if (c_msg ~ /^[0-9^.*+\/() -]*$/) {
            irc_privmsg(target, address calc(c_msg)) 
        }
        else {
            q = gensub(/\?$/, "", "g", join(arg, 1, sizeof(arg), SUBSEP))
            if (a = awkbot_db_question(tolower(q))) 
                irc_privmsg(target, address a)
        }
    }

    if (match(arg[1], /^(.*)\+\+$/, t)) awkbot_db_karma_inc(t[1])
    if (match(arg[1], /^(.*)--$/, t)) awkbot_db_karma_dec(t[1])

    if (arg[1] == "awkdoc") {
        if (arg[2]) {
            irc_privmsg(target, address awkdoc(arg[2]))
        }
        else {
            irc_privmsg(target, address "Usage is awkdoc < identifier >")
        }
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
