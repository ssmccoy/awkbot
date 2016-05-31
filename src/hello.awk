# Simple kernel messaging test.

#use module.awk

"message" == $1 {
    kernel_send("logger", "info", this, "Hello from hello.awk")
    kernel_shutdown()
}
