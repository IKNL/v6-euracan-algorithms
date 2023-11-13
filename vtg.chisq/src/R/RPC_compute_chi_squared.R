#' Compute the local chi-squared statistic
#'
#' @param data A data.frame supplied by the node instance.
#' @param columns A list of column names to be used for the computation of the
#' totals.
#' @param expected_values A vector of expected values.
#'
#' @return A list containing the local chi-squared statistic.
#'
RPC_compute_chi_squared <- function(data, subset_rules, columns,
                                    expected_values) {

  # Data pre-processing specific to EURACAN
  data <- vtg.preprocessing::extend_data(data)
  data <- vtg.preprocessing::subset_data(data, subset_rules)

  data <- na.omit(data[, columns])
  return(sum(abs(data - expected_values)^2 / expected_values))
}
