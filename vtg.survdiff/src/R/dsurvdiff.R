#' Federated survdiff
#'
#' @param client vtg::Client instance, provided by the node
#' @param formula an object of class formula (or one that can be coerced
#'   to that class: a symbolic description of the model to be fitted.
#'   E.g.: dependant_variable ~ explanatory_variable(i) + ...
#' @param timepoints time points to calculate KM (bins instead of individual time point)
#'
#' @return  for each strata returns a table with (n events median 0.95LCL 0.95UCL) KM plot and ...
#'
#' @author Cellamare, M.
#' @author Alradhi, H.
#' @author Martin, F.
#' @export
#'
#'
dsurvdiff <- function(client, formula, timepoints = NULL, tmax = NA,
                      organizations_to_include = NULL, subset_rules = NULL) {
  vtg::log$debug("Initializing...")
  lgr::threshold("debug")

  #
  # Central part guard
  # this will call itself without the `use.master.container` option
  #
  if (client$use.master.container) {
    vtg::log$debug(glue::glue("Running `dsurvdiff` in central container"))
    result <- client$call(
      "dsurvdiff",
      formula = f,
      timepoints = timepoints,
      organizations_to_include = organizations_to_include,
      subset_rules = subset_rules
    )

    return(result)
  }

  # Parse a string to formula type. If it already is a formula this statement
  # will do nothing. This is needed when Python (or other langauges) is used
  # as a client.
  f <- as.formula(formula)

  # We set the organizations to include for the partial tasks, we do this after
  # the central part guard, so that it is clear this is about the partial tasks
  # as the central part should only be executed in one node (this is because
  # of the `use.master.container` option)
  client$setOrganizations(organizations_to_include)

  # initialization variables
  vars <- all.vars(f)
  LRT <- function(vars, stratum = NULL) {
    if (length(vars) > 3) {
      master <- list(
        time = vars[1], time2 = vars[2],
        event = vars[3], strata = vars[4],
        timepoints = timepoints, tmax = tmax
      )
    } else {
      master <- list(
        time = vars[1], time2 = NA,
        event = vars[2], strata = vars[3],
        timepoints = timepoints, tmax = tmax
      )
    }
    if (is.null(timepoints)) {
      vtg::log$info("RPC Time")
      node_time <- client$call(
        "time",
        subset_rules = subset_rules,
        master = master,
        vars = vars
      )
      master <- vtg.survdiff::serv_time(nodes = node_time, master = master)
    } else {
      master <- vtg.survdiff::serv_time(master = master)
    }

    vtg::log$info("RPC Tab")
    node_tab <- client$call(
      "tab",
      subset_rules = subset_rules,
      master = master,
      stratum = stratum,
      vars = vars
    )
    master <- serv_tab(nodes = node_tab, master = master)
    return(master)
  }

  if (is.na(vars[3])) {
    vtg::log$debug("missing stratification variable - [DONE]")
    break
  } else {
    vtg::log$info("RPC strata")
    node_strata <- client$call(
      "strata",
      subset_rules = subset_rules,
      strata = ifelse(length(vars) > 3, vars[4], vars[3]),
      vars = vars
    )
    stratum <- unique(unlist(node_strata))
    master <- lapply(stratum, function(k) LRT(vars, k))
    vtg::log$debug("Itterations are done")
    names(master) <- paste0(ifelse(length(vars) > 3, vars[4], vars[3]), "=", stratum)
  }

  ######################################
  vtg::log$debug("a")
  N <- rowSums(sapply(1:length(master), function(g) master[[g]]$n))
  M <- rowSums(sapply(1:length(master), function(g) master[[g]]$m))
  for (s in 1:length(master)) {
    master[[s]]$e <- (master[[s]]$n / N) * M
  }
  ### create Tab
  vtg::log$debug("b")
  obs <- sapply(master, function(s) sum(s$m))
  exp <- sapply(master, function(s) sum(s$e))
  df <- exp > 0
  temp2 <- ((obs - exp)[df])[-1]
  V <- matrix(NA, length(master), length(master))
  diag(V) <- sapply(1:length(master), function(g) {
    v <- master[[g]]$n * (M / N) * ((N - M) / N) * ((N - master[[g]]$n) / (N - 1))
    sum(v[!is.nan(v)])
  })
  EG <- expand.grid(h = 1:length(master), g = 1:length(master))
  EG <- EG[EG$h != EG$g, ]
  for (i in 1:nrow(EG)) {
    v <- (master[[EG[i, 1]]]$n * master[[EG[i, 2]]]$n * M * (N - M)) / (N^2 * (N - 1))
    V[EG[i, 1], EG[i, 2]] <- -sum(v[!is.nan(v)])
  }
  vv <- (V[df, df])[-1, -1, drop = FALSE]
  colnames(V) <- names(master) # this has to be double-checked if OK.
  chi <- sum(solve(vv, temp2) * temp2)
  df <- (sum(1 * (exp > 0))) - 1
  vtg::log$debug("c")
  rval <- list(
    formula = toString(formula),
    n = sapply(master, function(s) (s$n)[1]),
    strata = names(master),
    obs = obs,
    exp = exp,
    var = V,
    chisq = chi,
    pvalue = pchisq(chi, df, lower.tail = FALSE)
  )
  vtg::log$debug("d")
  print(rval)
  df.rval <- as.data.frame(rval)

  vtg::log$debug("e")
  vtg.survdiff::print_output_dsurvdiff(df.rval)
  vtg::log$debug("  - [DONE]")
  return(df.rval)
}
