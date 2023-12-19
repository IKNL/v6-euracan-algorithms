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
#' 
#' UPDATE : Added one-hot-encoding for factor data
#' 
RPC_compute_summed_z <- function(df, subset_rules, expl_vars, time_col,
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

  data <- preprocess.data(df, expl_vars, censor_col, time_col)


  # Set condition to enable univariate Cox
  if (dim(data$Z)[2] > 1) {
    cases_with_events <- data$Z[data$censor == 1, ]
  } else {
    cases_with_events <- as.matrix(data$Z[data$censor == 1])
  }

  # We need to check if a factor exists, if it does hot encode before sum.
  hot.encode.factor <- function(cases_with_events, types){
      # Because we can have no types mentioned
      if(is.null(types)){
          return(cases_with_events)
      }else{
          column_names <- names(types)

          # we only want the factor types as this is the option to hot encode
          all.factors <- lapply(seq(types), function(i){
              if(types[[i]]$type == "factor"){
                  return(names(types)[[i]])
              }
          })
          # if no factors, this will be empty, else only return factor names
          all.factor.names <- Reduce("c", all.factors)
          # this creates the hot encoding by leveraging R's built in contrast
          # each factor will have its own independent levels
          # NOTE : these levels have to be applied before the hot encoding as
          # the hot encoding looks at the category supplied, if for instance
          # one data set only has 1:10 and the other 11:20 factor levels,
          # but the coding is done independently, this will cause errors.
          # at the central server the types should include the GLOBAL levels.
          contrast.list <- lapply(seq_along(all.factor.names), function(i) {
              return(contrasts(cases_with_events[[all.factor.names[i]]],
                               contrasts = F))
          })
          # contrast.arg expects a named list
          names(contrast.list) = all.factor.names
          if(!is.null(all.factor.names)){
              new.formula <- as.formula(paste("~0+", paste(column_names,
                                                           collapse = "+")))
              return(model.matrix(new.formula, data = cases_with_events,
                                  contrast.arg = contrast.list))
          }else{
              return(cases_with_events)
          }
      }
  }
  # Since an item can only be in a single set of events, we're essentially
  # summing over all cases with events.
  summed_zs <- colSums(hot.encode.factor(cases_with_events, types))

  return(summed_zs)
}
