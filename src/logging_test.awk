
"init" == $1 {
    print "module:init" >> "/dev/stderr"

    kernel_load("logger.awk", "logger")

    kernel_load("hello.awk", "hello")

    kernel_send("hello", "message")

    kernel_send("logger", "info", this, "This is a big, fat test...")

    print "module:end" >> "/dev/stderr"
}
