#' Federated Chisq Test.
#'
#' This version has built in `threshold` parameter that checks if any counts
#' are less than tolerance. Default is 5. Can go lower (to 1). Up to data-owner.
#' @param client `vtg::Client` instance provided by node (datastation).
#' @param col Can by single column name or N column name. If `2` column names,
#' executes Chisq on Contingency table. Warning: Sends frequency distribution.
#' @param threshold Disclosure check. Default is 5, if number of counts in
#' any cell is less than `threshold` the function stops and returns an error
#' message.
#' @param probs These are the probabilities needed. Default is `NULL` however
#' the data-owner/researcher can supply their own. The length of which has to
#' correspond to the "total" length of all combined dataset for given
#' column(s).
#'
#' @author Hasan Alradhi
#' @author Matteo Cellamare
#' @author Frank Martin
#'
#' @export
#'
dchisq <- function(client, col, threshold = 5L, probs = NULL, X_y_case = FALSE,
                       organizations_to_include = NULL){

     # Create a logger
    log <- lgr::get_logger_glue("dchisq2")
    log$set_threshold("debug")

    log$info("Initializing dchisq...")
    log$debug("col: {col}")
    log$debug("threshold: {threshold}")
    log$debug("probs: {probs}")
    log$debug("organizations_to_include: {organizations_to_include}")

    image.name <- "harbor2.vantage6.ai/starter/chisq:latest"
    log$info("using image '{image.name}'")

    client$set.task.image(
        image.name,
        task.name="chisq"
    )

    # Update the client organizations according to those specified
    if (!is.null(organizations_to_include)) {

        log$info("Sending tasks only to specified organizations")
        organisations_in_collaboration = client$collaboration$organizations
        # Clear the current list of organisations in the collaboration
        # Will remove them for current task, not from actual collaboration
        client$collaboration$organizations <- list()
        # Reshape list when the organizations_to_include is not already a list
        # Relevant when e.g., Python is used as client
        if (!is.list(organizations_to_include)){
            organisations_to_use <- toString(organizations_to_include)

            # Remove leading and trailing spaces as in python list
            organisations_to_use <-
                gsub(" ", "", organisations_to_use, fixed=TRUE)

            # Convert to list assuming it is comma separated
            organisations_to_use <-
                as.list(strsplit(organisations_to_use, ",")[[1]])
        }
        # Loop through the organisation ids in the collaboration
        for (organisation in organisations_in_collaboration) {
            # Include the organisations only when desired
            if (organisation$id %in% organisations_to_use) {
                client$collaboration$organizations[[length(
                    client$collaboration$organizations)+1]] <- organisation
            }
        }
    }

    if (client$use.master.container) {
        log$debug("Running `dchisq.test` in master container using")
        result <- client$call(
            "dchisq",
            col = col,
            threshold = threshold,
            probs = probs,
            X_y_case = X_y_case
        )
        return(result)
    }

    log$info("Making subtask to `get_N` and `get_sums` for each node...3")
    # TODO: combine the two calls into a single one
    lengths.and.sums <- client$call(
        "get_n_and_sums",
        col = col,
        threshold = threshold,
        X_y_case = X_y_case
    )

    # Extract from each element in the list `n`


    node.lens <- lapply(lengths.and.sums, function(x) x$n)
    node.sums <- lapply(lengths.and.sums, function(x) x$sums)

    log$info("Combining results from nodes...")
    total.lengths <- vtg.chisq::sumlocals(node.lens)


    # node.lens won't run unless all the class is the same...
    data.class <- attributes(node.lens[[1]])$class
    p <- vtg.chisq::assign_probabilities(
        (N <- ifelse(data.class == "DF", total.lengths$y,total.lengths$x)), probs)


    exp.and.var <- vtg.chisq::expectation(node.sums, p, data.class)

    E.glob <- exp.and.var$E

    V.glob <- exp.and.var$V

    vtg::log$info("RPC statistic")
    node.statistic <- client$call(
        "statistic",
        col = col,
        E = E.glob,
        data.class = data.class
    )

    glob.statistic <- Reduce(`+`, node.statistic)

    df.fn <- function(x, y) as.integer((x - 1L) * (y - 1L))

    glob.nc <- if(data.class == "DF"){
        Reduce("all", lapply(node.sums, function(x) x$nc))
    }else if(data.class == "X_y_case"){
        exp.and.var$glob.nc
    }

    glob.nr <- if(data.class == "X_y_case"){
        exp.and.var$glob.nr
    }else{
        Reduce(`+`, lapply(node.sums, function(x) x$nr))
    }


    parameter <- if(data.class == "DF"){
        df.fn(glob.nr, node.sums[[1]]$nc)
    }else if (data.class == "X_y_case"){
        df.fn(glob.nr, glob.nc)
    }else{
        N - 1
    }

    pval <- stats::pchisq(glob.statistic, parameter, lower.tail = F)

    names(glob.statistic) <- "X-squared"
    names(parameter) <- "df"

    method <- ifelse(data.class %in% c("DF", "X_y_case"),
                     "Pearson's Chi-squared test",
                     "Chi-squared test for given probabilities")

    structure(
        list(
            statistic = glob.statistic, parameter = parameter,
            pval = pval,
            method = method,
            residual.variance = V.glob
        )
    )
}
