
#' Compute totals from local data.frame
#'
#' @description
#' This function computes the totals from the data. This can either be a
#' data.frame or a vector.
#'
#' @param data A data.frame supplied by the node instance
#' @param columns A list of column names to be used for the computation of the
#'  totals.
#'
#' @return A list containing the totals.
#'
RPC_dimensions_and_totals <- function(data, subset_rules, columns) {

  # Data pre-processing specific to EURACAN
  data <- vtg.preprocessing::extend_data(data)
  data <- vtg.preprocessing::subset_data(data, subset_rules)

  # Number of observations in the dataset before removing NA's
  n_raw <- nrow(data)
  data_filtered <- na.omit(data[, columns])
  # Number of observations in the dataset after removing NA's
  n <- nrow(data_filtered)
  vtg::log$info("Removed ", n_raw - n, " rows from the dataset. As they
                contained NA's.")

  # Disclosure risk checks
#   if (!check_disclosure_risk(data)) {
#     cat("Disclosure risks, aborting...")
#     return(list("error" = "Disclosure risk"))
#   }

  if (is.data.frame(data_filtered)) {

    vtg::log$info("Running chisq.test on dataframe...")
    data_filtered <- as.matrix(data_filtered)
    totals <- list(
      "sum" = sum(data_filtered),
      "number_of_rows" = nrow(data_filtered),
      "number_of_columns" = ncol(data_filtered),
      "sum_of_rows" = rowSums(data_filtered),
      "sum_of_columns" = colSums(data_filtered)
    )
    attr(totals, "class") <- "chi.data.frame"
    return(totals)

  } else {

    vtg::log$info("Running chisq.test on vector...")
    totals <- list(
      "sum" = sum(data_filtered),
      "number_of_rows" = length(data_filtered)
    )
    attr(totals, "class") <- "chi.vector"
    return(totals)

  }

}

#' Check for disclosure risk
check_disclosure_risk <- function(data) {

  # The threshold is there to make sure individual records are not disclosed.
  threshold <- get_threshold()
  vtg::log$info("Using threshold of ", threshold, " for disclosure risk
                checks.")

  # The min patient threshold is there to make sure that a minimal number of
  # patients are included in the analysis.
  min_patient_threshold <- get_min_patient_threshold()
  vtg::log$info("Using min patient threshold of ", min_patient_threshold, "
                for disclosure risk checks.")

  is_data_frame <- is.data.frame(data)

  if (is_data_frame){
    # Check that all column names are unique
    if (length(unique(colnames(data))) != length(colnames(data))) {
      vtg::log$error("You have repeated column names...")
      return(FALSE)
    }

    # Check that the number of occurrences of each unique element for each
    # column is greater than the threshold
    for (column in colnames(data)) {
      if (!check_disclosure_risk(data[, column])) {
        return(FALSE)
      }
    }

  } else {

    # Count the number of occurrences of each unique element, this should
    # be greater than the threshold
    u_data <- unique(data)
    # Get the count of each unique element
    counts <- lapply(u_data, function(x) length(data[data == x]))
    # Check if any of the counts is lower than the threshold

    if (any(unlist(counts) < threshold)) {
      vtg::log$error("Disclosure risk, some values are lower than ",
                        threshold)
      return(FALSE)
    }
  }
  return(TRUE)
}


#' Obtain the threshold for the Chi-Square test
#'
#' @description
#' This function obtains the threshold for the Chi-Square test from the
#' environment variable `VTG_CHISQ_THRESHOLD`. If this variable is not set, it
#' will use the default value of 5.
#'
#' @return The threshold for the Chi-Square test.
#'
get_threshold <- function() {
  return(get_env_var("VTG_CHISQ_THRESHOLD", 5L))
}

get_min_patient_threshold <- function() {
  return(get_env_var("VTG_CHISQ_MIN_PATIENT_THRESHOLD", 10L))
}

get_env_var <- function(var, default) {

  value <- as.integer(Sys.getenv(var))

  if (is.na(value)) {
    vtg::log$warn("'", var, "' is not set, using default of ",
                  default, ".")
    return(default)
  }

}
