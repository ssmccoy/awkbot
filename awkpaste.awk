#!/usr/bin/awk -f

BEGIN {
    params(Query)
    for (key in Query) {
        print key, ":", Query[key]
    }
}
