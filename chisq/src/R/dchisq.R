#' Federated Chisq Test.
#'
#' This version has built in `threshold` parameter that checks if any counts
#' are less than tolerance. Default is 5. Can go lower (to 1). Up to data-owner.
#' @param client `vtg::Client` instance provided by node (data station).
#' @param columns Can by single column name or N column name. If `2` column
#' names, executes Chisq on Contingency table. Warning: Sends frequency
#' distribution.
#' @param probabilities These are the probabilities needed. Default is `NULL`
#' however the data-owner/researcher can supply their own. The length of which
#' has to correspond to the "total" length of all combined dataset for given
#' column(s). (!) Only used for the `columns` analysis.
#' @param organizations_to_include List of organizations to include in the
#' analysis. This is a list of organization ids.
#'
#' @author Hasan Alradhi
#' @author Matteo Cellamare
#' @author Frank Martin
#'
#' @TODO add Anja's preprocessing
#' @TODO setup build pipeline
#' @TODO add test cases
#'
dchisq <- function(client, columns, probabilities = NULL,
                   organizations_to_include = NULL) {

  # Create a logger
  vtg::log$set_threshold("debug")

  vtg::log$info("Initializing dchisq...")
  vtg::log$debug("columns: {columns}")
  vtg::log$debug("probabilities: {probabilities}")
  vtg::log$debug("organizations_to_include: {organizations_to_include}")

  image.name <- "harbor2.vantage6.ai/starter/chisq:latest"
  vtg::log$info("using image '{image.name}'")

  client$set.task.image(image.name, task.name = "chisq")

  #
  # Central part guard
  # this will call itself without the `use.master.container` option
  #
  if (client$use.master.container) {
    vtg::log$info("Running `dchisq.test` central container.")
    result <- client$call("dchisq", columns = columns,
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
  vtg::log$info("Making subtask to `dimensions_and_totals` for each node.")
  dimensions_and_totals <- client$call("dimensions_and_totals",
                                       columns = columns)
  vtg::log$info("Results from `dimensions_and_totals` received.")

  # Validate that all nodes reported their dimensions and totals
  error <- FALSE
  for (i in seq_along(dimensions_and_totals) ) {
    if (!is.null(dimensions_and_totals[[i]]$error)) {
      log$warn("Node {i} reported an error: {dimensions_and_totals[[i]]$error}")
      error <- TRUE
    }
  }
  if (error) {
    return(list(error = "One or more nodes reported an error."))
  }

  # Construct the global dimensions from the virtual data set
  global_dimensions <- vtg.chisq::global_dimensions(dimensions_and_totals)

  # In the case of a single vector we need to do some other things than in
  # the case of a data.frame
  data_class <- attributes(dimensions_and_totals[[1]])$class
  is_col <- ifelse(data_class == "chi.vector", TRUE, FALSE)

  # In case `probabilities` is provided and we are dealing with a
  # `chi.data.frame` class, we need warn the user that it is not used.
  if (!is.null(probabilities) && !is_col) {
    log$warn("The `probabilities` argument is ignored when using DF mode.")
  }

  globals <- vtg.chisq::expectation(dimensions_and_totals, global_dimensions,
                                    probabilities, is_col)

  if(!length(organizations_to_include) == length(dimensions_and_totals)){
    stop("organizations_to_include and dimensions_and_totals must be of
         same length.. This should not be possible")
  }

  # The computation of the X-squared statistic at each nodes only requires
  # the expected values for the data at that node. Therefore we send only
  # the relevant part of the global E to each node.
  # FIXME: This is very slow as each result is awaited before the next task is
  # started. This needs to be fixed in the vtg client.
  vtg::log$info("Making subtask to `compute_chi_squared` for each node.")
  idx <- 1
  node_chi_sq_statistic <- list()
  for (i in seq_along(organizations_to_include)) {

    organization_id <- organizations_to_include[[i]]
    client$setOrganizations(c(organization_id))
    dims <- dimensions_and_totals[[i]]

    if (is_col) {
      e_subset <- globals$expected[idx:(idx + dims$number_of_rows - 1)]
    } else {
      e_subset <- globals$expected[idx:(idx + dims$number_of_rows - 1), ]
    }
    idx <- idx + dims$number_of_rows

    node_chi_sq_statistic <- append(
      node_chi_sq_statistic,
      client$call("compute_chi_squared", columns = columns,
                  expected_values = e_subset)
    )
  }
  vtg::log$info("Results from `compute_chi_squared` received.")

  # The local chi-squared statistic is computed, now we can compute the global
  # chi-squared statistic by summing the local chi-squared statistics.
  globals$chi_squared <- Reduce("+", node_chi_sq_statistic)

  # The expectancy matrix has the same dimensions as the global dataset, so
  # we can use it to compute the degrees of freedom.
  if (is_col) {
    degrees_of_freedom <- global_dimensions$number_of_rows - 1
  } else {
    degrees_of_freedom <- ((global_dimensions$number_of_rows - 1) *
                             (global_dimensions$number_of_columns - 1))
  }
  vtg::log$debug("Degrees of freedom computed")

  # Use the global chi-squared value to compute to calculate the p-value
  pval <- stats::pchisq(globals$chi_squared, degrees_of_freedom,
                        lower.tail = FALSE)
  vtg::log$debug("p-value computed")

  # Some beatification of the output, so that it is similar to the output of
  # `chisq.test`.
  names(globals$chi_squared) <- "X-squared"
  names(degrees_of_freedom) <- "df"
  names(pval) <- "p-value"

  if (is_col) {
    method <- "Chi-squared test for given probabilities"
  } else {
    method <- "Pearson's Chi-squared test"
  }

  output <- list(statistic = globals$chi_squared,
                 parameter = degrees_of_freedom, pval = pval,
                 method = method, residual.variance = globals$variance,
                 expected = globals$expected)

  vtg::log$info("dchisq completed.")
  return(output)
}
