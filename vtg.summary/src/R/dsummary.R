#' Federated Summary algorithm.
#'
#' The summary algorithm aims to provide statistics about the data per column,
#' such as the number of missing values, length, sum and range.
#'
#' @param client vtg::Client instance provided by node.
#' @param columns List of column names to compute the summary for.
#' @param threshold Minimum count in any result before error message is returned
#' because the result may be disclosive. Default is 5.
#' @param types types to subset data with.
#' @param organizations_to_include organizations to include in the computation.
#'
#' @return a list of combined summary statistics aggregated about all
#' datastation(s) in the study. It will return  a list containing the
#' following:
#' `nan_count` representing each unique column's number of missing values,
#' `length` representing total length of each column across each site,
#' `range` a list of ranges per column,
#' `mean` a vector of means per column,
#' `variance` a vector of variance per column,
#' `node.specific.useable.rows` the node specific useable rows if the entire
#' data were used without missing values,
#' `global.useable.rows` is an aggregation of the node.specific.useable.rows.
#'
#' @author Hasan Alradhi
#' @author Matteo Cellamare
#' @author Frank Martin
#' @author Bart van Beusekom
#'
dsummary <- function(client, columns, threshold = 5L, types = NULL,
                     organizations_to_include = NULL) {
  # Create logger
  vtg::log$set_threshold("debug")

  vtg::log$info("Initializing summary...")
  vtg::log$debug("columns: {columns}")
  vtg::log$debug("threshold: {threshold}")
  vtg::log$debug("types: {types}")
  vtg::log$debug("organizations_to_include: {organizations_to_include}")

  #
  # Central part guard
  # If user indicates that master function is called, the `use.master.container`
  # is set to TRUE and this part is run.
  #
  if (client$use.master.container) {
    vtg::log$info("Running `dsummary` central container")
    result <- client$call(
      "dsummary",
      columns = columns,
      threshold = threshold,
      types = types,
      organizations_to_include = organizations_to_include
    )
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
  vtg::log$info("Computing Summary. Warning: If your data is factor calculations
            such as sum, mean, squared-deviance and variance are not
            applicable.")

  vtg::log$info("Computing initial statistics...")
  summary_per_node <- client$call(
    "summary",
    columns = columns,
    threshold = threshold,
    types = types
  )

  # catch errors for nodes
  for (node_statistics in summary_per_node) {
    if ("error" %in% names(node_statistics)) {
      vtg::log$error("Error in initial statistics. Check logs of subtasks.")
      return(node_statistics)
    }
  }

  # Compute global statistics from summary per node
  vtg::log$info("Aggregating node specific statistics...")
  summary = combine_node_statistics(summary_per_node, columns)

  # now that we have the global mean, we can compute the variance
  vtg::log$info("Calculating variance per node...")
  variance_per_node <- client$call(
    "variance",
    columns = columns,
    mean = summary[["mean"]],
    types = types
  )

  vtg::log$info("Aggregating squared deviance...")
  global_variance <- vtg.summary::comb_sums(variance_per_node, columns)

  vtg::log$info("Calculating global variance...")
  summary[["variance"]] <- vtg.summary::glob_var(
    global_variance, summary[["length"]], columns
  )

  vtg::log$info("Calculating global standard deviation")
  summary[["sd"]] <- sapply(summary[["variance"]], sqrt)

  return(summary)
}

combine_node_statistics <- function(summary_per_node, columns) {
  ###########   count NAs   ###############
  vtg::log$info("Aggregating length of missing data...")
  nan_count_per_node <- lapply(summary_per_node, function(results){
    results[["nan_count"]]
  })
  global_nan_count <- Reduce(`+`, nan_count_per_node)

  ###########   column length   ###############
  vtg::log$info("Aggregating node specific data lengths...")
  col_length_per_node <- lapply(summary_per_node, function(results){
    results[["column_lengths"]]
  })
  global_column_length = Reduce("+", col_length_per_node)

  ###########   sum   ###############
  vtg::log$info("Aggregating node specific sums...")
  sums_per_node <- lapply(summary_per_node, function(results){
    results[["column_sums"]]
  })
  global_sums <- vtg.summary::comb_sums(sums_per_node, columns)
  global_sums = Reduce("+", sums_per_node)

  ###########   range   ###############
  vtg::log$info("Aggregating node specific ranges...")
  ranges_per_node <- lapply(summary_per_node, function(results){
    results[["column_ranges"]]
  })
  global_ranges <- list()
  for (column in columns) {
    # combine ranges per column
    combined_ranges <- lapply(ranges_per_node, function(node_range){
      node_range[[column]]
    })
    if (all(sapply(combined_ranges, class) == "table")) {
      # column is a factor, so sum the occurrences of each value
      global_ranges[[column]] <- Reduce("+", combined_ranges)
    } else {
      # column is numeric, so the range is the range of the ranges
      global_ranges[[column]] <- Reduce("range", combined_ranges)
    }
  }

  ###########   complete rows   ###############
  vtg::log$info("Aggregating complete rows...")
  complete_rows_per_node <- lapply(summary_per_node, function(results){
      results[["complete_rows"]]
  })
  global_complete_rows <- Reduce("sum", complete_rows_per_node)
  # also return the complete rows per node
  # TODO incorporate the correct node IDs?!
  complete_rows_per_node <-
    data.frame("node" = seq_along(complete_rows_per_node),
                "complete_rows" = Reduce("c", complete_rows_per_node),
                row.names = NULL)

  ###########   mean   ###############
  vtg::log$info("Computing global means...")
  global_means = global_sums / global_column_length

  # return all
  return(
    list(
      "nan_count" = global_nan_count,
      "length" = global_column_length,
      "range" = global_ranges,
      "mean" = global_means,
      "complete_rows" = global_complete_rows,
      "complete_rows_per_node" = complete_rows_per_node
    )
  )
}