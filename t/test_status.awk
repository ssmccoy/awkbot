#use time.awk
#use status.awk
#use assert.awk

$1 == "init" {
    assert(format_duration(86400), "1 days")
    assert(format_duration(3600), "1 hours")
    assert(format_duration(10240411), "4 months 6 days 12 hours 33 minutes 31 seconds")
    assert(format_duration(60), "1 minute")
    assert(format_duration(61), "1 minutes 1 seconds")

    kernel_shutdown()
}
