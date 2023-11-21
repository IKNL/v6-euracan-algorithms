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
#'
#' @return A list with the following results for each column: length, sum,
#' range and number of rows with non-empty and empty values.
#'
#' @TODO check if works with single column
RPC_summary <- function(data, columns, threshold = 5L, types = NULL) {
  # check if all requested columns are in the data. If not, return error
  columns <- unique(columns)
  columns_present <- get_columns_in_data(data, columns)
  if (length(columns_present) != length(columns)) {
    msg <- "Not all columns are present in the data"
    vtg::log$error(msg)
    return(list("error" = msg))
  }

  # Assign types
  if (!is.null(types)) {
    data <- vtg.summary::assign_types(data, types)
  }

  # check if all columns are either numeric or factors. If not, return error
  if (any(
    !sapply(data[, columns], function(col) is.numeric(col) || is.factor(col))
  )) {
    return(wrong_column_type_message(data, columns))
  }
  factor_columns <- columns[sapply(data[, columns], is.factor)]

  # keep only requested columns. Cast to data.frame to avoid issues with
  # single column data.frames. Then, set the column names explicitly because
  # those are lost when casting to data.frame for single column data.frames.
  data <- as.data.frame(data[, columns])
  names(data) <- columns

  # TODO up to here the code should be the same as the other RPC's - extract

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

get_columns_in_data <- function(data, columns) {
  return(columns[columns %in% names(data)])
}

wrong_column_type_message <- function(data, columns) {
  # determine which columns are not numeric or factors and return error message
  wrong_column_types <- Reduce(`c`, lapply(columns, function(col_name) {
    if (!is.numeric(data[, col_name]) && !is.factor(data[, col_name])) {
      return(col_name)
    }
  }))
  wrong_column_types <- paste(wrong_column_types, collapse = ", ")
  msg <- glue::glue(
    "Wrong column type, the following columns are not numeric or factors:
    {wrong_column_types}"
  )
  vtg::log$error(msg)
  return(list("error" = msg))
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
