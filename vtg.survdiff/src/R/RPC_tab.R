#' @export
#'
RPC_tab <- function(data, subset_rules, master, stratum, vars, extend_data = TRUE){

  vtg::log$info("Preprocessing data...")
  data <- tryCatch(
    {
      if (extend_data) {
        data <- vtg.preprocessing::extend_data(data)
      }
      data <- vtg.preprocessing::subset_data(data, subset_rules)
      data
    },
    error = function(e) {
      vtg::error_format(conditionMessage(e))
    }
  )
  if (!is.null(data$error)) {
    vtg::log$error(data$error)
    return(data)
  }

  vtg::log$info("Rows before NA removal: {nrow(data)}")
  data <- na.omit(data[, vars])
  # TODO: we need to check if sufficient columns are left after NA removal
  vtg::log$info("Rows after NA removal: {nrow(data)}")

  time=master$time
  time2=master$time2
  tmax=master$tmax
  event=master$event
  strata=master$strata
  times=master$times
  if(!is.na(time2)) data[,time]=data[,time2]-data[,time]
  if(!is.na(tmax)){
      data[data[,time]>tmax ,event]=0
      data[data[,time]>tmax ,time]=tmax
  }
  n.event=sapply(times, function(t) sum( data[data[,time]==t & data[,strata] %in% stratum,event]==1) )
  n.censor=sapply(times, function(t) sum(data[data[,time]==t & data[,strata] %in% stratum,event]==0))
  n.at.risk=nrow(data[data[,strata] %in% stratum,])
  for(i in 2:length(times)) n.at.risk=c(n.at.risk,n.at.risk[i-1]-(n.event[i-1]+n.censor[i-1]))
  Tab=data.frame(n.event,n.censor,n.at.risk)
  names(Tab)=c('m','q','n')
  return(Tab)
}
