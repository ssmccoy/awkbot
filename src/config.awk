# awkbot/config.awk - A library for simple configuration file parsing
# ----------------------------------------------------------------------------- 
# "THE BEER-WARE LICENSE" (Revision 43) borrowed from FreeBSD's jail.c: 
# <tag@cpan.org> wrote this file.  As long as you retain this notice you 
# can do whatever you want with this stuff. If we meet some day, and you think 
# this stuff is worth it, you can buy me a beer in return.   Scott S. McCoy 
# -----------------------------------------------------------------------------
# deps: assert.awk

function config_load (filename) {
    _config["config", "filename"] = filename
    config_parse(_config, 0, filename)
}

# Recurse over new levels
function config_parse (config_data,level,filename    ,l,t,current,closing) {
    if (config_data["debug"]) 
        printf "config_parse(ARRAY, %s, %s)\n", level, filename

    while ( getline < filename ) {
        # Strip coments
        sub(/#.*$/, "")

        if (config_data["debug"]) {
            printf "read:%s:%d %s\n", filename, NR, $0
            print "Current namespace", level
        }

        if (/<[^/][^>]*>/) {
            match($0, /<([^/][^>]*)>/, l)
            if (config_data["debug"]) print "Opening: ", l[1]
            if (level) config_parse(config_data, level SUBSEP l[1], filename)
            else       config_parse(config_data, l[1],              filename)
        }
        else if (/<[/][^>]*>/) {
            match($0, /<[/]([^>]*)>/, l)
            t = split(l[1], l, SUBSEP)
            closing = l[t]
            t = split(level, l, SUBSEP)
            current = l[t]

            if (config_data["debug"]) print "Open", current, "close", closing
            assert((current == closing), "Inconsistent open/close tags")
            return
        }
        else {
            if (match($0, /([^ ][^ ]*)[ ]*(..*)/, l)) {
                if (config_data["debug"]) print level SUBSEP l[1], "=", l[2]
                if (level) config_data[level, l[1]] = l[2]
                else       config_data[l[1]]        = l[2]
            }
        }
    }
}

function config (item, value    ,element) {
    element = gensub(/\./, SUBSEP, "g", item)
    
    if (value) _config[element] = value
    if (_config["debug"]) print "config():", item, "(" element ")", value
# We should just treat undefined stuff as undefined *shrug*    
#    assert(_config[element], "config(): " element " is of no value")
    return _config[element]
}
