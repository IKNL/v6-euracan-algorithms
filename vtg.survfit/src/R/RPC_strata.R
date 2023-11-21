RPC_strata=function(data,subset_rules,strata){

    # Data pre-processing specific to EURACAN
    data <- vtg.preprocessing::extend_data(data)
    data <- vtg.preprocessing::subset_data(data, subset_rules)

    return(unique(data[,strata]))
}