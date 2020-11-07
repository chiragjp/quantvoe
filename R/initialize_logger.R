#' #' Logger
#' #'
#' initialize_logger <- function(fileName, saveLog = TRUE, logFilePath = NULL){
#' 
#'   if(saveLog == TRUE){
#'     if(is.null(logFilePath)){
#'       my_logfile = paste0('logfile_',fileName, '.txt')
#'     }else{
#'       my_logfile = paste0(logFilePath,'/logfile_',fileName, '.txt')
#'     }
#'     
#'     my_console_appender = log4r::console_appender()
#'     my_file_appender = log4r::file_appender(my_logfile, append = TRUE)
#'     
#'     my_logger <- log4r::logger(threshold = "INFO",
#'                                appenders= list(my_console_appender,my_file_appender))
#'     
#'     return(my_logger)
#'   }else{
#'     my_console_appender = log4r::console_appender()
#'     my_logger <- log4r::logger(threshold = "INFO",
#'                                appenders= list(my_console_appender))
#'   }
#'  
#' 
#' }
