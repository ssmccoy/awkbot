# ----------------------------------------------------------------------------- 
# "THE BEER-WARE LICENSE" (Revision 43) borrowed from FreeBSD's jail.c: 
# <tag@cpan.org> wrote this file.  As long as you retain this notice you 
# can do whatever you want with this stuff. If we meet some day, and you think 
# this stuff is worth it, you can buy me a beer in return.   Scott S. McCoy 
# -----------------------------------------------------------------------------
# deps: assert.awk mysql.awk

#include <assert.awk>
#include <mysql.awk>

BEGIN {
    # Config wont get parsed until awkbot's BEGIN {} block
    irc_register("initialize")
}

function irc_handler_initialize () {
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
    mysql_finish(mysql_query("DELETE FROM qna WHERE question = " \
                mysql_quote(question)))
    return 1
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
