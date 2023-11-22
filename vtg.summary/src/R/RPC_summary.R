#' Get summary statistics for a single node
#'
#' This function calculates all the preliminairy statistics used in the summary
#' algorithm. It calculates number of NA or missing data, length of each column
#' in the data, sum per column of data given that the data is not a factor,
#' and the range per column of the data:- if the column is a factor
#' then it returns a table of values with a disclosure check, otherwise
#' it simply returns the min and max values. Finally this also returns the
#' number of useable rows in the data.
#'
#' @param data A data.frame supplied by the node
#' @param columns List of column names to compute summary for.
#' @param threshold Minimum count in any result before error message is returned
#' because the result may be disclosive. Default is 5.
#' @param types types of the columns
#' @param subset_rules Rules to filter data with. Default is NULL.
#' @param extend_data Whether to extend the data with the `extend_data`
#' function. Default is TRUE.
#'
#' @return A list with the following results for each column: length, sum,
#' range and number of rows with non-empty and empty values.
#'
#' @TODO check if works with single column
RPC_summary <- function(data, columns, threshold = 5L, types = NULL,
                        subset_rules = NULL, extend_data = TRUE) {

  # Data pre-processing specific to EURACAN
  if (extend_data) {
    data <- vtg.preprocessing::extend_data(data)
  }
  data <- vtg.preprocessing::subset_data(data, subset_rules, threshold)

  # execute checks that are common to all RPCs
  data <- vtg.summary::common_checks_rpc(data, columns, types)
  if ("error" %in% names(data)) {
    # Return error message
    return(data)
  }

  # count number of NA's
  nan_count <- colSums(is.na(data))

  # get column length
  column_lengths <- colSums(!is.na(data))

  # check if there are disclosure risks in column lengths. If so, return error
  if (any(column_lengths < threshold)) {
    return(disclosive_msg_col_length(columns, column_lengths, threshold))
  }

  # compute sum
  column_sums <- get_column_sums(data, columns)

  # compute data range
  column_ranges <- get_column_ranges(data, columns)

  # check if there are disclosure risks for factors in column ranges. If so,
  # return error
  factor_columns <- columns[sapply(data[, columns], is.factor)]
  if (any(
    sapply(column_ranges[factor_columns], function(x) any(x < threshold))
  )) {
    return(disclosive_msg_factorial(column_ranges, factor_columns, threshold))
  }

  # compute number of rows with values in all columns
  complete_rows <- nrow(na.omit(data))
  if (complete_rows < threshold) {
    msg <- glue::glue(
      "Disclosure risk, not enough rows without NAs"
    )
    vtg::log$error(msg)
    return(list("error" = msg))
  }

  return(
    list(
      "nan_count" = nan_count,
      "column_lengths" = column_lengths,
      "column_sums" = column_sums,
      "column_ranges" = column_ranges,
      "complete_rows" = complete_rows
    )
  )
}

get_column_sums <- function(data, columns) {
  # compute sum per column. If column is a factor, return NaN
  sums <- (Reduce(`c`, lapply(columns, function(col_name) {
    if (is.factor(data[, col_name])) {
      return(NaN)
    } else if (is.numeric(data[, col_name])) {
      return(sum(data[, col_name], na.rm = TRUE))
    }
  })))
  names(sums) <- columns
  return(sums)
}

get_column_ranges <- function(data, columns) {
  # compute range per column. If column is a factor, return a table of values
  col_ranges <- lapply(columns, function(col_name) {
    if (is.factor(data[, col_name])) {
      return(table(data[, col_name]))
    } else if (is.numeric(data[, col_name])) {
      return(range(data[, col_name], na.rm = TRUE))
    }
  })
  names(col_ranges) <- columns
  return(col_ranges)
}





disclosive_msg_col_length <- function(columns, column_lengths, threshold) {
  # determine which columns are disclosive and return error message for them
  disclosive_columns <- Reduce(`c`, lapply(columns, function(col_name) {
    if (column_lengths[col_name] < threshold) {
      return(col_name)
    }
  }))
  disclosive_columns <- paste(disclosive_columns, collapse = ", ")
  msg <- glue::glue(
    "Disclosure risk, not enough observations in columns:
    {disclosive_columns}"
  )
  vtg::log$error(msg)
  return(list("error" = msg))
}

disclosive_msg_factorial <- function(col_ranges, factorial_cols, threshold) {
  # determine which columns are disclosive and return error message for them
  disclosive_columns <- c()
  for (col in factorial_cols) {
    if (any(Reduce(`c`, col_ranges[col]) < threshold)) {
      disclosive_columns <- c(disclosive_columns, col)
    }
  }
  disclosive_columns <- paste(disclosive_columns, collapse = ", ")
  msg <- glue::glue(
    "Disclosure risk, not enough observations in some categories of factorial
    columns: {disclosive_columns}"
  )
  vtg::log$error(msg)
  return(list("error" = msg))
}
