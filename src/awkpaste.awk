#!/usr/bin/awk -f

#import <cgi-lib.awk>
#import <config.awk>
#import <tempfile.awk>
#import <awkbot_db_mysql.awk>
#import <module.awk>
#include "config.h"

BEGIN {
    cgi_params(query)
    config_load("etc/awkbot.conf")
    awkbot_db_init()

    if (query["id"]) {
        if (awkbot_db_paste_get(query["id"], paste)) {
            id       = query["id"]
            nick     = paste["nick"]
            subject  = paste["subject"]
            language = paste["language"]
            content  = paste["content"]
            link    = sprintf("%s?id=%d", config("paste.cgi"), id)
        }
        else {
            print "Location: /404.html" 
            print ORS
            exit
        }
    }
    else {
        stream  = awkbot_db_status_livefeed()

	# This is a really big hack so that kernel publishing will work.
        # There *is* a better way to do this, but I want to quit working on
        # this project for a while
	_k_pipeline = stream
    
	nick     = query["name"]
	subject  = query["description"]
	content  = query["content"]
	language = query["language"]

        errmsg  = ""

        if (length(nick) == 0) {
            errmsg = errmsg \
                     "<b>Unable to submit paste, no name supplied</b><br/>"
        }
        if (length(subject) == 0) {
            errmsg = errmsg \
                     "<b>Unable to submit paste, no description " \
                      "supplied</b><br/>"
        }
        if (length(content) == 0) {
            errmsg = errmsg \
                     "<b>Unable to submit paste, no content to paste!</b><br/>"
        }

        if (length(errmsg)) {
            print "Content-Type: text/html"
            print ORS
            print "<html><head><title>Input Validation Error</title></head>"
            print "<body><span style=\"color: red\">"
            print errmsg 
            print "</span></body></html>"
            exit 1
        }
    
        awkbot_db_paste_add(nick, subject, language, content)
        # This has synchronization issues...but what the hell, this is awk
        id      = awkbot_db_paste_last()
        link    = sprintf("%s?id=%d", config("paste.cgi"), id)
    
        if (id) {
	    message = sprintf("%s pasted \"%s\" at %s", nick, subject, link)
	    kernel_send("irc", "msg", config("paste.channel"), message)

            print "Location:", link
            print ORS
            exit 1
        }
    }

    if (query["view"] == "text") {
        cgi_headers("text/plain")
        print content
        exit
    }
    else {
        cgi_headers("text/html")

#define TEMPLATE_FILE                   \
        workfile = tempfile("paste");   \
        template = workfile ".html";    \
                                        \
        print content > workfile;       \
        close(workfile)

#ifdef VIM
        TEMPLATE_FILE

        system("vim -i NONE -c \"syn on\" -c \"set syntax=awk\" " \
               " -c \"set nu\" -c TOhtml -c wq -c q " workfile " &> /dev/null")

        while (getline content < template) {
#else
#ifdef GAWK
        hilight = "highlight -I -l -k monospace -S " language

        print content |& hilight
        close(hilight, "to")

        while (hilight |& getline content) {
#else
        TEMPLATE_FILE

        system("highlight -I -l -k monospace -S awk -o " template " " workfile)

        while (getline content < template) {
#endif
#endif
            if (content ~ /<\/body>/) {
                printf "<a href=\"%s?id=%s&view=text\">Plain Text</a>",\
                    config("paste.cgi"), id
                printf " | <a href=\"%s\">Create a new Paste</a>\r\n", \
                    config("paste.form")
            }

            print content

            # Ghetto little thing to inject a title
            # works in both gawk and vim... 
            if (content ~ /<body/) {
                print "<h1>AWK Paste:", "<a href=\"" link "\">" id "</a></h1>"
                print "<p><b>Nick:", nick, "<br>"
                print "Subject:", subject, "<br>"
                print "</b></p><hr>"
            }
        }
#define CLEANUP_FILE            \
        system("rm " workfile); \
        system("rm " template)

#ifdef VIM
        CLEANUP_FILE
#else
#ifndef GAWK
        CLEANUP_FILE
#else
        close(hilight, "from")
#endif
#endif
    }
}
