#' Do a number of checks that are common to all RPC functions
#'
#' @param data Dataset supplied to the node
#' @param columns List of column names
#' @param types types of the columns
#' @return data.frame with only the requested columns, or a list with an error
#' message if there is an error
common_checks_rpc <- function(data, columns, types) {
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
    vtg.preprocessing::assign_types(data, types)
  }

  # check if all columns are either numeric or factors. If not, return error
  if (any(
    !sapply(data[, columns], function(col) is.numeric(col) || is.factor(col))
  )) {
    return(wrong_column_type_message(data, columns))
  }

  # keep only requested columns. Cast to data.frame to avoid issues with
  # single column data.frames. Then, set the column names explicitly because
  # those are lost when casting to data.frame for single column data.frames.
  data <- as.data.frame(data[, columns])
  names(data) <- columns

  return(data)
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
    {wrong_column_types}. Column types are: {sapply(data[, columns], class)}"
  )
  vtg::log$error(msg)
  return(list("error" = msg))
}