

$1 == "info" {
    printf "logger->info()\n" >> "/dev/stderr"
    printf "[%s] [%s] %s\n", strftime("%Y-%m-%dT%H:%M:%S"), $2, $3 >> "log"
    fflush("log")
}
