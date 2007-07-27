#import <irc.awk>
BEGIN {
    irc_set("debug", 1)

#    irc_register("initialize")
    irc_register("connect")
    irc_register("privmsg")

    irc_set("nickname", "awklibirc")
    irc_set("realname", "Testing irc.awk")
    irc_set("username", "tag")
    irc_connect("irc.freenode.net", "6667")
}

#function irc_handler_initialize () {
#}

function irc_handler_connect () {
    irc_join("#awk")
}

function irc_handler_privmsg (message,arg) {
    print message
}
