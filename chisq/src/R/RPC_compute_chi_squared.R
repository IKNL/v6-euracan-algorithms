RPC_compute_chi_squared <- function(data, col, expected_values){

  data <- na.omit(data[, col])

  # access correct rows & column...
  local_expected <- expected_values[
    dimnames(expected_values)[[1]] %in% dimnames(data)[[1]],
    dimnames(expected_values)[[2]] %in% dimnames(data)[[2]]
  ]

  return(sum((abs(data - local_expected))^2 / local_expected))
}
