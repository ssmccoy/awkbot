
#use module.awk

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

function logger_logfile_set (filename) {
    # Just incase we had the logfile open for some reason
    close(logfile)

    logfile = filename
}

function logger_level_set (component, level,l,i) {
    for (i = ERROR; i <= DEBUG; i++) {
        if (tolower(loglabel[i]) == tolower(level)) {
            loglevel[component] = i
            return
        }
    }
}

function logger_level (component    ,level) {
    level = loglevel[component]
    
    if ("" == level) {
	level = loglevel["default"]
    }

    return level
}

function logger (component, level, message  ,a1,a2,a3,a4,a5,a6,a7,a8,timestamp) {
    if (logger_level(component) < level) {
	next
    }

    timestamp = strftime("%Y-%m-%dT%H:%M:%S")

    printf "[%s] [%s] %s: %s\n", loglabel[level], timestamp, \
	   component, sprintf(message, a1,a2,a3,a4,a5,a6,a7,a8) >> logfile

    fflush(logfile)

    next
}

function logger_fini () {
    close(logfile)
}

"info"  == $1 { logger($2, INFO,    $3,$4,$5,$6,$7,$8,$9) }
"warn"  == $1 { logger($2, WARNING, $3,$4,$5,$6,$7,$8,$9) }
"debug" == $1 { logger($2, DEBUG,   $3,$4,$5,$6,$7,$8,$9) }
"error" == $1 { logger($2, ERROR,   $3,$4,$5,$6,$7,$8,$9) }

"level"   == $1 { logger_level_set($2,$3) }
"logfile" == $1 { logger_logfile_set($2)  }
"fini"    == $1 { logger_fini()           }


## Usage
# kernel_load("logger.awk", "log")
# kernel_send("log", "debug", "This is a %s message", "debug")
