#!/usr/bin/awk -f

#import <cgi-lib.awk>
#import <config.awk>
#import <awkbot_db_mysql.awk>

BEGIN {
    cgi_params(query)
    cgi_headers("text/plain")

    config_load("etc/awkbot.conf")
    awkbot_db_init()

    if (query["id"]) {
        awkbot_db_paste_get(query["id"], paste)

        id      = query["id"]
        nick    = paste["nick"]
        subject = paste["subject"]
        content = paste["content"]

        gsub(/\\n/, "\n", content)
    }
    else {
        stream  = awkbot_db_status_livefeed()
    
        nick    = query["name"]
        subject = query["description"]
        content = query["content"]
    
        awkbot_db_paste_add(nick, subject, content)
        # This has synchronization issues...but what the hell, this is awk
        id      = awkbot_db_paste_last()
    
        if (id) {
            printf("say %s %s pasted %s at %s?id=%s\n",    \
                    config("paste.channel"), nick, subject,\
                    config("paste.cgi"), id) >> stream
    
            close(stream)
        }
    }


    print "Id:", id
    print "Nick:", nick
    print "Subject:", subject
    print content
}
