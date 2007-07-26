#!/usr/bin/awk -f

#import <cgi-lib.awk>

BEGIN {
    cgi_params(query)
    cgi_headers("text/plain")

    for (key in query) {
        print key, ":", query[key]
    }
}
