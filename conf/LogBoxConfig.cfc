component {
    void function configure() {
        logBox = {
            appenders = {
                fw1rulebox = {
                    class = "logbox.system.logging.appenders.RollingFileAppender",
                    properties = {
                        filePath = "./logs",
                        autoExpand = true,
                        fileMaxSize = 3000,
                        fileMaxArchives = 5
                    }
                }
            },
            root = { appenders = "*" }
        };
    }
}