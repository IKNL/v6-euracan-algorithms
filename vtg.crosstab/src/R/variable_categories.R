#' Aggregator side function.
#'
#' Collect all the local instances of unique variables and sort them to a
#' global list of unique categories.
#'
#' @param nodes This contains the categories from each node. It is a list.
#' @param master List containing output from `init_formula`. Formula.
#'
#' @return Returns the master object with appended item, var_cat which is
#' the global unique categories.
#'
#' @export
#'
variable_categories <- function(nodes, master){

  used_variables <- all.vars(master$formula)

  for (i in used_variables) {
    for (j in nodes) {
      master$var_cat[[i]] <- unique(c(master$var_cat[[i]], j[[i]]))
    }
  }
  return(master)

}