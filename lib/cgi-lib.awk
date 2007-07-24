BEGIN {
    if (ENVIRON["REQUEST_METHOD"] == "POST") 
        while ( getline ) _cgilib_in = _cgilib_in $0
    if (ENVIRON["REQUEST_METHOD"] == "GET")
        _cgilib_in = ENVIRON["QUERY_STRING"]

# Set this globally so we don't have to ensure it happens anywhere else...
    ORS = "\r\n"
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
