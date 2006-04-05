# deps: assert.awk awkbot_awkbot_config.awk

BEGIN {
    if (ARGV[1]) conf = ARGV[1]
	else conf = "t/test_awkbot_config.conf"
	
	awkbot_config_load(conf)

    assert((awkbot_config("Test")    == 1), "Test failed")
    assert((awkbot_config("foo.bar") == 2), "Test failed")
    assert((awkbot_config("foo.baz") == 3), "Test failed")

    print "OKAY, Passed tests"
    print "This is 3:", awkbot_config("foo.baz")
    exit (0)
}

# getline
function gl(file, null	,t)	{ getline t < file; if (null) $0 = t; return t	}
function fs(f	,ofs, of)	{ ofs = FS; FS = "[ \t]*=[ \t]*"; of = $f
		FS = ofs; return of	}
# split
function sp(str, Arr, prefix	,A, i) { split(str, A); while (A[++i])
		if (prefix) Arr[prefix, i] = A[i]; else Arr[A[i]] = i # else: just set true
		return i }

function awkbot_config_load(file) {
	gl(file)

	if ($1 ~ /=/) {
		if ($1 ~ /\[\]$/) { # array, 
			if ($1 ~ /\[\w\]$/) { # 2d array
				
		awkbot[fs(1)] = fs(2)
