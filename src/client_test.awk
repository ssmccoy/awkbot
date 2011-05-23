

BEGIN {
    kernel = "/tmp/tmp.iWNsajpzlD"
}

"init" == $1 {
    kernel_load("client.awk", "client")
    kernel_listen("client", "fini", "shutdown")
    kernel_send("client", "connect", kernel)
    kernel_send("client", "send", "irc", "msg", "#awkbot-test", "Armaggedon!")
    kernel_send("client", "disconnect")
}

"shutdown" == $1 {
    kernel_shutdown()
}

"fini" == $1 {
    kernel_send("kernel", "exit")
}
