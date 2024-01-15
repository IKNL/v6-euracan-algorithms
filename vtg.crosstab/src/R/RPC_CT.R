#' Data station / node side function.
#'
#' Calculates the local instance of the Cross tabulation.
#'
#' @param data Data provided by node.
#' @param subset_rules Set of filters for subsetting the data.
#' @param master This will contain output from `init_formula`, a formula.
#'
#' @return Local instance of Cross tabulation. This computes the instances per
#' var_cat which belong to the data. In other words, frequency distribution
#' per categorical variable.
#'
#' @export
#'
RPC_CT <- function(data, subset_rules, master){

    # Data pre-processing specific to EURACAN
    df <- vtg.preprocessing::extend_data(data)
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

    for (i in all.vars(master$formula)) {
        data[,i] = factor(data[,i],levels = master$var_cat[[i]])
    }
    ct=xtabs(master$formula, data = data)
    return(ct)
}