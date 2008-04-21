#!/usr/bin/awk -f

#import <cgi-lib.awk>
#import <config.awk>
#import <tempfile.awk>
#import <awkbot_db_mysql.awk>
#include "config.h"

BEGIN {
    cgi_params(query)
    config_load("etc/awkbot.conf")
    awkbot_db_init()

    if (query["id"]) {
        if (awkbot_db_paste_get(query["id"], paste)) {
            id      = query["id"]
            nick    = paste["nick"]
            subject = paste["subject"]
            content = paste["content"]
            link    = sprintf("%s?id=%d", config("paste.cgi"), id)

            gsub(/\r\\n/, "\n", content) # CRLF to LF
# This should be dealt with in mysql.awk
#           gsub(/\\t/,   "\t", context) # Outcoming tabs.
            gsub(/\\\\/,  "\\", content) # Outcoming escapes
        }
        else {
            print "Location: /404.html" 
            print ORS
            exit
        }
    }
    else {
        stream  = awkbot_db_status_livefeed()
    
        nick    = query["name"]
        subject = query["description"]
        content = query["content"]
    
        awkbot_db_paste_add(nick, subject, content)
        # This has synchronization issues...but what the hell, this is awk
        id      = awkbot_db_paste_last()
        link    = sprintf("%s?id=%d", config("paste.cgi"), id)
    
        if (id) {
            printf("say %s %s pasted %s at %s\n",    \
                    config("paste.channel"), nick, subject,\
                    link) >> stream
    
            close(stream)
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
        hilight = "highlight -I -l -k monospace -S awk"

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
