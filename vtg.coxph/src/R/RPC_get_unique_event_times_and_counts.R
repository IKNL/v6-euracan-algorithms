#' Return a dataframe of unique event times
#'
#' Params:
#'   df: dataframe
#'   time_col: name of the column that contains the event/censor times
#'
#' Return:
#'   dataframe with columns time and Freq
RPC_get_unique_event_times_and_counts <- function(df, expl_vars, subset_rules, time_col,
                                                  censor_col, types = NULL) {
  # Data pre-processing specific to EURACAN
  df <- vtg.preprocessing::extend_data(df)
  df <- tryCatch(
    vtg.preprocessing::subset_data(df, subset_rules),
    error = function(e) {
      return(vtg::error_format(conditionMessage(e)))
    }
  )

  if (!is.null(df$error)) {
    vtg::log$error(df$error)
    return(df)
  }

  vtg::log$info("Rows before NA removal: {nrow(df)}")
  df <- na.omit(df[, c(expl_vars, censor_col, time_col)])
  # TODO: we need to check if sufficient columns are left after NA removal
  vtg::log$info("Rows after NA removal: {nrow(df)}")

  # Specify data types for the columns in the data
  if (!is.null(types)) df <- assign_types(df, types)

  time <- df[df[, censor_col] == 1, time_col]
  print(time)
  print(length(time) == 0)
  if (length(time) < 2){
    vtg::log$warn("< 2 events found in the data!")
    return(data.frame(time = numeric(), Freq = numeric()))
  }
  time <- sort(time)

  df_time <- as.data.frame(table(time), stringsAsFactors = F)
  df_time <- apply(df_time, 2, as.numeric)
  return(df_time)
}
