#' @export
#' @TODO docs
compute_global_dimensions <- function(nodes) {

  # Confirm that all the nodes have executed the same type of Chi-Square
  # test. This can either be `2 by 2`, a `DF`` or a `col`.
  if (length(unique(lapply(nodes, function(x) attributes(x)$class))) != 1) {
    vtg::log$critical("All nodes must have executed the same type of
                        Chi-Square test.")
    stop("Mixed types of Chi-Square tests.")
  }

  chi_class <- attributes(nodes[[1]])$class
  vtg::log$debug("Chi-Square class: ", chi_class)

  # In all class-cases we can sum up the first element of each node, which
  # basically is the number of rows in the global dataset.
  x <- Reduce(`+`, lapply(nodes, function(x) x[1]))

  # Depending on the class of the Chi-Square test, we need to sum up the
  # second element of each node in a different way. In case of col, there
  # is no second element.
  if (chi_class == "DF") {

    # Validate that all sites report the same length for y. If this is
    # not the case, this could be an attempt to disclose information.
    # therefore we stop the execution.
    if (length(unique(sapply(nodes, function(x) x[2]))) != 1) {
      vtg::log$critical("Nodes reported different lengths for y.")
      stop("Nodes reported different lengths for y.")
    }
    return(list("x" = x, "y" = nodes[[1]][2]))

  } else if (chi_class == "2-by-2") {

    y <- Reduce("+", lapply(nodes, function(x) x[2]))
    return(list("x" = x, "y" = y))

  } else if (chi_class == "col") {

    return(list("x" = x))

  } else {
    vtg::log$critical("Unknown class of Chi-Square test.")
    stop("Unknown class of Chi-Square test.")
  }
}
