#' Federated CoxPH algorithm.
#'
#' @param client `vtg::Client` instance.
#' @param expl_vars: list of explanatory variables (covariates) to use
#' @param time_col: name of the column that contains the event/censor times
#' @param censor_col: name of the column that explains whether an event occurred
#' or the patient was censored
#' @param organizations_to_include: either `NULL` meaning all participating
#' organizations or select organization ids must be list of id(s).
#'
#' @return RDS with beta, p-value and confidence interval for each explanatory
#' variable.
#'
#' @author Melle Sieswerda
#' @author Matteo Cellamare
#' @author Hasan Alradhi
#' @author Frank Martin
#'
#' @export
#'
dcoxph <- function(client, expl_vars, time_col, censor_col, types = NULL,
                   organizations_to_include = NULL, subset_rules = NULL) {

  # Create a logger
  lgr::threshold("debug")

  vtg::log$info("Initializing coxph ...")
  vtg::log$debug("expl_vars: {expl_vars}")
  vtg::log$debug("time_col: {time_col}")
  vtg::log$debug("censor_col: {censor_col}")

  MAX_COMPLEXITY <- 250000
  USE_VERBOSE_OUTPUT <- getOption("vtg.verbose_output", F)

  #
  # Central part guard
  # this will call itself without the `use.master.container` option
  #
  if (client$use.master.container) {
    vtg::log$info("Running `dcoxph` in central container.")
    result <- client$call("dcoxph", expl_vars = expl_vars, time_col = time_col,
                          censor_col = censor_col, types = types,
                          organizations_to_include = organizations_to_include,
                          subset_rules = subset_rules)
    return(result)
  }

  # We set the organizations to include for the partial tasks, we do this after
  # the central part guard, so that it is clear this is about the partial tasks
  # as the central part should only be executed in one node (this is because
  # of the `use.master.container` option)
  client$setOrganizations(organizations_to_include)

  # Run in a REGULAR container
  m <- length(expl_vars)

  # Ask all nodes to return their unique event times with counts
  vtg::log$info("Getting unique event times and counts")
  results <- client$call("get_unique_event_times_and_counts",
                         subset_rules = subset_rules, time_col = time_col,
                         censor_col = censor_col, types = types)
  vtg::log$info("Results from `get_unique_event_times_and_counts` received.")

  errors <- vtg::collect_errors(results)
  if (!is.null(errors)) {
    return(errors)
  }

  Ds <- lapply(results, as.data.frame)

  D_all <- compute.combined.ties(Ds)
  unique_event_times <- as.numeric(names(D_all))

  vtg::log$debug(unique_event_times)

  complexity <- length(unique_event_times) * length(expl_vars)^2
  vtg::log$info("********************************************")
  vtg::log$info(c("Complexity:", complexity))
  vtg::log$info("********************************************")

  if (complexity > MAX_COMPLEXITY) {
    msg <- "This computation will be too heavy on the nodes! Aborting!"
    vtg::log$error(msg)
    return(vtg::error_format(error = msg))
  }

  # Ask all nodes to compute the summed Z statistic
  vtg::log$info("Getting the summed Z statistic")
  summed_zs <- client$call("compute_summed_z", subset_rules = subset_rules,
                           expl_vars = expl_vars, time_col = time_col,
                           censor_col = censor_col, types = types)
  vtg::log$info("Results from `compute_summed_z` received.")

  errors <- vtg::collect_errors(summed_zs)
  if (!is.null(errors)) {
    return(errors)
  }

  # z_hat: vector of same length m
  # Need to jump through a few hoops because apply simplifies a matrix
  # with one row to a numeric (vector) :@
  # z_hat <- list.to.matrix(summed_zs)
  # z_hat <- apply(z_hat, 2, as.numeric)
  # z_hat <- matrix(z_hat, ncol=m, dimnames=list(NULL, expl_vars))
  # z_hat <- colSums(z_hat)
  z_hat <- Reduce(`+`, summed_zs)

  # Initialize the betas to 0 and start iterating
  vtg::log$info("Starting iterations ...")
  beta <- beta_old <- rep(0, m)
  delta <- 0

  i <- 1
  while (i <= 30) {
    vtg::log$info(sprintf("Executing iteration %i", i))
    if (USE_VERBOSE_OUTPUT) {
      writeln("Beta's:")
      print(beta)
      writeln()

      writeln("delta: ")
      print(delta)
      writeln()
    }

    aggregates <- client$call("perform_iteration", subset_rules = subset_rules,
                              expl_vars = expl_vars, time_col = time_col,
                              censor_col = censor_col, beta = beta,
                              unique_event_times = unique_event_times, types = types)
    vtg::log$info("Results from `perform_iteration` {i} received.")

    errors <- vtg::collect_errors(aggregates)
    if (!is.null(errors)) return(errors)

    # Compute the primary and secondary derivatives
    derivatives <- compute.derivatives(z_hat, D_all, aggregates)
    # print(derivatives)

    # Update the betas
    beta_old <- beta
    beta <- beta_old - (solve(derivatives$secondary) %*%
      derivatives$primary)

    delta <- abs(sum(beta - beta_old))

    if (is.na(delta)) {
      writeln("Delta as turned into a NaN???")
      writeln(beta_old)
      writeln(beta)
      writeln(delta)
      break
    }

    if (delta <= 10^-8) {
      vtg::log$info("Betas have settled! Finished iterating!")
      break
    }
    i <- i + 1
  }

  # Computing the standard errors
  SErrors <- NULL
  fisher <- solve(-derivatives$secondary)

  # Standard errors are the squared root of the diagonal
  for (k in 1:dim(fisher)[1]) {
    se_k <- sqrt(fisher[k, k])
    SErrors <- c(SErrors, se_k)
  }

  # Calculating P and Z values
  # zvalues <- (exp(beta)-1)/SErrors

  # Now calculating the z-values the same way `survival::coxph()` does it.
  zvalues <- beta / SErrors
  pvalues <- 2 * pnorm(-abs(zvalues))
  pvalues <- format.pval(pvalues, digits = 1)

  # 95%CI = beta +- 1.96 * SE
  results <- data.frame(
    "coef" = round(beta, 5), "exp(coef)" = round(exp(beta), 5),
    "SE" = round(SErrors, 5)
  )
  results <- dplyr::mutate(results, lower_ci = round(exp(coef - 1.96 * SE), 5))
  results <- dplyr::mutate(results, upper_ci = round(exp(coef + 1.96 * SE), 5))
  results <- dplyr::mutate(results, "Z" = round(zvalues, 2), "P" = pvalues)
  results$var <- as.matrix(round(fisher, 5))
  # results <- dplyr::mutate(results, "Z_2"=round(zvalues2, 2),
  # "P_2"=pvalues2)
  row.names(results) <- rownames(beta)

  return(results)
}
