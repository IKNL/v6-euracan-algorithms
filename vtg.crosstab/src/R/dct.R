#' Federated Cross Tabulation
#'
#' @param client vtg::Client instance, provided by the node
#' @param f an object of class formula
#'
#' @return Federated Cross Table object.
#'
#' @author Alradhi, H.
#' @author Cellamare, M.
#'
#' @export

dct <- function(client, f, margin = NULL, percentage = F,
                organizations_to_include = NULL, subset_rules = NULL) {
  lgr::threshold("debug")

  vtg::log$info("Initializing crosstab...")
  vtg::log$debug("f: {f}")
  vtg::log$debug("margin: {margin}")
  vtg::log$debug("percentage: {percentage}")

  #
  # Central part guard
  # this will call itself without the `use.master.container` option
  #
  if (client$use.master.container) {
    result <- client$call(
      "dct",
      f = f,
      margin = margin,
      percentage = percentage,
      organizations_to_include = organizations_to_include,
      subset_rules = subset_rules
    )
    return(result)
  }

  # We set the organizations to include for the partial tasks, we do this after
  # the central part guard, so that it is clear this is about the partial tasks
  # as the central part should only be executed in one node (this is because
  # of the `use.master.container` option)
  client$setOrganizations(organizations_to_include)

  ct <- vtg.crosstab::init_formula(f)

  vtg::log$info("")
  vtg::log$info("###############################################")
  vtg::log$info("# Collecting local variables...")
  vtg::log$info("###############################################")
  vtg::log$info("")
  #######################################################################
  # RPC GET VARS - GET UNIQUE VARIABLES AT EACH NODE
  #######################################################################
  nodes <- client$call("get_vars", subset_rules = subset_rules, master = ct)

  vtg::log$info("")
  vtg::log$info("###############################################")
  vtg::log$info("# Collecting variable categories...")
  vtg::log$info("###############################################")
  vtg::log$info("")
  #######################################################################
  # VARIABLE CATEGORIES - COLLECT UNIQUE VARIABLE CATEGORIES FROM NODES
  #######################################################################
  ct <- vtg.crosstab::variable_categories(nodes = nodes, master = ct)
  vtg::log$debug("ct: {ct}")

  vtg::log$info("")
  vtg::log$info("###############################################")
  vtg::log$info("# Building local contingency table... ")
  vtg::log$info("###############################################")
  vtg::log$info("")
  #######################################################################
  # RPC CT - BUILD LOCAL CONTINGENCY TABLE
  #######################################################################
  nodes <- client$call("CT", subset_rules = subset_rules, master = ct)

  vtg::log$info("")
  vtg::log$info("###############################################")
  vtg::log$info("# Calculating global contingency table... ")
  vtg::log$info("###############################################")
  vtg::log$info("")
  #######################################################################
  # ADD CTS - CREATE GLOBAL CONTINGENCY TABLE
  #######################################################################
  ct <- vtg.crosstab::add_cts(nodes = nodes, master = ct)

  if (!is.null(margin) && (is.integer(margin)) && (1 <= margin) &&
        (3 >= margin)) {
    ct <- vtg.crosstab::proportion(ct, margin)
  }

  if (!isFALSE(percentage)) {
    # TODO : This should loop ideally over the nodes but only
    # return the right node result to the client, not
    # all results should be sent!!!
    node.contribution <- percentage(node[[1]], output)
  }

  df.ct <- as.data.frame(ct)

  return(df.ct)
}