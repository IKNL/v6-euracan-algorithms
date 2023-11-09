RPC_compute_chi_squared <- function(data, columns, expected_values) {
  data <- na.omit(data[, columns])
  return(sum(abs(data - expected_values)^2 / expected_values))
}
