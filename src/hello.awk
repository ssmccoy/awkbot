# Simple kernel messaging test.

"message" == $1 {
    kernel_send("logger", "info", this, "Hello from hello.awk")
    kernel_shutdown()
}
