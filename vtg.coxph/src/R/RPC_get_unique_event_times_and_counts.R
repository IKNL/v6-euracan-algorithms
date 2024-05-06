#' Return a dataframe of unique event times
#'
#' Params:
#'   df: dataframe
#'   time_col: name of the column that contains the event/censor times
#'
#' Return:
#'   dataframe with columns time and Freq
RPC_get_unique_event_times_and_counts <- function(df, expl_vars, subset_rules, time_col,
                                                  censor_col, types = NULL,
                                                  extend_data = TRUE) {
  # Data pre-processing and filtering specific to EURACAN
  vtg::log$info("Computing unique event times and counts")
  vtg::log$info("Preprocessing data...")
  df <- tryCatch(
    {
      if (extend_data) {
        df <- vtg.preprocessing::extend_data(df)
      }
      df <- vtg.preprocessing::subset_data(df, subset_rules)
      df
    },
    error = function(e) {
      vtg::error_format(conditionMessage(e))
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
  vtg::log$info("Assigning types to columns")
  if (!is.null(types)) df <- assign_types(df, types)

  vtg::log$info("One-hot encoding factor columns in expl vars...")
  for (column_name in expl_vars) {
    if (is.factor(df[[column_name]])) {
      res <- one_hot_encoding(df, column_name)
      expl_vars <- c(expl_vars, res$columns_names)
      expl_vars <- expl_vars[expl_vars != column_name]
      df <- res$data
    }
  }
  time <- df[df[, censor_col] == 1, time_col]
  if (length(time) < 2) {
    vtg::log$warn("< 2 events found in the data!")
    return(data.frame(time = numeric(), Freq = numeric()))
  }
  time <- sort(time)

  df_time <- as.data.frame(table(time), stringsAsFactors = F)
  df_time <- apply(df_time, 2, as.numeric)
  vtg::log$info("Unique event times and counts computed")
  return(df_time)
}
