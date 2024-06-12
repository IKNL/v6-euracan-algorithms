#' @export
#'
RPC_strata <- function(data, subset_rules, strata, vars, extend_data = TRUE){

  vtg::log$info("Preprocessing data...")
  data <- tryCatch(
    {
      if (extend_data) {
        data <- vtg.preprocessing::extend_data(data)
      }
      data <- vtg.preprocessing::subset_data(data, subset_rules)
      data
    },
    error = function(e) {
      vtg::error_format(conditionMessage(e))
    }
  )
  if (!is.null(data$error)) {
    vtg::log$error(data$error)
    return(data)
  }

  vtg::log$info("Rows before NA removal: {nrow(data)}")
  data <- na.omit(data[, vars])
  # TODO: we need to check if sufficient columns are left after NA removal
  vtg::log$info("Rows after NA removal: {nrow(data)}")

  return(unique(data[, strata]))
}