#' Data station / node side function.
#'
#' This function extracts from the data based on the formula provided the
#' unique levels/categories/factors.
#'
#' @param data Data provided by client.
#' @param subset_rules Set of filters for subsetting the data.
#' @param master output from `init_formula`, a formula.
#'
#' @return returns a list with unique categories/factors of the variable in
#' the data.
#'
#' @export
#'
RPC_get_vars <- function(data, subset_rules, master, extent_data = TRUE) {
  # Data pre-processing specific to EURACAN
  if (extent_data) {
    data <- vtg.preprocessing::extend_data(data)
  }
  data <- tryCatch(
    vtg.preprocessing::subset_data(data, subset_rules),
    error = function(e) {
      return(vtg::error_format(conditionMessage(e)))
    }
  )

  if (!is.null(data$error)) {
    vtg::log$error(data$error)
    return(data)
  }

  used_variables <- all.vars(master$formula)
  data <- data[, used_variables]
  data[is.na(data)] <-"N/A"

  vars <- apply(data, 2, unique, simplify = FALSE)
  return(vars)
}
