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
#'
#' @return A list with the following results for each column: length, sum,
#' range and number of rows with non-empty and empty values.
#'
#' @TODO check if column names are in the data
RPC_summary <- function(data, columns, threshold=5L, types=NULL){

  # Assign types
  if(!is.null(types)){
    data <- vtg.summary::assign_types(data, types)
  }

  # check if all requested columns are in the data. If not, return error
  columns <- unique(columns)
  columns_present <- get_columns_in_data(data, columns)
  if (length(columns_present) != length(columns)) {
    msg <- "Not all columns are present in the data"
    vtg::log$error(msg)
    return(list("error" = msg))
  }

  # keep only requested columns
  data <- data[, columns]

  # count number of NA's
  nan_count <- colSums(is.na(data))

  # get column length
  column_lengths <- check.lengths.data(data, columns, threshold)

  # compute sum
  column_sums <- summation(data, columns, column_lengths)

  # compute data range
  column_ranges <- range.fn(data, columns, column_lengths, threshold)

  # compute number of rows with values
  data.useable.rows <- useable.rows.data(data, columns, threshold)

  return(
    list(
      "nan_count" = nan_count,
      "column_lengths" = column_lengths,
      "column_sums" = column_sums,
      "column_ranges" = column_ranges,
      "data.useable.rows" = data.useable.rows
    )
  )
}

get_columns_in_data <- function(data, columns){
  return(columns[columns %in% names(data)])
}

check.lengths.data <- function(data, columns, threshold){
    length.of.columns <- lapply(columns, function(colName){
        len.data <- length(na.omit(data[,colName]))
        names(len.data) <- colName
        return(len.data)
    })
    length.of.columns <- lapply(length.of.columns, function(col.len){
        if((col.len == 0) || (col.len > threshold)){
            len.data <- col.len
        }else if(col.len < threshold){
            stop("Disclosure risk, not enough observations in ", colName, " < "
                 , threshold)
        }
    })
    # it's much simpler and cleaner to return a named vector
    return(Reduce("c", length.of.columns))
}

summation <- function(data, columns, column_lengths){
    sums.per.column <- lapply(columns, function(colName){
        # first we check if the length of the data is 0, if so sum will be 0
        if(column_lengths[colName] == 0){
            sum.per.column <- 0
        }else if(is.factor(data[,colName])){
            sum.per.column <- NaN
        }else if(is.numeric(data[,colName])){
            sum.per.column <- sum(data[,colName], na.rm = T)
        }else{
            stop("Data has to be in the form of a data frame and has to be
                 a numerical value...")
        }
        names(sum.per.column) <- colName
        return(sum.per.column)
    })
    return(Reduce("c", sums.per.column))
}

# we don't want to run on small tabular data due to disclosive risk
disclosure.check.tab <- function(tab, threshold=5L){
    if(any(tab < threshold)){
        stop(paste0("Disclosure risk, some values in '", colName,
                    "' are lower than ", threshold))
    }else{
        tab
    }
}

range.fn <- function(data, columns, column_lengths, threshold=5L){
    range.per.column <- lapply(columns, function(colName){
        dt <- na.omit(data[,colName])
        if(column_lengths[colName] == 0){
             NULL
        }else if(is.factor(dt)){
            disclosure.check.tab(table(dt), threshold)
        }else{
            range(dt)
        }
    })
    names(range.per.column) <- columns
    return(range.per.column)
}

# Different function to lengths because this tells you as a whole,
# how many useable rows are there in the dataset.
useable.rows.data <- function(data, columns, threshold=5L){
    dt <- na.omit(data[,columns])
    # if dt is simply a vector...
    n.useable.rows <- if(is.null(dim(data))){
        length(dt)
    }else{
        nrow(dt)
    }
    if(is.null(n.useable.rows) || n.useable.rows == 0){
        return(0)
    }else if(n.useable.rows > threshold){
        return(n.useable.rows)
    }else{
        stop("Disclosure risk as there are fewer than ",
             threshold, " observations.")
    }
}
