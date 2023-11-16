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
#' `global.nas` representing each unique column's number of missing values,
#' `global.lengths` representing total length of each column across each site,
#' `global.range` a list of ranges per column,
#' `global.means` a vector of means per column,
#' `global.variance` a vector of variance per column,
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
  initial_statistics <- client$call(
    "summary",
    columns = columns,
    threshold = threshold,
    types = types
  )
  print(initial_statistics)

  ###########################################
  # Separating pieces of initial statistics #
  ###########################################
  vtg::log$info("Aggregating length of missing data...")
  node.nas <- lapply(initial_statistics, function(results){
    results[["nan_count"]]
  })
  glob.nas <- vtg.summary::comb_na(node.nas, columns)

  vtg::log$info("Aggregating node specific data lengths...")
  node.lengths <- lapply(initial_statistics, function(results){
    results[["column_lengths"]]})
  glob.lens <- vector(length=length(unique(columns)))
  names(glob.lens) = unique(columns)
  for(colName in unique(columns)){
    # fast function
    identifies.values.of.columns <- mapply(FUN = function(vec){
        vec[which(names(vec) == colName)]}, node.lengths)
    # to remove the named numeric(0)
    identifies.values.of.columns <-
        Reduce("c", identifies.values.of.columns)
    glob.lens[[colName]] <- sum(identifies.values.of.columns)
  }

  vtg::log$info("Aggregating node specific sums...")
  node.sums <- lapply(initial_statistics, function(results){
    results[["column_sums"]]})
  glob.sums <- vtg.summary::comb_sums(node.sums, columns)


  vtg::log$info("Aggregating node specific ranges...")
  node.range <- lapply(initial_statistics, function(results){
    results[["column_ranges"]]})
  glob.range <- vtg.summary::comb_range(node.range, columns)

  vtg::log$info("Aggregating useable rows...")
  node.useable.rows <- lapply(initial_statistics, function(results){
      results[["data.useable.rows"]]
  })
  glob.useable.rows <- Reduce("sum", node.useable.rows)
  node.useable.rows.df <-
      data.frame("node" = seq_along(node.useable.rows),
                  "useable.rows" = Reduce("c", node.useable.rows),
                  row.names = NULL)
  # :@ R is still assigning rownames!!
  rownames(node.useable.rows.df) <- NULL

  vtg::log$info("Computing global means...")
  glob.mean <- vtg.summary::glob_mean(glob.sums, glob.lens, columns)

  vtg::log$info("Calculating node specific squared deviance...")
  node.sqr.dev <- client$call(
    "sqr_dev",
    col = columns,
    glob.mean = glob.mean
  )

  vtg::log$info("Aggregating squared deviance...")
  glob.sqr.dev <- vtg.summary::comb_sums(node.sqr.dev, columns)

  vtg::log$info("Calculating global variance...")
  glob.var <- vtg.summary::glob_var(glob.sqr.dev, glob.lens, columns)

  vtg::log$info("Calculating global standard deviation")
  glob.sd <- sapply(glob.var, sqrt)

  return(
    list(
      "global.nas" = glob.nas,
      "global.lengths" = glob.lens,
      "global.range" = glob.range,
      "global.means" = glob.mean,
      "global.variance" = glob.var,
      "node.specific.useable.rows" = node.useable.rows.df,
      "global.useable.rows" = glob.useable.rows
    )
  )
}
