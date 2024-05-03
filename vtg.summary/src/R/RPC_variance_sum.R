#' Calculate Squared Deviance.
#'
#' This function is the precursor to getting the summed squared deviance
#' across all the datastation(s) (node). This is then used to calculate the
#' variance and following that, the standard deviation.
#'
#' @param data Dataset
#' @param columns Should be supplied by researcher as a vector of strings
#' representing the column names they think is present in the data
#' @param mean This is calculated earlier in the algorithm, global mean
#' of the combined datastation(s) (nodes).
#' @param types containing the types to set to the columns
#' @param subset_rules Rules to filter data with. Default is NULL.
#' @param is_extend_data Whether to extend the data with the `is_extend_data`
#' function. Default is TRUE.
#'
#' @return Vector of squared deviance per column in the Data or NaN if the
#' data is populated entirely by NA
#'
RPC_variance_sum <- function(data, columns, mean, types = NULL,
                             subset_rules = NULL, is_extend_data = TRUE) {
  data <- tryCatch(
    {
      if (is_extend_data) {
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

  vtg::log$debug("Factorizing character data...")
  data <- vtg.preprocessing::factorize(data)

  # execute checks that are common to all RPCs
  data <- vtg.summary::common_checks_rpc(data, columns, types)
  if ("error" %in% names(data)) {
    # Return error message
    return(data)
  }

  # compute sum of the variance
  result <- list()
  for (column in columns) {
    if (is.factor(data[, column])) {
      result[[column]] <- NA
    } else {
      result[[column]] <- sum((data[, column] - mean[[column]])^2,
        na.rm = TRUE
      )
    }
  }
  return(result)
}
