RPC_KMsurv=function(data,subset_rules,master,vars,stratum=NULL){

    # Data pre-processing specific to EURACAN
    data <- vtg.preprocessing::extend_data(data)
    data <- vtg.preprocessing::subset_data(data, subset_rules)

    # Select only the records that have non-missing values for the vars
    data <- na.omit(data[, vars])
    print(paste0("final row count: ", nrow(data)))

    time=master$time
    time2=master$time2
    strata=master$strata
    tmax=master$tmax
    event=master$event
    n.at.risk=master$n.at.risk
    times=master$times
    if(!is.na(time2)) data[,time]=data[,time2]-data[,time]
    if(!is.na(tmax)){
        data[data[,time]>tmax ,event]=0
        data[data[,time]>tmax ,time]=tmax
    }
    if(!is.na(strata)){
        data=data[data[,strata]==stratum,]
    }
    data=data[order(data[,time]),]
    ev_cen=event_and_censor(data=data,master=master)
    n.event=ev_cen$n.event
    n.censor=ev_cen$n.censor
    s=(n.event/n.at.risk)
    r=n.event/(n.at.risk*(n.at.risk-n.event))
    return(list(s=s,r=r))
}