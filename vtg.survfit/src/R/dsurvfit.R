#' Federated survfit (Kaplan Meier)
#'
#' @param client vtg::Client instance, provided by the node
#' @param formula an object of class formula (or one that can be coerced
#'   to that class: a symbolic description of the model to be fitted.
#'   E.g.: dependant_variable ~ explanatory_variable(i) + ...
#' @param conf.int confidence interval coverage (95% default)
#' @param conf.type type of confidence interval (log, identity, log-log)
#' @param timepoints time points to calculate KM (bins instead of individual
#' time point)
#' @param plotCI True if the researcher wants to plot Confidence Interval for
#' the KM curves
#' @param organizations_to_include either NULL meaning all participating
#' organizations or select organizations ids; must be list of id(s)
#'
#' @return  for each strata returns a table with (n events median 0.95LCL
#' 0.95UCL) KM plot and ...
#'
#' @author Cellamare, M.
#' @author Alradhi, H.
#' @author Martin, F.
#'
#' @export
#'
dsurvfit <- function(client, formula, conf.int = 0.95, conf.type = "log", tmax = NA,
                     timepoints = NULL, plotCI = FALSE, organizations_to_include = NULL,
                     subset_rules = NULL, extend_data = TRUE) {

  vtg::log$set_threshold("debug")

  vtg::log$debug("Initializing dsurvfit ...")
  vtg::log$debug("  - formula: {formula}")
  vtg::log$debug("  - conf.int: {conf.int}")
  vtg::log$debug("  - conf.type: {conf.type}")
  vtg::log$debug("  - tmax: {tmax}")
  vtg::log$debug("  - timepoints: {timepoints}")
  vtg::log$debug("  - plotCI: {plotCI}")
  vtg::log$debug("  - organizations_to_include: {organizations_to_include}")
  vtg::log$debug("  - subset_rules: {subset_rules}")

  #
  # Central part guard
  # this will call itself without the `use.master.container` option
  #
  if (client$use.master.container) {
    vtg::log$info("Running `dsurvfit` in central container")
    result <- client$call("dsurvfit", formula = formula, conf.int = conf.int,
                          conf.type = conf.type, timepoints = timepoints,
                          plotCI = plotCI,
                          organizations_to_include = organizations_to_include,
                          subset_rules = subset_rules, extend_data = extend_data)
    return(result)
  }

  # Parse a string to formula type. If it already is a formula this statement
  # will do nothing. This is needed when Python (or other languages) is used
  # as a client.
  formula <- as.formula(formula)

  # We set the organizations to include for the partial tasks, we do this after
  # the central part guard, so that it is clear this is about the partial tasks
  # as the central part should only be executed in one node (this is because
  # of the `use.master.container` option)
  client$setOrganizations(organizations_to_include)

  # The variables that we want to use in the analysis, these correspond to the
  # column names in the data.frame
  vars <- all.vars(formula)


  KM <- function(vars, stratum = NULL) {
    master <-
      if (length(vars) > 3) {
        list(
          time = vars[1], time2 = vars[2], event = vars[3], strata = vars[4],
          conf.int = conf.int, conf.type = conf.type,
          timepoints = timepoints, tmax = tmax
        )
      } else {
        list(
          time = vars[1], time2 = NA, event = vars[2], strata = vars[3],
          conf.int = conf.int, conf.type = conf.type,
          timepoints = timepoints, tmax = tmax
        )
      }

    vtg::log$info("RPC Time")
    node_time <- client$call(
      "time",
      subset_rules = subset_rules,
      master = master,
      vars = vars,
      stratum = stratum,
      extend_data = extend_data
    )

    if (is.null(timepoints)) {
      master <- vtg.survfit::serv_time(nodes = node_time, master = master)
    } else {
      master <- vtg.survfit::serv_time(master = master)
    }

    vtg::log$info("RPC at risk")
    node_at_risk <- client$call(
      "at_risk",
      subset_rules = subset_rules,
      master = master,
      vars = vars,
      stratum = stratum,
      extend_data = extend_data
    )
    master <- serv_at_risk(nodes = node_at_risk, master = master)

    vtg::log$info("RPC KM surv")
    node_KMsurv <- client$call(
      "KMsurv",
      subset_rules = subset_rules,
      master = master,
      vars = vars,
      stratum = stratum,
      extend_data = extend_data
    )
    master <- vtg.survfit::serv_KM(nodes = node_KMsurv, master = master)
    return(master)
  }


  if (is.na(vars[3])) {

    master <- list(KM(vars))

  } else {
    vtg::log$info("RPC strata")
    node_strata <- client$call(
      "strata",
      subset_rules = subset_rules,
      strata = vars[3],
      vars = vars,
      extend_data = extend_data
    )
    stratum <- unique(unlist(node_strata))
    print(stratum)
    master <- lapply(stratum, function(k) KM(vars, k))
    names(master) <- paste0(vars[3], "=", stratum)
  }

  ######################################
  master <- master[sort(names(master))]
  Tab <- sapply(1:length(master), function(i) {
    med <- which(master[[i]]$surv <= .5)[1]
    medL <- which(master[[i]]$lower <= .5)[1]
    medU <- which(master[[i]]$upper <= .5)[1]
    tab <- c(
      master[[i]]$n.at.risk[1], master[[i]]$n.events,
      master[[i]]$times[med], master[[i]]$times[medL],
      master[[i]]$times[medU]
    )
    return(tab)
  })

  Tab <- as.table(t(Tab))
  row.names(Tab) <- names(master)
  colnames(Tab) <- c("n", "events", "median", "0.95LCL", "0.95UCL")
  Tab <- as.matrix(Tab)
  Tab[is.na(Tab)] <- "NA"
  Tab <- as.table(Tab)
  master$Tab <- Tab
  print(master$Tab)
  # plot <- jpeg(filename = "plotKM_plot%03d.jpg", width = 960, height = 960,
  #              quality = 100)
  print("all good, plotting")
  jpeg(plot <- tempfile(fileext = ".jpg"),
    width = 960, height = 960,
    quality = 100
  )
  vtg.survfit::plotKM(master, plotCI = plotCI)
  dev.off()
  vtg::log$debug("  - [DONE]")
  # read jpeg file
  # base64 encode
  # return result to server return master$base64
  txt <- RCurl::base64Encode(readBin(
    plot, "raw",
    file.info(plot)[1, "size"]
  ), "txt")
  print("we made it!")
  master$imgtxt <- txt
  return(list(
    Tab = master$Tab,
    imgtxt = master$imgtxt
  ))
}
