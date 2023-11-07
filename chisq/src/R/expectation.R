#' Totalling and computing the expectation
#' @export
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

  return(list("E" = expected_values, "V" = variance))

}
