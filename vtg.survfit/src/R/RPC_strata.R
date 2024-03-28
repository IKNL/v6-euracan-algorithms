RPC_strata <- function(data, subset_rules, strata, vars, extend_data=TRUE) {

  # Data pre-processing specific to EURACAN
  if (extend_data) {
    data <- vtg.preprocessing::extend_data(data)
  }
  data <- vtg.preprocessing::subset_data(data, subset_rules)

  # Select only the records that have non-missing values for the vars
  data <- na.omit(data[, vars])
  print(paste0("final row count: ", nrow(data)))

  return(unique(data[, strata]))
}
