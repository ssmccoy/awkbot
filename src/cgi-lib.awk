
#import <chr.awk>

BEGIN {
    if (ENVIRON["REQUEST_METHOD"] == "POST") 
        while ( getline ) _cgilib_in = _cgilib_in $0
    if (ENVIRON["REQUEST_METHOD"] == "GET")
        _cgilib_in = ENVIRON["QUERY_STRING"]

# Set this globally so we don't have to ensure it happens anywhere else...
    ORS = "\r\n"
}

function uri_decode (string     ,i,len,result) {
    # for portability, we have to continuously work in the argument provided...
    # standard awk has no Nth match
    len = length(string)

    while ((i = index(string, "%")) && i + 2 <= len) {
        result = result substr(string, 1, i - 1)
        result = result chr(dec( substr(string, i + 1, 2) ))
        string = substr(string, i + 3)
    }

    result = result string

    gsub("+", " ", result)
    return result
}

function cgi_params (query    ,each,pairs,i) {
    split(_cgilib_in, pairs, /\&/)
    i = 0    

    while (pairs[++i]) {
        split(pairs[i], each, /=/)

        # This assumes no encoding will exist in keys...typically a safe
        # assumption, but not necessarily always true
        query[each[1]] = uri_decode(each[2])
    }
}

function cgi_headers (content_type, headers) {
    print "Content-Type:", content_type
    
    for (key in headers) {
        print key ":", headers[key]
    }

    printf ORS
}
