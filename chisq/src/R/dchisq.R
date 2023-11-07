#' Federated Chisq Test.
#'
#' This version has built in `threshold` parameter that checks if any counts
#' are less than tolerance. Default is 5. Can go lower (to 1). Up to data-owner.
#' @param client `vtg::Client` instance provided by node (data station).
#' @param col Can by single column name or N column name. If `2` column names,
#' executes Chisq on Contingency table. Warning: Sends frequency distribution.
#' @param probabilities These are the probabilities needed. Default is `NULL`
#' however the data-owner/researcher can supply their own. The length of which
#' has to correspond to the "total" length of all combined dataset for given
#' column(s). (!) Only used for the `col` analysis.
#'
#' TODO Missing values are ignored. Even when a single value is missing the
#' whole row is removed. We should document this.
#'
#' @author Hasan Alradhi
#' @author Matteo Cellamare
#' @author Frank Martin
#'
#' @TODO add some additional logging
#' @TODO validate the parameter descriptions
#' @TODO RPC_compute_chi_squared needs only the part of E relevant to the node
#' @TODO incorporate Hasan's changes from the branch
#' @TODO add Anja's preprocessing
#' @TODO format all code to linter standards
#' @TODO setup build pipeline
#' @TODO add test cases
#'
dchisq <- function(client, col, probabilities = NULL,
                   organizations_to_include = NULL) {

  # Create a logger
  log <- lgr::get_logger_glue("dchisq2")
  log$set_threshold("debug")

  log$info("Initializing dchisq...")
  log$debug("col: {col}")
  log$debug("probabilities: {probabilities}")
  log$debug("organizations_to_include: {organizations_to_include}")

  image.name <- "harbor2.vantage6.ai/starter/chisq:latest"
  log$info("using image '{image.name}'")

  client$set.task.image(image.name, task.name = "chisq")

  #
  # Central part guard
  # this will call itself without the `use.master.container` option
  #
  if (client$use.master.container) {
    log$info("Running `dchisq.test` central container.")
    result <- client$call("dchisq", col = col,
                          probabilities = probabilities)
    return(result)
  }

  # We set the organizations to include for the partial tasks, we do this after
  # the central part guard, so that it is clear this is about the partial tasks
  # as the central part should only be executed in one node (this is because
  # of the `use.master.container` option)
  client$setOrganizations(organizations_to_include)

  #
  # Orchestration and Aggregation
  #
  log$info("Making subtask to `get_n_and_sums` for each node.")
  dimensions_and_totals <- client$call("dimensions_and_totals", col = col)
  log$info("Results from `dimensions_and_totals` received.")

  # Depending on the number of `cols` the contents of `partial_dimensions`
  # will be different.
  # (1) In the case of a vector this contains the number of elements in that
  #     vector per site.
  # (2) In the case of 2 columns, this contains the number of elements in
  #     each column per site.
  # (3) In the case of a data.frame, this contains the number of elements in
  #     and the number of columns per site.
#   partial_dimensions <- lapply(
#     dimensions_and_totals,
#     function(x) c(x$number_of_rows, x$number_of_columns)
#   )

  global_dimensions <- vtg.chisq::global_dimensions(dimensions_and_totals)

  # In the case of a single vector we need to do some other things than in
  # the case of a data.frame or x-by-y.
  data_class <- attributes(dimensions_and_totals[[1]])$class
  is_col <- ifelse(data_class == "chi.vector", TRUE, FALSE)

  # In case `probabilities` is provided and we are dealing with DF or 2-by-2,
  # we need warn the user that it is not used
  if (!is.null(probabilities) && !is_col) {
    log$warn("The `probabilities` argument is ignored when using DF mode.")
  }

  # Depending on the number of `cols` the contents of `partial_totals` will be
  # different.
  # (1) In the case of a vector this contains the sum of elements in that
  #     vector per site.
  # (2) In the case of 2 columns .... TODO
  # (3) In the case of a data.frame, this contains the totals of each row,
  #     column and the total number of elements per site.
  # Compute the global expectation and variance
  globals <- vtg.chisq::expectation(dimensions_and_totals, global_dimensions,
                                    probabilities, is_col)

  # Now that the global expectation is computed, we can compute the local
  # chi-squared statistic.
  # TODO: Send back only he relevant part of E, now we send all expected values
  #       to each node while it only needs the expected values for its own
  #       data.
  vtg::log$info("Making subtask to `compute_chi_squared` for each node.")
  node_chi_sq_statistic <- client$call("compute_chi_squared", col = col,
                                       expected_values = globals$E)
  log$info("Results from `compute_chi_squared` received.")

  # The local chi-squared statistic is computed, now we can compute the global
  # chi-squared statistic by summing the local chi-squared statistics.
  globals$chi_squared <- Reduce("+", node_chi_sq_statistic)

  # The number of observations in the global dataset
  globals$n_rows <- Reduce("+", lapply(dimensions_and_totals,
                                       function(x) x$number_of_rows))

  # The expectancy matrix has the same dimensions as the global dataset, so
  # we can use it to compute the degrees of freedom.
  globals$n_cols <- ncol(globals$E)
  if (is_col) {
    degrees_of_freedom <- global_dimensions$number_of_rows - 1
  } else {
    degrees_of_freedom <- (globals$n_rows - 1) * (globals$n_cols - 1)
  }

  # Use the global chi-squared value to compute to calculate the p-value
  vtg::log$info("DF", degrees_of_freedom)
  vtg::log$info(globals$chi_squared)

  pval <- stats::pchisq(globals$chi_squared, degrees_of_freedom,
                        lower.tail = FALSE)

  # Some beatification of the output, so that it is similar to the output of
  # `chisq.test`.
  names(globals$chi_squared) <- "Chi squared"
  names(degrees_of_freedom) <- "df"

  if (is_col) {
    method <- "Chi-squared test for given probabilities"
  } else {
    method <- "Pearson's Chi-squared test"
  }

  output <- list(statistic = globals$chi_squared,
                 parameter = degrees_of_freedom, pval = pval,
                 method = method, residual.variance = globals$V,
                 expected = globals$E)

  return(output)
}
