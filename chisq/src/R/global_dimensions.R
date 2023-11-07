#' @export
#' @TODO docs
global_dimensions <- function(partials) {

  partials_dimensions <- lapply(
    partials,
    function(x) c(x$number_of_rows, x$number_of_columns)
  )
  # print("partials_dimensions: ", partials_dimensions[[1][[1]]])
  # Confirm that all the nodes have executed the same type of Chi-Square
  # test. This can either be `2 by 2`, a `DF`` or a `col`.

  classes <- lapply(partials, function(x) attributes(x)$class)

  if (length(unique(classes)) != 1) {
    vtg::log$critical("All nodes must have executed the same type of
                        Chi-Square test.")
    stop("Mixed types of Chi-Square tests.")
  }

  chi_class <- classes[[1]]
  vtg::log$debug("Chi-Square class: ", chi_class)

  # In all class-cases we can sum up the first element of each node, which
  # basically is the number of rows in the global dataset.
  x <- Reduce(`+`, lapply(partials_dimensions, function(x) x[1]))

  # Depending on the class of the Chi-Square test, we need to sum up the
  # second element of each node in a different way. In case of col, there
  # is no second element.
  if (chi_class == "chi.data.frame") {

    # Validate that all sites report the same length for y. If this is
    # not the case, this could be an attempt to disclose information.
    # therefore we stop the execution.
    if (length(unique(sapply(partials_dimensions, function(x) x[2]))) != 1) {
      vtg::log$critical("Nodes reported different lengths for y.")
      stop("Nodes reported different lengths for y.")
    }

    dimensions <- list("number_of_rows" = x,
                       "number_of_columns" = partials_dimensions[[1]][2])
    return(dimensions)

  } else if (chi_class == "chi.vector") {

    return(list("number_of_rows" = x))

  } else {
    vtg::log$critical("Unknown class of Chi-Square test.")
    stop("Unknown class of Chi-Square test.")
  }
}
