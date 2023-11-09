RPC_compute_chi_squared <- function(data, col, expected_values) {
  data <- na.omit(data[, col])
  return(sum(abs(data - expected_values)^2 / expected_values))
}
