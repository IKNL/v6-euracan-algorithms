RPC_compute_chi_squared <- function(data, col, expected_values){

  data <- na.omit(data[, col])

  # access correct rows & column...
  if (is.data.frame(data)) {

    local_expected <- expected_values[
      dimnames(expected_values)[[1]] %in% dimnames(data)[[1]],
      dimnames(expected_values)[[2]] %in% dimnames(data)[[2]]
    ]
  } else {
    local_expected <- expected_values[
      # TODO: this is wrong, we need to access the correct rows & columns
      seq_along(data)
    ]
  }

  print('doodle')
  print(expected_values)

  return(sum((abs(data - local_expected))^2 / local_expected))
}
