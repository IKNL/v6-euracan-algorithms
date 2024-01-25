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
#' @param types types of the columns
#' @param subset_rules Rules to filter data with. Default is NULL.
#' @param is_extend_data Whether to extend the data with the `is_extend_data`
#' function. Default is TRUE.
#'
#' @return A list with the following results for each column: length, sum,
#' range and number of rows with non-empty and empty values.
#'
#' @TODO check if works with single column
RPC_summary <- function(data, columns, types = NULL, subset_rules = NULL,
                        is_extend_data = TRUE) {

  vtg::log$set_threshold("debug")
  # TODO if preprocessing active, logs of RPC functions are not printed. Why?
  # Data pre-processing specific to EURACAN
  if (is_extend_data) {
    data <- vtg.preprocessing::extend_data(data)
  }
  data <- vtg.preprocessing::subset_data(data, subset_rules)

  vtg::log$debug("Factorizing character data...")
  data <- vtg.preprocessing::factorize(data)

  # execute checks that are common to all RPCs
  vtg::log$debug("Checking data & Apply types")
  data <- vtg.summary::common_checks_rpc(data, columns, types)
  if ("error" %in% names(data)) {
    # Return error message
    # FIXME: this is not safe
    return(data)
  }

  # count number of NA's
  vtg::log$debug("Counting number of NA's...")
  nan_count <- colSums(is.na(data))

  # get column length
  vtg::log$debug("Counting column lengths...")
  column_lengths <- colSums(!is.na(data))

  # check if there are disclosure risks in column lengths. If so, return error
  threshold <- get_threshold()
  vtg::log$debug("Checking diclosure risk in column lengths...")
  if (any(column_lengths < threshold)) {
    return(disclosive_msg_col_length(columns, column_lengths, threshold))
  }

  # compute sum
  vtg::log$debug("Computing column sums...")
  column_sums <- get_column_sums(data, columns)

  # compute data range
  vtg::log$debug("Computing column ranges...")
  # FIXME FM 24-01-24: in case of a factor column, the range is not computed but the
  # count of each factor is returned. This is not a range
  column_ranges <- get_column_ranges(data, columns)

  # check if there are disclosure risks for factors in column ranges. If so,
  # return error
  vtg::log$debug("Checking disclosure risk in column ranges...")
  factor_columns <- columns[sapply(data[, columns], is.factor)]
  if (any(
    sapply(column_ranges[factor_columns], function(x) any(x < threshold))
  )) {
    return(disclosive_msg_factorial(column_ranges, factor_columns, threshold))
  }

  # compute number of rows with values in all columns
  vtg::log$debug("Counting number of rows with values in all columns...")
  complete_rows <- nrow(na.omit(data))
  if (complete_rows < threshold) {
    msg <- glue::glue(
      "Disclosure risk, not enough rows without NAs"
    )
    vtg::log$error(msg)
    return(list("error" = msg))
  }

  vtg::log$debug("Returning results...")
  return(
    list(
      "nan_count" = nan_count,
      "column_lengths" = column_lengths,
      "column_sums" = column_sums,
      "column_ranges" = column_ranges[setdiff(names(column_ranges), factor_columns)],
      "factor_counts" = as.list(column_ranges[factor_columns]),
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
  factor_columns <- columns[sapply(as.data.frame(data[, columns]), is.factor)]
  numeric_columns <- columns[sapply(as.data.frame(data[, columns]), is.numeric)]

  # numeric summary
  summary_numeric <- NULL
  if (length(numeric_columns) > 0) {
    summary_numeric <- do.call(cbind, lapply(data[, numeric_columns], summary))
  }

  # factorial summary - omit NAs to not make that a separate category
  summary_factors <- NULL
  if (length(factor_columns) > 0) {
    summary_factors <- sapply(as.data.frame(na.omit(data[, factor_columns])), summary, simplify = FALSE)
    names(summary_factors) <- factor_columns
  }

  # get range per column from summary
  col_ranges <- summary_factors
  for (col in numeric_columns) {
    col_ranges[[col]] <- c(summary_numeric["Min.", col],
                           summary_numeric["Max.", col])
  }
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

get_threshold <- function() {
  return(get_env_var("VTG_SUMMARY_THRESHOLD", 5L))
}

get_env_var <- function(var, default) {

  value <- as.integer(Sys.getenv(var))

  if (is.na(value)) {
    vtg::log$warn("'", var, "' is not set, using default of ",
                  default, ".")
    return(default)
  }

}