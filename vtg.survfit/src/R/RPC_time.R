RPC_time=function(data,subset_rules,master,vars, stratum=NULL){

    # Data pre-processing specific to EURACAN
    data <- vtg.preprocessing::extend_data(data)
    data <- vtg.preprocessing::subset_data(data, subset_rules)

    # Select only the records that have non-missing values for the vars
    data <- na.omit(data[, vars])
    print(paste0("final row count: ", nrow(data)))

    time=master$time
    time2=master$time2
    event=master$event
    strata=master$strata
    tmax=master$tmax
    if(!is.na(time2)) data[,time]=data[,time2]-data[,time]
    if(!is.na(tmax)){
        data[data[,time]>tmax ,event]=0
        data[data[,time]>tmax ,time]=tmax
    }
    if(is.na(strata)){
        times=unique(data[,time])
    }else{
        times=unique(data[data[,strata]==stratum,time])
    }
    return(times)
}
