one_hot_encoding <- function(data, column_name) {
  vtg::log$info("One hot encoding column: {column_name}")
  # Apply one hot encoding
  one_hot <- model.matrix(~ data[[column_name]] - 1)
  colnames(one_hot) <- paste(column_name, levels(data[[column_name]]), sep = "_")
  data <- cbind(data, one_hot)

  return(
    list(
      data = data,
      columns_names = colnames(one_hot)[-1]
    )
  )
}
