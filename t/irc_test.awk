#import <irc.awk>
BEGIN {
    exit(0); # skip test for now...
    irc_set("debug", 1)

#    irc_register("initialize")
    irc_register("connect")

    irc_set("nickname", "awklibirc_t")
    irc_set("realname", "Testing irc.awk")
    irc_set("username", "tag")
    irc_connect("irc.freenode.net", "6667")
}

#function irc_handler_initialize () {
#}

function irc_handler_connect () {
    exit(0);
}
