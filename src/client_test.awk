
#use module.awk
#use log.awk

BEGIN {
    kernel = "/tmp/awkbot"
}

"init" == $1 {
    kernel_load("logger.awk", "log")
    kernel_send("log", "logfile", "logs/client.log")

    kernel_load("client.awk", "client")
    # wtf!?
#    kernel_listen("client", "fini", "shutdown")
    kernel_send("client", "connect", kernel)
    kernel_send("client", "send", "irc", "msg", "#awkbot-test", "Armaggedon!")
    kernel_listen("client", "shutdown")
    kernel_send("client", "disconnect")
}

"shutdown" == $1 {
    kernel_shutdown()
}

"fini" == $1 {
    kernel_send("kernel", "exit")
}
