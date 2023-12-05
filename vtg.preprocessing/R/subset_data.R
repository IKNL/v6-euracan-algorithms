#' version: 1.0
#' Data filter function.
#'
#' This function will be called at the start of the analysis, and executed on
#' the data of every node. Has to be implemented in every RPC call.
#'
#' @param data Data provided by client.
#' @param subset_rules A list of subset rules given by the user. When providing
#' multiple subsetting steps the subsets will be executed in the order as given
#' in the list.
#'
#' Example of a subset rules json file:
#' [
#'  {
#'    "subset": "site==6"
#'  },
#'  {
#'    "subset": "site %in% c(6,7)"
#'  },
#'  {
#'    "subset": "age>30 & age<=70"
#'  }
#' ]
#'
#' @return Either, the subset of data to be used in the rest of the analysis,
#' or, for privacy preserving reasons, an empty data.frame (with the column
#' names) if the subset of data has less than N rows.
#'
#' @export
subset_data <- function(data, subset_rules) {

  if (is.null(subset_rules)) {
    print("No subset rules are given.")
    return(data)
  }

  print("Number of rows before subset_data:")
  print(nrow(data))

  require(dplyr)

  result <- data
  for (n_rule in seq_len(nrow(subset_rules))) {
    query <- subset_rules[n_rule, "subset"]
    result <- result %>% filter(!!rlang::parse_expr(query))
  }

  # subset rules are given and subsetted data is < N
  threshold <- get_threshold()
  if (nrow(result) < threshold) {
    error_msg <- glue::glue("Subset contains less than {threshold} rows.")
    return(stop(error_msg))
  }

  print("Number of rows after subset_data:")
  print(nrow(result))

  return(result)
}

get_threshold <- function() {
  threshold <- Sys.getenv("VTG_PREPROCESS_MIN_RECORDS_THRESHOLD")
  if (is.null(threshold)) {
    threshold <- 5
  }
  return(as.integer(threshold))

}