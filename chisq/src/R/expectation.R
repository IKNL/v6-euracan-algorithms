#' Totalling and computing the expectation
#' @export
#'
expectation <- function(local_totals, total_lengths, probabilities, is_col) {

  if (is_col) {

    # Global sum of all elements
    global_sum <- Reduce(`+`, lapply(local_totals, function(x) x$n))

    # If not provided, compute the probabilities.
    if (is.null(probabilities)) {
      probabilities <- rep(1, total_lengths$x) / total_lengths$x
    }

    # Compute the expected values and the variance
    expected_values <- global_sum * probabilities
    variance <- global_sum * probabilities * (1 - probabilities)

  } else {

    # Global sum of all elements
    global_sum <- Reduce(`+`, lapply(local_totals, function(x) x$n))

    # Global row totals
    row_totals <- Reduce(`c`, lapply(local_totals, function(x) x$sr))

    # Global column totals
    column_totals <- Reduce(`+`, lapply(local_totals, function(x) x$sc))

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
