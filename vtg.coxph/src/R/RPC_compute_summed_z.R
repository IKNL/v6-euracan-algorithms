#' Compute the aggregate statistic of step 2
#' sum over all distinct times i
#'   sum the covariates of cases in the set of cases with events at time i.
#'
#' Params:
#'   df: dataframe
#'   expl_vars: list of explanatory variables (covariates) to use
#'   time_col: name of the column that contains the event/censor times
#'   censor_col: name of the colunm that explains whether an event occured or
#'               the patient was censored
#'
#' Return:
#'   numeric vector with sums and named index with covariates.
RPC_compute_summed_z <- function(df, subset_rules, expl_vars, time_col,
                                 censor_col, types = NULL, extend_data = TRUE) {
  # Data pre-processing and filtering specific to EURACAN
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
  if (!is.null(types)) df <- assign_types(df, types)

  data <- preprocess.data(df, expl_vars, censor_col, time_col)


  # Set condition to enable univariate Cox
  if (dim(data$Z)[2] > 1) {
    cases_with_events <- data$Z[data$censor == 1, ]
  } else {
    cases_with_events <- as.matrix(data$Z[data$censor == 1])
  }

  # Since an item can only be in a single set of events, we're essentially
  # summing over all cases with events.
  summed_zs <- colSums(cases_with_events)

  return(summed_zs)
}
