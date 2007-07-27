BEGIN {
    if (ENVIRON["REQUEST_METHOD"] == "POST") 
        while ( getline ) _cgilib_in = _cgilib_in $0
    if (ENVIRON["REQUEST_METHOD"] == "GET")
        _cgilib_in = ENVIRON["QUERY_STRING"]

# Set this globally so we don't have to ensure it happens anywhere else...
    ORS = "\r\n"

    # Handle uploads...

    # gawk only
    match(HEADER["Content-Disposition"], / filename="([^;]*)"/, r)
    filename = r[1] ? r[1] : "multipart/mixed"

    if (filename && multipart) {
        tempfilename = tempfile("cgi-awk")
    }

    # When it's multipart, save headers and body together
    if (multipart) {
        for (key in HEADER) print key ":", HEADER[key] >> tempfilename
        print "\r\n" >> tempfilename
    }

    while (buffersize < length(input)) {
        getline i
        print i >> tempfile
    }

    print cgi_read_buffer() >> tempfilename
}

function cgi_params (query    ,each,pairs,i) {
    split(_cgilib_in, pairs, /\&/)
    i = 0    
    while (pairs[++i]) {
        split(pairs[i], each, /=/)
        query[each[1]] = each[2]
    }
}

function cgi_headers (content_type, headers) {
    print "Content-Type:", content_type
    
    for (key in headers) {
        print key ":", headers[key]
    }

    printf ORS
}
