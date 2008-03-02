#!/usr/bin/awk -f

#import <cgi-lib.awk>
#import <config.awk>
#import <tempfile.awk>
#import <awkbot_db_mysql.awk>

BEGIN {
    cgi_params(query)
    cgi_headers("text/html")

    config_load("etc/awkbot.conf")
    awkbot_db_init()

    if (query["id"]) {
        awkbot_db_paste_get(query["id"], paste)

        id      = query["id"]
        nick    = paste["nick"]
        subject = paste["subject"]
        content = paste["content"]
        link    = sprintf("%s?id=%d", config("paste.cgi"), id)

        gsub(/\r\\n/, "\n", content)
        gsub(/\\\t/,  "\t", content)
        gsub(/\\\\/,  "\\", content) # Outcoming escapes
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

    workfile = tempfile("paste")
    template = workfile ".html"

    print content > workfile
    close(workfile)

    system("vim -i NONE -c \"syn on\" -c \"set syntax=awk\" -c \"set nu\"" \
            " -c TOhtml -c wq -c q " workfile " &> /dev/null")

    while (getline content < template) {
        print content

        # Ghetto little thing to inject a title
        if (content ~ /<body/) {
            print "<h1>AWK Paste:", "<a href=\"" link "\"/>" id "</a></h1>"
            print "<p><b>Nick:", nick, "<br/>"
            print "Subject:", subject, "<br/>"
            print "</b></p><hr/>"
        }
    }
    close(template)

#   print "Id:", id
#   print "Nick:", nick
#   print "Subject:", subject
#   print content

    system("rm " workfile)
    system("rm " template)
}
