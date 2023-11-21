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
#'
#' @return Vector of squared deviance per column in the Data or NaN if the
#' data is populated entirely by NA
#'
RPC_variance <- function(data, columns, mean, types = NULL) {
  # TODO generalize start of this function to work same as other RPCs
  if (!is.null(types)) {
    data <- vtg.summary::assign_types(data, types)
  }

  columns <- unique(columns)
  columns_present <- get_columns_in_data(data, columns)
  if (length(columns_present) != length(columns)) {
    msg <- "Not all columns are present in the data"
    vtg::log$error(msg)
    return(list("error" = msg))
  }

  # keep only requested columns. Cast to data.frame to avoid issues with
  # single column data.frames. Then, set the column names explicitly because
  # those are lost when casting to data.frame for single column data.frames.
  data <- as.data.frame(data[, columns])
  names(data) <- columns

  result <- list()
  for (column in columns) {
    if (is.factor(data[, column])) {
      result[[column]] <- NA
    } else {
      result[[column]] <- sum((data[, column] - mean[[column]])^2,
                              na.rm = TRUE)
    }
  }

  return(result)
}

# TODO this is a duplicate of the function in RPC_summary.R
get_columns_in_data <- function(data, columns) {
  return(columns[columns %in% names(data)])
}