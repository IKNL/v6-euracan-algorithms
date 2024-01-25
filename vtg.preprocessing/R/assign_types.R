#' Set the types of the columns of a dataframe
#'
#' @param data dataframe
#' @param types containing the types to set to the columns
#'   'types': {'column_name': {'type': 'numeric' | 'factor'},
#'             'column_name': {
#'               'type': 'factor',
#'               'levels': ['a', 'b', 'c'],
#'               'ref': 'a'
#'              }
#'           }
#'
#' @return dataframe with the specified types
#'
#' @export
#'
assign_types <- function(data, types) {

  column_names <- names(types)
  vtg::log$debug("Assigning types to columns: ", column_names)

  # for each specified column in types set the appropiate type
  for (i in seq_len(length(types))) {

    column_name <- column_names[i]
    specs <- types[[i]]
    type_ <- specs$type

    if (type_ == "numeric") {

      data[[column_name]] <- as.numeric(data[[column_name]])

    } else if (type_ == "factor") {
      # TODO check if this is what we want: we basically filter the data here!

      if (!is.null(specs$levels)) {
        data <- data[data[[column_name]] %in% specs$levels,]
        data[[column_name]] <- factor(data[[column_name]], levels = specs$levels)
      } else {
        data[[column_name]] <- factor(data[[column_name]])
      }

      if (!is.null(specs$ref)) {
        data[[column_name]] <- relevel(data[[column_name]], ref = specs$ref)
      }

    } else {
      vtg::log$error("Wrong type specified: ", type_, ". Continuing with next column.")
    }
  }

  return(data)
}