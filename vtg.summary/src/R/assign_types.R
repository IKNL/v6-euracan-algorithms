#' Assign numeric or factor type to columns specified.
#'
#' @param data dataframe
#' @param types containing the types to set to the columns
#'
#' @return formatted dataframe
#'
#' @export
#'
assign_types <- function(data, types) {

  column_names <- names(types)

  # TODO validate types, if fails return error
  # types should be a list with elements $type and (if $type == "factor")
  # $levels and (if $type == "factor" and $ref != NULL) $ref

  # for each column specified in types set the appropiate type
  for (i in seq_len(length(types))) {
    column_name <- column_names[i]
    specs <- types[[i]]
    type_ <- specs$type
    if (type_ == "numeric") {
      data[[column_name]] <- as.numeric(data[[column_name]])
    } else if (type_ == "factor") {
      # TODO check if this is what we want: we basically filter the data here!
      data <- data[data[[column_name]] %in% specs$levels,]
      data[[column_name]] <- factor(data[[column_name]], levels = specs$levels)
      if (!is.null(specs$ref)) {
        data[[column_name]] <- relevel(data[[column_name]], ref = specs$ref)
      }
    } else {
      # TODO error message, wrong type
    }
  }


  return(data)
}