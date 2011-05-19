
BEGIN {
    ERROR   = 1
    WARNING = 2
    INFO    = 3
    DEBUG   = 4

    loglabel[ERROR]   = "ERROR"
    loglabel[WARNING] = "WARNING"
    loglabel[INFO]    = "INFO"
    loglabel[DEBUG]   = "DEBUG"

    loglevel["default"] = INFO

    logfile = "log"
}

function logger_level_set (component, level) {
    loglevel[component] = level
}

function logger_level (component    ,level) {
    level = loglevel[component]
    
    if ("" == level) {
	level = loglevel["default"]
    }

    return level
}

function logger (component, level, message	,timestamp) {
    if (logger_level(component) < level) {
	next
    }

    timestamp = strftime("%Y-%m-%dT%H:%M:%S")

    printf "[%s] %20s [%s] %s\n", loglabel[level], component, \
	   timestamp, message >> logfile

    fflush(logfile)

    next
}

"info"  == $1 { logger($2, INFO,    $3) }
"warn"  == $1 { logger($2, WARNING, $3) }
"debug" == $1 { logger($2, DEBUG,   $3) }
"error" == $1 { logger($2, ERROR,   $3) }

"set_level" == $1 { logger_level_set($2, $3) }
"set_logfile" == $1 { logfile = $2 }
