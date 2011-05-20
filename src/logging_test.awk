
"init" == $1 {
    print "module:init" >> "/dev/stderr"

    kernel_load("logger.awk", "logger")

    kernel_send("logger", "logfile", "test.log")
    kernel_send("logger", "level", "default", "debug")

    kernel_load("hello.awk", "hello")

    kernel_send("hello", "message")

    kernel_send("logger", "debug", this, "This is a big, %s", "fat test...")

    print "module:end" >> "/dev/stderr"

    # Let some time pass.
    system("exec sleep 0.25")

    # "ping" the kernel (by asking to shut ourselves down)
    kernel_shutdown()
}

"fini" == $1 {
    kernel_send("kernel", "exit")
}
