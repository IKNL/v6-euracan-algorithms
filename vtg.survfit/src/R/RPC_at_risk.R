RPC_at_risk <- function(data,subset_rules,master,vars,stratum=NULL, extend_data=TRUE){


    print("RPC_at_risk")
    print(stratum)

    # Data pre-processing specific to EURACAN
    if (extend_data) {
      data <- vtg.preprocessing::extend_data(data)
    }
    data <- vtg.preprocessing::subset_data(data, subset_rules)

    # Select only the records that have non-missing values for the vars
    data <- na.omit(data[, vars])
    print(paste0("final row count: ", nrow(data)))

    time=master$time
    time2=master$time2
    if(!is.na(time2)) data[,time]=data[,time2]-data[,time]
    event=master$event
    if(!is.na(master$strata)){
       data=data[data[,master$strata]==stratum,]
    }
    data=data[order(data[,time]),]
    times=master$times
    ev_cen=event_and_censor(data=data,master=master)
    n.event=ev_cen$n.event
    n.censor=ev_cen$n.censor

    n.at.risk=nrow(data)

    for(i in 2:length(times)) {
      n.at.risk = c(n.at.risk, n.at.risk[i - 1] - (n.event[i - 1] + n.censor[i - 1]))
    }

    return(list(n.at.risk=n.at.risk,event=sum(n.event)))
}
#lapply(dataset, RPC_at_risk,master=master,stratum=stratum)