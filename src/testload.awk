
#use module.awk

BEGIN { instances = 20 }

"init" == $1 {
    # Test the 10 concurrent tests
    for (i = 1; i <= instances; i++) {
        kernel_load("loadtest.awk", i)
    }
}

"completed" == $1 {
    if (++completed == instances) {
        kernel_send("kernel", "exit")
    }
}
