#' Compute the local chi-squared statistic
#'
#' @param data A data.frame supplied by the node instance.
#' @param columns A list of column names to be used for the computation of the
#' totals.
#' @param expected_values A vector of expected values.
#'
#' @return A list containing the local chi-squared statistic.
#'
RPC_compute_chi_squared <- function(data, columns, expected_values) {
  data <- na.omit(data[, columns])
  return(sum(abs(data - expected_values)^2 / expected_values))
}
