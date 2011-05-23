# ----------------------------------------------------------------------------- 
# "THE BEER-WARE LICENSE" (Revision 43) borrowed from FreeBSD's jail.c: 
# <tag@cpan.org> wrote this file.  As long as you retain this notice you 
# can do whatever you want with this stuff. If we meet some day, and you think 
# this stuff is worth it, you can buy me a beer in return.   Scott S. McCoy 
# -----------------------------------------------------------------------------

# Keep support for CPP (for awkpaste, for now)
#import <config.awk>
#import <mysql.awk>

# Also support module loading...
#use config.awk
#use mysql.awk
#use log.awk

function awkbot_db_init () {
    config_load("etc/awkbot.conf")

    mysql_login(config("mysql.username"), config("mysql.password"))
    mysql_db(config("mysql.database"))
}

function awkbot_db_karma_inc (nick,amount   ,rv,row) {
    # the "0" is because undefined == 0 is true, we want to see if its actually
    # exactly zero.
    if ((amount != "0") && ! amount) amount = 1;
    rv = mysql_query("select * from karma where nick = " mysql_quote(nick))

    mysql_fetch_assoc(rv, row)
    mysql_finish(rv)
    row["karma"] += amount

    mysql_finish(mysql_query("replace into karma (nick,karma) values (" \
                mysql_quote(nick) ", " row["karma"] ")"))
}

function awkbot_db_karma_dec (nick,amount,rv,row) {
    if ((amount != "0") && ! amount) amount = 1;
    rv = mysql_query("select * from karma where nick = " mysql_quote(nick))

    mysql_fetch_assoc(rv, row)
    mysql_finish(rv)
    row["karma"] -= amount

    mysql_finish(mysql_query("replace into karma (nick,karma) values (" \
                mysql_quote(nick) ", " row["karma"] ")"))
}

function awkbot_db_karma (nick  ,rv,row) {
    rv = mysql_query("SELECT karma FROM karma WHERE nick = " mysql_quote(nick))

    mysql_fetch_assoc(rv,row)
    mysql_finish(rv)

    return 0 + row["karma"]
}

function awkbot_db_question (question   ,rv,row) {
    rv = mysql_query("SELECT answer FROM qna WHERE question = " \
            mysql_quote(question))

    mysql_fetch_assoc(rv, row)
    mysql_finish(rv)

    return row["answer"]
}

function awkbot_db_answer (question,answer) {
    mysql_finish(mysql_query("INSERT INTO qna (question, answer) " \
            " VALUES (" mysql_quote(question) "," mysql_quote(answer) ")"))

    return 1
}

function awkbot_db_forget (question) {
    debug("database->forget(\"%s\")", question)

    mysql_finish(mysql_query("DELETE FROM qna WHERE question = " \
                mysql_quote(question)))
    return 1
}

function awkbot_db_status_running (running) {
    mysql_finish(mysql_query("UPDATE status SET running = " \
        (running ? 1 : 0)))

    if (! running) {
        mysql_finish(mysql_query("UPDATE status SET livefeed = NULL"))
        mysql_finish(mysql_query("UPDATE status SET started = NULL"))
    }
    else {
        mysql_finish( \
                mysql_query("UPDATE status SET started = CURRENT_TIMESTAMP"))
    }
}

function awkbot_db_status_connected (connected) {
    mysql_finish(mysql_query("UPDATE status SET connected = " \
        (connected ? 1 : 0)))
}

function awkbot_db_status_livefeed (filename    ,rv,row) {
    if (filename) {
        mysql_finish(mysql_query("UPDATE status SET livefeed = " \
                    mysql_quote(filename)))
    }
    else {
        rv = mysql_query("SELECT livefeed FROM status")
        
        mysql_fetch_row(rv, row)
        filename = row[1]

        mysql_finish(rv)
    }

    return filename
}

function awkbot_db_info (keyword    ,result,rv,row) {
    rv = mysql_query("select keyword, text from info where keyword like " \
            mysql_quote(keyword "%"))

    if (mysql_fetch_assoc(rv, row)) { 
        result = row["keyword"] row["text"]
    }
    else {
        result = 0
    }

    mysql_finish(rv)

    return result
}

function awkbot_db_paste_add (nick, description, language, content) {
    mysql_finish(mysql_query("INSERT INTO paste (nick, subject, language, "\
                "content) VALUES (" mysql_quote(nick) "," \
                        mysql_quote(description) "," \
                        mysql_quote(language) "," \
                        mysql_quote(content) ")"))
}

function awkbot_db_paste_get (id,row    ,rv,result) {
    rv = mysql_query("SELECT paste_id, nick, subject, language, content " \
       "FROM paste WHERE paste_id = " mysql_quote(id))

    result = mysql_fetch_assoc(rv, row)
    mysql_finish(rv)
    return result
}

function awkbot_db_paste_last (     result,row,rv) {
    rv = mysql_query("SELECT max(paste_id) as paste_id FROM paste");

    if (mysql_fetch_assoc(rv, row)) {
        result = row["paste_id"]
    }

    mysql_finish(rv)

    return result
}

function awkbot_db_uptime (     result,row,rv) {
    rv = mysql_query("SELECT TIMEDIFF(CURRENT_TIMESTAMP, started)" \
        "AS uptime FROM status");

    if (mysql_fetch_assoc(rv, row)) {
        result = row["uptime"]
    }

    mysql_finish(rv)

    return result
}

# -----------------------------------------------------------------------------
# Modularization - This is a little more than a dispatch table, the following
# ports an unmodifiable old API to make this code a pub/sub module.  This
# leaves the old API unchanged, with one exception - the awkbot_db_init()
# method now loads the config file (this is necessary, since it will be in a
# separate process in the new awkbot), causing awkpaste to parse the config
# file twice.

"init" == $1 { awkbot_db_init() }

# Read messages publish their results... second and third parameters are
# "state" parameters for the listeners.

"uptime"   == $1 { kernel_publish("uptime", $2, $3, awkbot_db_uptime())     }
"info"     == $1 { kernel_publish("info",   $2, $3, awkbot_db_info($4))     }
"karma"    == $1 { kernel_publish("karma",  $2, $3, awkbot_db_karma($4))    }
"question" == $1 { kernel_publish("answer", $2, $3, awkbot_db_question($4)) }

# Write messages are just mapped

"forget"    == $1 { awkbot_db_forget($2)           }
"answer"    == $1 { awkbot_db_answer($2,$3)        }
"livefeed"  == $1 { awkbot_db_status_livefeed($2)  }
"karma_inc" == $1 { awkbot_db_karma_inc($2)        }
"karma_dec" == $1 { awkbot_db_karma_dec($2)        }
"connected" == $1 { awkbot_db_status_connected($2) }
"running"   == $1 { awkbot_db_status_running($2)   }
"livefeed"  == $1 { awkbot_db_status_livefeed($2)  }
