#' Federated Chisq Test.
#'
#' This version has built in `threshold` parameter that checks if any counts
#' are less than tolerance. Default is 5. Can go lower (to 1). Up to data-owner.
#' @param client `vtg::Client` instance provided by node (data station).
#' @param col Can by single column name or N column name. If `2` column names,
#' executes Chisq on Contingency table. Warning: Sends frequency distribution.
#' @param threshold Disclosure check. Default is 5, if number of counts in
#' any cell is less than `threshold` the function stops and returns an error
#' message.
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
#' @TODO move the organization selection to the vtg package, i think it is
#'      already there. Just check that it is the same, it looks like something
#'      is changed...
#' @TODO format all code to linter standards
#' @TODO setup build pipeline
#' @TODO add test cases
#'
dchisq <- function(client, col, threshold = 5L, probabilities = NULL,
                   organizations_to_include = NULL) {

  # Create a logger
  log <- lgr::get_logger_glue("dchisq2")
  log$set_threshold("debug")

  log$info("Initializing dchisq...")
  log$debug("col: {col}")
  log$debug("threshold: {threshold}")
  log$debug("probabilities: {probabilities}")
  log$debug("organizations_to_include: {organizations_to_include}")

  image.name <- "harbor2.vantage6.ai/starter/chisq:latest"
  log$info("using image '{image.name}'")

  client$set.task.image(image.name, task.name = "chisq")

  # Update the client organizations according to those specified
  if (!is.null(organizations_to_include)) {

    log$info("Sending tasks only to specified organizations")
    organizations_in_collaboration = client$collaboration$organizations
    # Clear the current list of organizations in the collaboration
    # Will remove them for current task, not from actual collaboration
    client$collaboration$organizations <- list()

    # Reshape list when the organizations_to_include is not already a list
    # Relevant when e.g., Python is used as client
    if (!is.list(organizations_to_include)) {
      organizations_to_use <- toString(organizations_to_include)

      # Remove leading and trailing spaces as in python list
      organizations_to_use <-
        gsub(" ", "", organizations_to_use, fixed = TRUE)

      # Convert to list assuming it is comma separated
      organizations_to_use <-
        as.list(strsplit(organizations_to_use, ",")[[1]])
    }

    # Loop through the organization ids in the collaboration
    for (organization in organizations_in_collaboration) {
      # Include the organizations only when desired
      if (organization$id %in% organizations_to_use) {
        client$collaboration$organizations[[
          length(client$collaboration$organizations) + 1
        ]] <- organization
      }
    }
  }

  #
  # Master container guard
  # this will call itself without the `use.master.container` option
  #
  if (client$use.master.container) {
    log$info("Running `dchisq.test` central container.")
    result <- client$call("dchisq", col = col, threshold = threshold,
                          probabilities = probabilities)
    return(result)
  }

  #
  # Orchestration and Aggregation
  #
  log$info("Making subtask to `get_n_and_sums` for each node.")
  lengths_and_sums <- client$call("get_n_and_sums", col = col,
                                  threshold = threshold)
  log$info("Results from `get_n_and_sums` received.")

  # Depending on the number of `cols` the contents of `node_lens` will be
  # different.
  # (1) In the case of a vector this contains the number of elements in that
  #     vector per site.
  # (2) In the case of 2 columns, this contains the number of elements in
  #     each column per site.
  # (3) In the case of a data.frame, this contains the number of elements in
  #     and the number of columns per site.
  node_lens <- lapply(lengths_and_sums, function(x) x$n)
  total_lengths <- vtg.chisq::compute_global_dimensions(node_lens)

  # In the case of a single vector we need to do some other things than in
  # the case of a data.frame or x-by-y.
  data_class <- attributes(node_lens[[1]])$class
  is_col <- ifelse(data_class == "col", TRUE, FALSE)

  # In case `probabilities` is provided and we are dealing with DF or 2-by-2,
  # we need warn the user that it is not used
  if (!is.null(probabilities) && !is_col) {
    log$warn("The `probabilities` argument is ignored when using DF mode.")
  }

  # Depending on the number of `cols` the contents of `node_sums` will be
  # different.
  # (1) In the case of a vector this contains the sum of elements in that
  #     vector per site.
  # (2) In the case of 2 columns .... TODO
  # (3) In the case of a data.frame, this contains the totals of each row,
  #     column and the total number of elements per site.
  node_sums <- lapply(lengths_and_sums, function(x) x$sums)

  # Compute the global expectation and variance
  globals <- vtg.chisq::expectation(node_sums, total_lengths, probabilities,
                                    is_col)

  # Now that the global expectation is computed, we can compute the local
  # chi-squared statistic.
  vtg::log$info("Making subtask to `compute_chi_squared` for each node.")
  node_chi_sq_statistic <- client$call("compute_chi_squared", col = col,
                                       E = globals$E)
  log$info("Results from `compute_chi_squared` received.")

  # The local chi-squared statistic is computed, now we can compute the global
  # chi-squared statistic by summing the local chi-squared statistics.
  globals$chi_squared <- Reduce("+", node_chi_sq_statistic)

  # The number of observations in the global dataset
  globals$n_rows <- Reduce("+", lapply(node_sums, function(x) x$nr))

  # The expectancy matrix has the same dimensions as the global dataset, so
  # we can use it to compute the degrees of freedom.
  globals$n_cols <- ncol(globals$E)
  if (is_col) {
    degrees_of_freedom <- total_lengths$x - 1
  } else {
    degrees_of_freedom <- (globals$n_rows - 1) * (globals$n_cols - 1)
  }

  # Use the global chi-squared value to compute to calculate the p-value
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
