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
RPC_get_vars <- function(data, subset_rules, master) {
  # Data pre-processing specific to EURACAN
  data <- vtg.preprocessing::extend_data(data)
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

  vtg::log$info("Rows before NA removal: {nrow(data)}")
  used_variables <- all.vars(master$formula)
  data <- na.omit(data[, used_variables])
  vtg::log$info("Rows after NA removal: {nrow(data)}")

  f <- master$formula
  vars <- apply(data, 2, unique, simplify = F)
  return(vars)
}
