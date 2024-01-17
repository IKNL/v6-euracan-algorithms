#' Computing the expected values and variance
#'
#' @param partial_totals A list of partial totals from each node, each element
#' of the list should be a list with the following elements:
#' \itemize{
#'  \item \code{sum}: The sum of all elements in the dataset.
#' \item \code{sum_of_rows}: The sum of all rows in the dataset.
#' \item \code{sum_of_columns}: The sum of all columns in the dataset.
#' }
#' @param global_dimensions A list with the following elements:
#' \itemize{
#' \item \code{number_of_rows}: The number of rows in the global dataset.
#' \item \code{number_of_columns}: The number of columns in the global dataset.
#' }
#' @param probabilities A vector of probabilities, one for each row in the
#' global dataset.
#' @param is_col A boolean indicating whether the computation is for a column
#' or not.
#'
#' @return A list containing the expected values and the variance.
#'
expectation <- function(partial_totals, global_dimensions, probabilities,
                        is_col) {

  if (is_col) {

    # Global sum of all elements
    global_sum <- Reduce(`+`, lapply(partial_totals, function(x) x$sum))

    # If not provided, compute the probabilities.
    if (is.null(probabilities)) {
      n <- global_dimensions$number_of_rows
      probabilities <- rep(1, n) / n
    }

    # Compute the expected values and the variance
    expected_values <- global_sum * probabilities
    variance <- global_sum * probabilities * (1 - probabilities)

  } else {

    # Global sum of all elements
    global_sum <- Reduce(`+`, lapply(partial_totals, function(x) x$sum))

    # Global row totals
    row_totals <- Reduce(`c`, lapply(partial_totals, function(x) x$sum_of_rows))

    # Global column totals
    column_totals <- Reduce(`+`, lapply(partial_totals,
                                        function(x) x$sum_of_columns))

    # Based on the totaling, compute the expected value per element in the
    # global dataset.
    expected_values <- outer(row_totals, column_totals) / global_sum

    # Special cross product for variance using the `compute_variance` function
    # for each element.
    compute_variance <- function(r, c, n) {
      c * r * (n - r) * (n - c) / n^3
    }
    variance <- outer(row_totals, column_totals, compute_variance, global_sum)

  }

  return(list("expected" = expected_values, "variance" = variance))

}
