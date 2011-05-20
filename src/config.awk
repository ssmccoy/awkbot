# awkbot/config.awk - A library for simple configuration file parsing
# ----------------------------------------------------------------------------- 
# "THE BEER-WARE LICENSE" (Revision 43) borrowed from FreeBSD's jail.c: 
# <tag@cpan.org> wrote this file.  As long as you retain this notice you 
# can do whatever you want with this stuff. If we meet some day, and you think 
# this stuff is worth it, you can buy me a beer in return.   Scott S. McCoy 
# -----------------------------------------------------------------------------

#use assert.awk

function config_load (filename) {
    _config["config", "filename"] = filename
    config_parse(_config, 0, filename)
}

# Recurse over new levels
function config_parse (config_data,level,filename ,l,t,s,current,closing) {
    if (config_data["debug"])
        printf "config_parse(ARRAY, %s, %s)\n", level, filename

    while ( getline < filename ) {

        sub(/^[\t ]*#.*$/, "")

        if (config_data["debug"]) {
            printf "read:%s:%d %s\n", filename, NR, $0 > "/dev/stderr"
            print "Current namespace", level > "/dev/stderr"
        }

        if (/<[^\/][^>]*>/) {
            match($0, /<[^\/][^>]*>/)

            s = substr($0, RSTART + 1, RLENGTH - 2)

            if (config_data["debug"]) print "Opening: ", s > "/dev/stderr"
            if (level) config_parse(config_data, level SUBSEP s, filename)
            else config_parse(config_data, s, filename)
        }
        else if (/<[\/][^>]*>/) {
            match($0, /<[\/]([^>]*)>/)

            s = substr($0, RSTART + 2, RLENGTH - 3)

            t = split(s, l, SUBSEP)
            closing = l[t]
            t = split(level, l, SUBSEP)
            current = l[t]

            if (config_data["debug"])
                print "Open", current, "close", closing > "/dev/stderr"

            assert((current == closing), "Inconsistent open/close tags")
            return
        }
        else if (match($0, /([^ ][^ ]*)[ ][ ]*([^ ].*)/)) {

            split(substr($0, RSTART), l, /[ ][ ]*/)

            l[2] = substr($0, RSTART + length(l[1]))

            sub(/^[ ][ ]*/, "", l[2])

            if (level) {
                if (config_data["debug"]) {
                    print level "." l[1], "=", l[2] > "/dev/stderr"
                }

                config_data[level, l[1]] = l[2]
            }
            else {
                if (config_data["debug"]) {
                    print l[1], "=", l[2] > "/dev/stderr"
                }

                config_data[l[1]] = l[2]
            }
        }
    }
}

function config (item, value    ,element) {
    # Portable equivilent...
    # element = gensub(/\./, SUBSEP, "g", item)

    element = item
    gsub(/\./, SUBSEP, element)
    
    if (value) _config[element] = value

    if (_config["debug"]) 
        print "config():", item, "(" element ")", value > "/dev/stderr"

# We should just treat undefined stuff as undefined *shrug*    
#    assert(_config[element], "config(): " element " is of no value")
    return _config[element]
}
